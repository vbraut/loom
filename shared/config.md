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

5. **Load conventions (optional).** If `project.conventions` is defined:
   - Resolve the path relative to the project root. It must be a directory.
   - Verify the directory exists. If not: `ERROR: Conventions directory not found: {resolved_path}`
   - List all `.md` files in the directory (non-recursive).
   - For each file, read the YAML frontmatter (between `---` delimiters at the top of the file). Extract the `agents` field — a list of agent names this convention targets. A special value `"*"` means all agents.
   - If a file has no frontmatter or no `agents` field: `ERROR: Convention file {filename} is missing required 'agents' frontmatter field.`
   - Build a map: `{conventions_map}` keyed by agent name → list of file contents (body after frontmatter). Files with `"*"` in their agents list are added to every agent's entry.
   - At agent invocation time, the orchestrator looks up the current agent name in `{conventions_map}` and concatenates matching convention contents into `## project_conventions`. If no conventions match, the section is omitted entirely.
