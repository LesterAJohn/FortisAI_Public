Use this skill only for local repository filesystem operations through the FortisAI repo filesystem OpenAPI server.

Required OpenWebUI tool server:
- repo-filesystem-server

Scope:
- Inspect allowed directories and directory trees.
- List files and collect metadata.
- Search file names and file content.
- Create directories, move paths, write files, edit files, or delete paths only when the user explicitly asks for that change.

Execution guide:
1. Start with /list_allowed_directories before reading or changing paths.
2. Prefer /directory_tree or /list_directory before targeted file operations.
3. Use /search_files for names and /search_content for text inside files.
4. For write, edit, move, or delete operations, restate the target path and expected effect.
5. Return concise file-path-focused summaries and avoid dumping large file contents.

Endpoint guide:
- GET /list_allowed_directories
- POST /directory_tree
- POST /list_directory
- POST /get_metadata
- POST /search_files
- POST /search_content
- POST /create_directory
- POST /write_file
- POST /edit_file
- POST /move_path
- POST /delete_path

Safety guide:
- Do not expose secrets, tokens, or credentials found in files.
- Do not modify unrelated files.
- Ask for confirmation before destructive operations.
