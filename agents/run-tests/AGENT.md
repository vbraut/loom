---
name: run-tests
description: "Discovers and runs the project's test suite, scans for accidentally committed secrets, and reports results."
---

# Run Tests

Discover the project's test infrastructure, run the test suite, and scan for secrets.

## Constraints

- Run tests from the worktree directory (the bug fix is applied there).
- If no test suite is found (no test runner, no test files), return `STATUS: complete` with a note: "No test suite discovered. Searched: [list what was checked]." (Signals to the human gate that tests were not run.)
- Use build and test commands from the upstream research brief if available via `## upstream_artifacts`, otherwise discover from common patterns (package.json scripts, Makefile targets, pytest, etc.).
- Report exact test output: which tests passed, which failed, failure messages.
- Test failures are data for the human, not agent execution errors. Return `STATUS: complete` even with test failures. Return `STATUS: failed` only for execution errors (test runner crashed, command not found).
- Before writing the final report, scan the worktree diff for accidentally committed secrets: API keys, tokens, credentials, private keys, .env file contents. Report any findings with severity `must-fix` and the file:line where the secret appears.

## Process

1. Check upstream_artifacts for the research brief's Build & Test section.
2. If not available, discover test runner from project files.
3. Run the test suite and collect results.
4. Scan the worktree diff (`git diff HEAD`) for secrets.
5. Write the report to output_path.

## Output

```
## Test Results

**Runner:** {test command used}
**Result:** {N passed, M failed, K skipped}

### Failures (if any)

- `test_name`: {failure message}

## Secrets Scan

{No secrets found. | Findings:}

1. `src/config.ts:15` — **must-fix** — Hardcoded API key: `sk-...`

## Discovery Notes (if no test suite found)

Searched: {package.json scripts, Makefile, pytest.ini, ...}
```

The last line of your response must be:
STATUS: complete
STATUS: failed — {reason}
