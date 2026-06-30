const express = require("express");
const http = require("http");
const { WebSocketServer } = require("ws");
const crypto = require("crypto");
const { spawn } = require("child_process");

const app = express();
app.use(express.json({ limit: "2mb" }));

const packageVersion = "0.1.0";
const port = Number(process.env.PORT || 8090);
const sqlclRuntimeBin = process.env.SQLCL_RUNTIME_BIN || "podman";
const sqlclContainerName = process.env.SQLCL_CONTAINER_NAME || "fortisai-sqlcl";
const sqlclTimeoutMs = Number(process.env.SQLCL_TIMEOUT_MS || 30000);

function requestId() {
  return crypto.randomUUID();
}

function okEnvelope(operation, payload) {
  return {
    requestId: requestId(),
    operation,
    status: "accepted",
    payload,
    timestamp: new Date().toISOString(),
  };
}

function applyNamedParams(statement, params) {
  if (!params || typeof params !== "object") return statement;

  let rendered = statement;
  for (const [name, value] of Object.entries(params)) {
    const token = new RegExp(`:${name}\\b`, "g");
    if (value === null || value === undefined) {
      rendered = rendered.replace(token, "NULL");
    } else if (typeof value === "number" || typeof value === "bigint") {
      rendered = rendered.replace(token, String(value));
    } else if (typeof value === "boolean") {
      rendered = rendered.replace(token, value ? "1" : "0");
    } else {
      const escaped = String(value).replace(/'/g, "''");
      rendered = rendered.replace(token, `'${escaped}'`);
    }
  }

  return rendered;
}

function runSqlclViaContainer(operation, sqlText) {
  return new Promise((resolve, reject) => {
    const shellCmd = [
      "set -e",
      "if [ -f /opt/oracle/wallet/oracle-db.env ]; then . /opt/oracle/wallet/oracle-db.env; fi",
      "CONNECT_STRING=\"${ORACLE_DB_CONNECT_STRING:-${ORACLE_DB_HOST:-fortisai-oracle-db}:${ORACLE_DB_PORT:-1521}/${ORACLE_DB_SERVICE_NAME:-FREEPDB1}}\"",
      "DB_USER=\"${ORACLE_DB_USER:-pdbadmin}\"",
      "DB_PASSWORD=\"${ORACLE_DB_PASSWORD:-FortisAI26ai!2026}\"",
      "{",
      "  printf \"connect %s/%s@%s\\n\" \"$DB_USER\" \"$DB_PASSWORD\" \"$CONNECT_STRING\"",
      "  cat",
      "  printf \"\\nexit\\n\"",
      "} | sql -s /nolog",
    ].join("\n");

    const proc = spawn(
      sqlclRuntimeBin,
      ["exec", "-i", sqlclContainerName, "/bin/sh", "-lc", shellCmd],
      {
        stdio: ["pipe", "pipe", "pipe"],
        env: {
          ...process.env,
          HOME: "/tmp",
          XDG_RUNTIME_DIR: "/tmp",
          XDG_CONFIG_HOME: "/tmp/.config",
        },
      }
    );

    let stdout = "";
    let stderr = "";
    let timedOut = false;

    const timer = setTimeout(() => {
      timedOut = true;
      proc.kill("SIGKILL");
    }, sqlclTimeoutMs);

    proc.stdout.on("data", (chunk) => {
      stdout += chunk.toString("utf8");
    });

    proc.stderr.on("data", (chunk) => {
      stderr += chunk.toString("utf8");
    });

    proc.on("error", (err) => {
      clearTimeout(timer);
      reject(new Error(`Failed to start ${sqlclRuntimeBin}: ${err.message}`));
    });

    proc.on("close", (code) => {
      clearTimeout(timer);

      if (timedOut) {
        reject(new Error(`SQLcl timeout after ${sqlclTimeoutMs}ms`));
        return;
      }

      const output = `${stdout}\n${stderr}`.trim();
      const hasOracleError = /ORA-\d+|SP2-\d+/i.test(output);

      if (code !== 0 || hasOracleError) {
        reject(new Error(output || `SQLcl command failed for ${operation}`));
        return;
      }

      resolve({ output: stdout.trim() });
    });

    proc.stdin.write(sqlText.trim());
    proc.stdin.end("\n");
  });
}

function ensureBody(res, body, fieldName) {
  if (!body || typeof body !== "object" || !body[fieldName]) {
    res.status(400).json({
      error: `Missing required field: ${fieldName}`,
    });
    return false;
  }
  return true;
}

app.get("/health", (_req, res) => {
  res.json({ status: "ok", service: "fortisai-oracle-node-api" });
});

app.get("/version", (_req, res) => {
  res.json({
    name: "fortisai-oracle-node-api",
    version: packageVersion,
    node: process.version,
  });
});

app.post("/exec", async (req, res) => {
  if (!ensureBody(res, req.body, "statement")) return;

  try {
    const statement = applyNamedParams(req.body.statement, req.body.params || {});
    const result = await runSqlclViaContainer("exec", statement);
    res.json(okEnvelope("exec", {
      statement,
      params: req.body.params || {},
      output: result.output,
    }));
  } catch (err) {
    res.status(502).json({
      operation: "exec",
      error: err.message,
    });
  }
});

app.post("/script", async (req, res) => {
  if (!ensureBody(res, req.body, "script")) return;

  try {
    const script = req.body.script;
    const statements = script
      .split(";")
      .map((line) => line.trim())
      .filter(Boolean);

    const result = await runSqlclViaContainer("script", script);
    res.json(okEnvelope("script", {
      statementCount: statements.length,
      statements,
      output: result.output,
    }));
  } catch (err) {
    res.status(502).json({
      operation: "script",
      error: err.message,
    });
  }
});

app.post("/ddl", async (req, res) => {
  if (!ensureBody(res, req.body, "ddl")) return;

  try {
    const result = await runSqlclViaContainer("ddl", req.body.ddl);
    res.json(okEnvelope("ddl", {
      ddl: req.body.ddl,
      output: result.output,
    }));
  } catch (err) {
    res.status(502).json({
      operation: "ddl",
      error: err.message,
    });
  }
});

app.post("/format", async (req, res) => {
  if (!ensureBody(res, req.body, "sql")) return;

  const keywords = ["select", "from", "where", "join", "group by", "order by", "insert", "update", "delete"];
  let formatted = req.body.sql.trim();

  for (const keyword of keywords) {
    const regex = new RegExp(`\\b${keyword}\\b`, "gi");
    formatted = formatted.replace(regex, keyword.toUpperCase());
  }

  formatted = formatted.replace(/\s+/g, " ").trim();

  try {
    // Use SQLcl round-trip to validate the formatted statement over stdio.
    const result = await runSqlclViaContainer("format", formatted);
    res.json(okEnvelope("format", {
      input: req.body.sql,
      formatted,
      output: result.output,
    }));
  } catch (err) {
    res.status(502).json({
      operation: "format",
      error: err.message,
    });
  }
});

app.post("/mcp", (_req, res) => {
  res.status(426).json({
    error: "Upgrade Required",
    message: "Use WebSocket at ws://<host>:<port>/mcp",
  });
});

const server = http.createServer(app);

const wss = new WebSocketServer({
  server,
  path: "/mcp",
});

wss.on("connection", (socket) => {
  socket.send(JSON.stringify({
    type: "mcp.connected",
    requestId: requestId(),
    message: "Connected to /mcp websocket endpoint",
  }));

  socket.on("message", (rawData) => {
    let payload;
    try {
      payload = JSON.parse(rawData.toString("utf8"));
    } catch (_err) {
      socket.send(JSON.stringify({
        type: "mcp.error",
        requestId: requestId(),
        error: "Invalid JSON payload",
      }));
      return;
    }

    socket.send(JSON.stringify({
      type: "mcp.response",
      requestId: requestId(),
      accepted: true,
      payload,
      timestamp: new Date().toISOString(),
    }));
  });
});

server.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`fortisai-oracle-node-api listening on port ${port}`);
});
