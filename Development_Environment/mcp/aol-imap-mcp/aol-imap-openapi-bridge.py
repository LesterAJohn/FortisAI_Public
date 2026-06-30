#!/usr/bin/env python3
"""FortisAI AOL IMAP action bridge for n8n workflows."""

from __future__ import annotations

import imaplib
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from contextlib import contextmanager
from dataclasses import dataclass
from email import message_from_bytes
from email.header import decode_header
from email.message import Message
from email.utils import parseaddr
from typing import Any, Dict, Iterator, List, Optional, Tuple

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


APP_NAME = "FortisAI AOL IMAP OpenAPI Bridge"
BRIDGE_PORT = int(os.environ.get("AOL_IMAP_BRIDGE_PORT", "8101"))
AOL_IMAP_HOST = os.environ.get("AOL_IMAP_HOST", "imap.aol.com").strip() or "imap.aol.com"
AOL_IMAP_PORT = int(os.environ.get("AOL_IMAP_PORT", "993"))
AOL_IMAP_TIMEOUT_SECONDS = int(os.environ.get("AOL_IMAP_TIMEOUT_SECONDS", "30"))
VAULT_ADDR = (os.environ.get("FORTISAI_VAULT_ADDR") or os.environ.get("VAULT_ADDR") or "").rstrip("/")
VAULT_TOKEN = os.environ.get("VAULT_TOKEN", "").strip()

DEFAULT_SPAM_FOLDER = os.environ.get("AOL_IMAP_SPAM_FOLDER", "Spam").strip() or "Spam"
AOL_SPAM_FOLDER_ALIASES = [
    folder.strip()
    for folder in os.environ.get("AOL_IMAP_SPAM_FOLDER_ALIASES", "Spam,Bulk,Junk").split(",")
    if folder.strip()
]


@dataclass(frozen=True)
class AccountConfig:
    account_id: str
    email: str
    password_path: str


ACCOUNTS: Dict[str, AccountConfig] = {
    "lester_aol": AccountConfig(
        account_id="lester_aol",
        email="LesterAJohn@aol.com",
        password_path="aol/imap/lesterajohn/password",
    ),
    "laj0703_aol": AccountConfig(
        account_id="laj0703_aol",
        email="laj0703@aol.com",
        password_path="aol/imap/laj0703/password",
    ),
    "lester1_aol": AccountConfig(
        account_id="lester1_aol",
        email="LesterAJohn1@aol.com",
        password_path="aol/imap/lesterajohn1/password",
    ),
}

app = FastAPI(
    title=APP_NAME,
    version="1.0.0",
    description=(
        "Vault-backed AOL IMAP actions used by FortisAI n8n spam workflows. "
        "The bridge moves classifier-detected spam into the Spam folder and deletes Spam-folder harvest messages after memory ingestion."
    ),
)


class MailboxRequest(BaseModel):
    account_id: str = Field(..., description="Configured AOL account id.")


class MoveMessageRequest(BaseModel):
    account_id: str = Field(..., description="Configured AOL account id.")
    source_folder: str = Field("Inbox", description="Folder that currently contains the message.")
    target_folder: str = Field(default_factory=lambda: DEFAULT_SPAM_FOLDER, description="Destination folder.")
    uid: Optional[str] = Field(None, description="IMAP UID when available from n8n.")
    message_id: Optional[str] = Field(None, description="RFC Message-ID or provider message id fallback.")
    expunge: bool = Field(True, description="Expunge deleted source message after COPY fallback.")
    timeout_seconds: int = Field(default=AOL_IMAP_TIMEOUT_SECONDS, ge=1, le=180)


class DeleteMessageRequest(BaseModel):
    account_id: str = Field(..., description="Configured AOL account id.")
    source_folder: str = Field(default_factory=lambda: DEFAULT_SPAM_FOLDER, description="Folder that contains the message.")
    uid: Optional[str] = Field(None, description="IMAP UID when available from n8n.")
    message_id: Optional[str] = Field(None, description="RFC Message-ID or provider message id fallback.")
    expunge: bool = Field(True, description="Expunge deleted message immediately.")
    timeout_seconds: int = Field(default=AOL_IMAP_TIMEOUT_SECONDS, ge=1, le=180)


class DeleteMessageItem(BaseModel):
    uid: Optional[str] = Field(None, description="IMAP UID when available from n8n.")
    message_id: Optional[str] = Field(None, description="RFC Message-ID or provider message id fallback.")


class DeleteMessagesRequest(BaseModel):
    account_id: str = Field(..., description="Configured AOL account id.")
    source_folder: str = Field(default_factory=lambda: DEFAULT_SPAM_FOLDER, description="Folder that contains the messages.")
    messages: List[DeleteMessageItem] = Field(default_factory=list, description="Messages to delete from the selected folder.")
    expunge: bool = Field(True, description="Expunge deleted messages after all STORE operations complete.")
    timeout_seconds: int = Field(default=AOL_IMAP_TIMEOUT_SECONDS, ge=1, le=180)


class FetchMessagesRequest(BaseModel):
    account_id: str = Field(..., description="Configured AOL account id.")
    source_folder: str = Field(default_factory=lambda: DEFAULT_SPAM_FOLDER, description="Folder to scan.")
    criteria: str = Field("ALL", description='IMAP UID SEARCH criteria such as "ALL" or "UNSEEN".')
    limit: int = Field(25, ge=1, le=100, description="Maximum messages to return.")
    timeout_seconds: int = Field(default=AOL_IMAP_TIMEOUT_SECONDS, ge=1, le=180)


def _vault_read(path: str) -> Optional[str]:
    if not VAULT_ADDR or not VAULT_TOKEN:
        return None

    clean_path = path.strip("/")
    if not clean_path or ".." in clean_path:
        return None

    encoded_path = "/".join(urllib.parse.quote(part, safe="") for part in clean_path.split("/"))
    url = f"{VAULT_ADDR}/v1/secret/data/fortisai/dev/{encoded_path}"
    request = urllib.request.Request(url, headers={"X-Vault-Token": VAULT_TOKEN}, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            body = response.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return None
        return None
    except Exception:
        return None

    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        return None

    data = payload.get("data", {}).get("data", {})
    value = data.get("value")
    if value is None and len(data) == 1:
        value = next(iter(data.values()))
    return str(value) if value is not None else None


def _account(account_id: str) -> AccountConfig:
    clean = account_id.strip()
    account = ACCOUNTS.get(clean)
    if not account:
        raise HTTPException(status_code=404, detail=f"Unknown AOL account id: {account_id}")
    return account


def _account_password(account: AccountConfig) -> str:
    value = _vault_read(account.password_path)
    if not value:
        raise HTTPException(
            status_code=503,
            detail=f"Missing Vault secret: secret/fortisai/dev/{account.password_path}",
        )
    return value


@contextmanager
def _imap_session(account: AccountConfig, timeout_seconds: int = AOL_IMAP_TIMEOUT_SECONDS) -> Iterator[imaplib.IMAP4_SSL]:
    password = _account_password(account)
    previous_timeout = getattr(imaplib, "_MAXLINE", None)
    if previous_timeout is not None:
        imaplib._MAXLINE = max(imaplib._MAXLINE, 10000000)

    imap = imaplib.IMAP4_SSL(AOL_IMAP_HOST, AOL_IMAP_PORT, timeout=timeout_seconds)
    try:
        typ, data = imap.login(account.email, password)
        if typ != "OK":
            raise HTTPException(status_code=502, detail=f"IMAP login failed for {account.email}: {_decode_response(data)}")
        yield imap
    except HTTPException:
        raise
    except imaplib.IMAP4.error as exc:
        raise HTTPException(status_code=502, detail=f"IMAP error for {account.email}: {exc}") from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"IMAP connection error for {account.email}: {type(exc).__name__}: {exc}") from exc
    finally:
        try:
            imap.logout()
        except Exception:
            pass


def _decode_response(data: Any) -> str:
    if isinstance(data, (list, tuple)):
        return " ".join(_decode_response(item) for item in data)
    if isinstance(data, bytes):
        return data.decode("utf-8", errors="replace")
    return str(data)


def _decode_mailbox_name(encoded: str) -> str:
    value = encoded.strip()
    match = re.search(r'(?:"([^"]+)"|(\S+))$', value)
    name = (match.group(1) or match.group(2)) if match else value
    name = name.strip('"')
    try:
        return imaplib.IMAP4._decode_utf7(name)
    except Exception:
        return name


def _mailbox_exists(mailboxes: List[str], folder: str) -> bool:
    wanted = folder.strip().lower()
    return any(name.lower() == wanted for name in mailboxes)


def _resolve_mailbox(mailboxes: List[str], folder: str) -> str:
    wanted = folder.strip().lower()
    for name in mailboxes:
        if name.lower() == wanted:
            return name
    return folder


def _spam_fetch_folders(mailboxes: List[str], folder: str) -> List[str]:
    requested = folder.strip() or DEFAULT_SPAM_FOLDER
    if requested.lower() not in {DEFAULT_SPAM_FOLDER.lower(), "spam"}:
        return [_resolve_mailbox(mailboxes, requested)]

    candidates = [requested, DEFAULT_SPAM_FOLDER, *AOL_SPAM_FOLDER_ALIASES, "Bulk", "Junk"]
    folders: List[str] = []
    seen = set()
    for candidate in candidates:
        resolved = _resolve_mailbox(mailboxes, candidate)
        if not _mailbox_exists(mailboxes, resolved):
            continue
        key = resolved.lower()
        if key in seen:
            continue
        seen.add(key)
        folders.append(resolved)
    return folders or [requested]


def _list_mailboxes(imap: imaplib.IMAP4_SSL) -> List[str]:
    typ, data = imap.list()
    if typ != "OK":
        raise HTTPException(status_code=502, detail=f"Unable to list IMAP mailboxes: {_decode_response(data)}")
    names: List[str] = []
    for item in data or []:
        if not item:
            continue
        names.append(_decode_mailbox_name(_decode_response(item)))
    return sorted(set(names), key=str.lower)


def _select_folder(imap: imaplib.IMAP4_SSL, folder: str) -> Dict[str, Any]:
    typ, data = imap.select(folder, readonly=False)
    if typ == "OK":
        return {"folder": folder, "message_count": int((data or [b"0"])[0] or 0)}

    mailboxes = _list_mailboxes(imap)
    for name in mailboxes:
        if name.lower() == folder.lower():
            typ, data = imap.select(name, readonly=False)
            if typ == "OK":
                return {"folder": name, "message_count": int((data or [b"0"])[0] or 0)}

    raise HTTPException(
        status_code=404,
        detail={
            "message": f"IMAP folder not found: {folder}",
            "available_folders": mailboxes,
        },
    )


def _clean_message_id(message_id: Optional[str]) -> str:
    text = str(message_id or "").strip()
    if not text:
        return ""
    if text.startswith("<") and text.endswith(">"):
        return text
    if "@" in text and not text.startswith("<"):
        return f"<{text}>"
    return text


def _extract_uid(value: Optional[str]) -> str:
    text = str(value or "").strip()
    if not text:
        return ""
    match = re.search(r"\b(\d+)\b", text)
    return match.group(1) if match else text


def _find_uid(imap: imaplib.IMAP4_SSL, uid: Optional[str], message_id: Optional[str]) -> Tuple[str, Dict[str, Any]]:
    clean_uid = _extract_uid(uid)
    if clean_uid:
        typ, data = imap.uid("SEARCH", None, "UID", clean_uid)
        found = _space_split_first(data)
        if typ == "OK" and clean_uid in found:
            return clean_uid, {"matched_by": "uid"}

    clean_message_id = _clean_message_id(message_id)
    if clean_message_id:
        for candidate in (clean_message_id, clean_message_id.strip("<>")):
            typ, data = imap.uid("SEARCH", None, "HEADER", "Message-ID", _quote_search_value(candidate))
            found = _space_split_first(data)
            if typ == "OK" and found:
                return found[0], {"matched_by": "message_id", "search_value": candidate}

    raise HTTPException(
        status_code=404,
        detail={
            "message": "Message was not found in selected IMAP folder.",
            "uid": clean_uid,
            "message_id": clean_message_id,
        },
    )


def _quote_search_value(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _space_split_first(data: Any) -> List[str]:
    if not data:
        return []
    first = data[0] if isinstance(data, (list, tuple)) else data
    if not first:
        return []
    if isinstance(first, bytes):
        first = first.decode("ascii", errors="ignore")
    return [part for part in str(first).split() if part]


def _uid_action_ok(result: Tuple[str, List[bytes]], operation: str) -> None:
    typ, data = result
    if typ != "OK":
        raise HTTPException(status_code=502, detail=f"IMAP UID {operation} failed: {_decode_response(data)}")


def _move_uid(imap: imaplib.IMAP4_SSL, uid: str, target_folder: str, expunge: bool) -> Dict[str, Any]:
    typ, data = imap.uid("MOVE", uid, target_folder)
    if typ == "OK":
        return {"operation": "MOVE", "target_folder": target_folder, "response": _decode_response(data)}

    copy_typ, copy_data = imap.uid("COPY", uid, target_folder)
    if copy_typ != "OK":
        raise HTTPException(
            status_code=502,
            detail={
                "message": "IMAP MOVE and COPY fallback failed.",
                "move_response": _decode_response(data),
                "copy_response": _decode_response(copy_data),
            },
        )
    _uid_action_ok(imap.uid("STORE", uid, "+FLAGS", r"(\Deleted)"), "STORE")
    if expunge:
        imap.expunge()
    return {
        "operation": "COPY_DELETE",
        "target_folder": target_folder,
        "move_response": _decode_response(data),
        "copy_response": _decode_response(copy_data),
        "expunged": expunge,
    }


def _mark_uid_deleted(imap: imaplib.IMAP4_SSL, uid: str) -> Dict[str, Any]:
    _uid_action_ok(imap.uid("STORE", uid, "+FLAGS", r"(\Deleted)"), "STORE")
    return {"operation": "STORE_DELETE"}


def _expunge_deleted(imap: imaplib.IMAP4_SSL) -> str:
    typ, data = imap.expunge()
    if typ != "OK":
        raise HTTPException(status_code=502, detail=f"IMAP EXPUNGE failed: {_decode_response(data)}")
    return _decode_response(data)


def _delete_uid(imap: imaplib.IMAP4_SSL, uid: str, expunge: bool) -> Dict[str, Any]:
    _mark_uid_deleted(imap, uid)
    expunge_response = ""
    if expunge:
        expunge_response = _expunge_deleted(imap)
    return {"operation": "DELETE", "expunged": expunge, "expunge_response": expunge_response}


def _decode_bytes(data: bytes, charset: Optional[str]) -> str:
    candidates = []
    if charset:
        candidates.append(charset)
    candidates.extend(["utf-8", "latin-1"])
    for candidate in candidates:
        encoding = str(candidate or "").strip().lower()
        if not encoding or encoding in {"unknown", "unknown-8bit", "x-unknown"}:
            continue
        try:
            return data.decode(encoding, errors="replace")
        except (LookupError, UnicodeError):
            continue
    return data.decode("utf-8", errors="replace")


def _decode_header_value(value: Optional[str]) -> str:
    if not value:
        return ""
    parts: List[str] = []
    for data, charset in decode_header(value):
        if isinstance(data, bytes):
            parts.append(_decode_bytes(data, charset))
        else:
            parts.append(str(data))
    return "".join(parts).strip()


def _message_text(message: Message, max_chars: int = 4000) -> str:
    chunks: List[str] = []
    if message.is_multipart():
        for part in message.walk():
            content_type = part.get_content_type()
            disposition = str(part.get("Content-Disposition", "")).lower()
            if "attachment" in disposition:
                continue
            if content_type not in {"text/plain", "text/html"}:
                continue
            payload = part.get_payload(decode=True)
            if payload is None:
                continue
            text = _decode_bytes(payload, part.get_content_charset())
            chunks.append(text)
            if sum(len(chunk) for chunk in chunks) >= max_chars:
                break
    else:
        payload = message.get_payload(decode=True)
        if payload is not None:
            chunks.append(_decode_bytes(payload, message.get_content_charset()))
    text = "\n".join(chunks)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text[:max_chars]


def _parse_message(uid: str, raw: bytes, account: AccountConfig, folder: str) -> Dict[str, Any]:
    message = message_from_bytes(raw)
    message_id = _decode_header_value(message.get("Message-ID", "")).strip()
    from_header = _decode_header_value(message.get("From", ""))
    to_header = _decode_header_value(message.get("To", ""))
    subject = _decode_header_value(message.get("Subject", ""))
    date = _decode_header_value(message.get("Date", ""))
    from_name, from_email = parseaddr(from_header)
    snippet = _message_text(message)
    return {
        "account_id": account.account_id,
        "sourceMailbox": account.email,
        "sourceFolder": folder,
        "imapUid": uid,
        "uid": uid,
        "messageId": message_id or uid,
        "sourceMessageId": message_id or uid,
        "rfcMessageId": message_id,
        "sourceFrom": from_header,
        "sourceFromEmail": from_email,
        "sourceFromName": from_name,
        "sourceTo": to_header or account.email,
        "sourceSubject": subject,
        "sourceDate": date,
        "sourceSnippet": snippet,
        "From": from_header,
        "To": to_header or account.email,
        "Subject": subject,
        "snippet": snippet,
        "labels": [{"id": folder, "name": folder}],
        "sourceLabels": [{"id": folder, "name": folder}],
    }


def _search_uids(imap: imaplib.IMAP4_SSL, criteria: str) -> List[str]:
    clean = criteria.strip() or "ALL"
    if clean.startswith("["):
        try:
            parsed = json.loads(clean)
            if isinstance(parsed, list):
                args = [str(item) for item in parsed]
            else:
                args = ["ALL"]
        except json.JSONDecodeError:
            args = ["ALL"]
    else:
        args = clean.split()
    typ, data = imap.uid("SEARCH", None, *args)
    if typ != "OK":
        raise HTTPException(status_code=502, detail=f"IMAP UID SEARCH failed: {_decode_response(data)}")
    return _space_split_first(data)


def _fetch_message(imap: imaplib.IMAP4_SSL, uid: str) -> bytes:
    typ, data = imap.uid("FETCH", uid, "(BODY.PEEK[])")
    if typ != "OK":
        raise HTTPException(status_code=502, detail=f"IMAP UID FETCH failed for {uid}: {_decode_response(data)}")
    for item in data or []:
        if isinstance(item, tuple) and len(item) >= 2 and isinstance(item[1], bytes):
            return item[1]
    raise HTTPException(status_code=502, detail=f"IMAP UID FETCH returned no message body for {uid}")


def _folder_message_count(imap: imaplib.IMAP4_SSL, folder: str) -> Optional[int]:
    try:
        selected = _select_folder(imap, folder)
        return selected.get("message_count")
    except Exception:
        return None


@app.get("/healthz", include_in_schema=False)
def healthz() -> Dict[str, Any]:
    return {
        "ok": True,
        "service": "aol-imap",
        "host": AOL_IMAP_HOST,
        "port": AOL_IMAP_PORT,
        "accounts": list(ACCOUNTS.keys()),
        "spam_folder_aliases": AOL_SPAM_FOLDER_ALIASES,
    }


@app.get("/aol_imap_connection_info", operation_id="aol_imap_connection_info")
def aol_imap_connection_info() -> Dict[str, Any]:
    return {
        "ok": True,
        "bridge": "fortisai-mcp-openapi-aol-imap",
        "host": AOL_IMAP_HOST,
        "port": AOL_IMAP_PORT,
        "vault_configured": bool(VAULT_ADDR and VAULT_TOKEN),
        "default_spam_folder": DEFAULT_SPAM_FOLDER,
        "spam_folder_aliases": AOL_SPAM_FOLDER_ALIASES,
        "accounts": [
            {
                "account_id": account.account_id,
                "email": account.email,
                "password_vault_path": f"secret/fortisai/dev/{account.password_path}",
                "has_password": bool(_vault_read(account.password_path)),
            }
            for account in ACCOUNTS.values()
        ],
    }


@app.post("/aol_imap_list_mailboxes", operation_id="aol_imap_list_mailboxes")
def aol_imap_list_mailboxes(request: MailboxRequest) -> Dict[str, Any]:
    account = _account(request.account_id)
    started = time.monotonic()
    with _imap_session(account) as imap:
        mailboxes = _list_mailboxes(imap)
    return {
        "ok": True,
        "account_id": account.account_id,
        "email": account.email,
        "mailboxes": mailboxes,
        "elapsed_ms": round((time.monotonic() - started) * 1000, 2),
    }


@app.post("/aol_imap_move_message", operation_id="aol_imap_move_message")
def aol_imap_move_message(request: MoveMessageRequest) -> Dict[str, Any]:
    account = _account(request.account_id)
    started = time.monotonic()
    with _imap_session(account, timeout_seconds=request.timeout_seconds) as imap:
        selected = _select_folder(imap, request.source_folder)
        mailboxes = _list_mailboxes(imap)
        if not _mailbox_exists(mailboxes, request.target_folder):
            raise HTTPException(
                status_code=404,
                detail={"message": f"Target folder not found: {request.target_folder}", "available_folders": mailboxes},
            )
        target_folder = _resolve_mailbox(mailboxes, request.target_folder)
        try:
            uid, match = _find_uid(imap, request.uid, request.message_id)
        except HTTPException as exc:
            if exc.status_code != 404:
                raise
            return {
                "ok": True,
                "account_id": account.account_id,
                "email": account.email,
                "source_folder": selected["folder"],
                "target_folder": target_folder,
                "uid": _extract_uid(request.uid),
                "match": {"matched_by": "not_found"},
                "action": {"operation": "SKIP", "reason": "message_not_found_in_source_folder"},
                "skipped": True,
                "detail": exc.detail,
                "elapsed_ms": round((time.monotonic() - started) * 1000, 2),
            }
        action = _move_uid(imap, uid, target_folder, request.expunge)
    return {
        "ok": True,
        "account_id": account.account_id,
        "email": account.email,
        "source_folder": selected["folder"],
        "target_folder": target_folder,
        "uid": uid,
        "match": match,
        "action": action,
        "elapsed_ms": round((time.monotonic() - started) * 1000, 2),
    }


@app.post("/aol_imap_delete_message", operation_id="aol_imap_delete_message")
def aol_imap_delete_message(request: DeleteMessageRequest) -> Dict[str, Any]:
    account = _account(request.account_id)
    started = time.monotonic()
    with _imap_session(account, timeout_seconds=request.timeout_seconds) as imap:
        selected = _select_folder(imap, request.source_folder)
        try:
            uid, match = _find_uid(imap, request.uid, request.message_id)
        except HTTPException as exc:
            if exc.status_code != 404:
                raise
            return {
                "ok": True,
                "account_id": account.account_id,
                "email": account.email,
                "source_folder": selected["folder"],
                "uid": _extract_uid(request.uid),
                "match": {"matched_by": "not_found"},
                "action": {"operation": "SKIP", "reason": "message_not_found_in_source_folder"},
                "skipped": True,
                "detail": exc.detail,
                "elapsed_ms": round((time.monotonic() - started) * 1000, 2),
            }
        action = _delete_uid(imap, uid, request.expunge)
    return {
        "ok": True,
        "account_id": account.account_id,
        "email": account.email,
        "source_folder": selected["folder"],
        "uid": uid,
        "match": match,
        "action": action,
        "elapsed_ms": round((time.monotonic() - started) * 1000, 2),
    }


@app.post("/aol_imap_delete_messages", operation_id="aol_imap_delete_messages")
def aol_imap_delete_messages(request: DeleteMessagesRequest) -> Dict[str, Any]:
    account = _account(request.account_id)
    started = time.monotonic()
    results: List[Dict[str, Any]] = []
    deleted = 0
    skipped = 0
    errors = 0

    if not request.messages:
        return {
            "ok": True,
            "skipped": True,
            "detail": "No messages supplied.",
            "account_id": account.account_id,
            "email": account.email,
            "source_folder": request.source_folder,
            "deleted": 0,
            "elapsed_ms": round((time.monotonic() - started) * 1000, 2),
        }

    with _imap_session(account, timeout_seconds=request.timeout_seconds) as imap:
        selected = _select_folder(imap, request.source_folder)
        for message in request.messages:
            try:
                uid, match = _find_uid(imap, message.uid, message.message_id)
                action = _mark_uid_deleted(imap, uid)
            except HTTPException as exc:
                if exc.status_code == 404:
                    skipped += 1
                    results.append(
                        {
                            "ok": True,
                            "skipped": True,
                            "uid": _extract_uid(message.uid),
                            "message_id": _clean_message_id(message.message_id),
                            "detail": exc.detail,
                        }
                    )
                    continue
                errors += 1
                results.append(
                    {
                        "ok": False,
                        "uid": _extract_uid(message.uid),
                        "message_id": _clean_message_id(message.message_id),
                        "detail": exc.detail,
                    }
                )
                continue

            deleted += 1
            results.append(
                {
                    "ok": True,
                    "uid": uid,
                    "message_id": _clean_message_id(message.message_id),
                    "match": match,
                    "action": action,
                }
            )

        expunge_response = ""
        if request.expunge and deleted:
            expunge_response = _expunge_deleted(imap)

    return {
        "ok": errors == 0,
        "account_id": account.account_id,
        "email": account.email,
        "source_folder": selected["folder"],
        "requested": len(request.messages),
        "deleted": deleted,
        "skipped": skipped,
        "errors": errors,
        "expunged": request.expunge and deleted > 0,
        "expunge_response": expunge_response,
        "results": results,
        "elapsed_ms": round((time.monotonic() - started) * 1000, 2),
    }


@app.post("/aol_imap_folder_counts", operation_id="aol_imap_folder_counts")
def aol_imap_folder_counts(request: MailboxRequest) -> Dict[str, Any]:
    account = _account(request.account_id)
    with _imap_session(account) as imap:
        mailboxes = _list_mailboxes(imap)
        counts = {
            folder: _folder_message_count(imap, folder)
            for folder in mailboxes
            if folder.lower() in {"inbox", "spam", "junk", "bulk"}
        }
    return {"ok": True, "account_id": account.account_id, "email": account.email, "counts": counts}


@app.post("/aol_imap_fetch_messages", operation_id="aol_imap_fetch_messages")
def aol_imap_fetch_messages(request: FetchMessagesRequest) -> Dict[str, Any]:
    account = _account(request.account_id)
    started = time.monotonic()
    with _imap_session(account, timeout_seconds=request.timeout_seconds) as imap:
        mailboxes = _list_mailboxes(imap)
        folders = _spam_fetch_folders(mailboxes, request.source_folder)
        folder_results: List[Dict[str, Any]] = []
        messages: List[Dict[str, Any]] = []
        matched = 0
        for folder in folders:
            selected = _select_folder(imap, folder)
            uids = _search_uids(imap, request.criteria)
            matched += len(uids)
            selected_uids = uids[-request.limit :]
            folder_messages = [
                _parse_message(uid=uid, raw=_fetch_message(imap, uid), account=account, folder=selected["folder"])
                for uid in selected_uids
            ]
            folder_results.append(
                {
                    "folder": selected["folder"],
                    "message_count": selected.get("message_count"),
                    "matched": len(uids),
                    "returned": len(folder_messages),
                }
            )
            messages.extend(folder_messages)
    return {
        "ok": True,
        "account_id": account.account_id,
        "email": account.email,
        "source_folder": request.source_folder,
        "selected_folders": folder_results,
        "criteria": request.criteria,
        "matched": matched,
        "returned": len(messages),
        "messages": messages,
        "elapsed_ms": round((time.monotonic() - started) * 1000, 2),
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=BRIDGE_PORT)
