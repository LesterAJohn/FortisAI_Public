Use this skill only for time and timezone operations through the FortisAI repo time OpenAPI server.

Required OpenWebUI tool server:
- repo-time-server

Scope:
- Get current UTC or local time.
- Format the current time.
- Convert timestamps between timezones.
- Calculate elapsed time.
- Parse natural or ISO timestamp strings.
- List valid IANA time zones.

Execution guide:
1. Prefer /get_current_utc_time for canonical timestamps.
2. Use IANA timezone names, for example America/New_York or UTC.
3. When converting time, include the input timestamp, source timezone, and target timezone.
4. When calculating elapsed time, state the requested unit.
5. Return exact timestamps and timezone names in the answer.

Endpoint guide:
- GET /get_current_utc_time
- GET /get_current_local_time
- POST /format_time
- POST /convert_time
- POST /elapsed_time
- POST /parse_timestamp
- GET /list_time_zones
