# Config Loader

Load and validate the project's `sdlc.config.yml`.

## Steps

1. **Find config.** Look for `sdlc.config.yml` in the current working directory (project root). If not found, halt with:
   ```
   ERROR: No sdlc.config.yml found in the current directory.
   Create one from the template: see templates/sdlc.config.example.yml in the Loom plugin.
   ```

2. **Read and parse.** Read the file contents. Parse as YAML.

3. **Validate required fields.**
   - `version` must be `1`. If missing or different: `ERROR: sdlc.config.yml version must be 1 (found: {value})`
   - `project.backlog_cwd` must be present and non-empty. If missing: `ERROR: project.backlog_cwd is required in sdlc.config.yml`
   - `project.default_branch` is optional. If omitted, defaults to `main`.

4. **Verify backlog directory exists.** If not: `ERROR: Backlog directory not found: {resolved_path}`
