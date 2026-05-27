---
description: Full preflight gate — sync deps, lint, format-check, type-check, test.
allowed-tools: Bash, Read
argument-hint: ""
---

<!--
  TEMPLATE NOTE (delete when generating):
  This command is shown CWD-AWARE (two modes — one per code area). If the project
  has a SINGLE code area, delete "Step 0 — Detect mode" and the "Mode B" block,
  and keep just one linear gate. If it has two areas, fill both modes. Each mode's
  steps are the project's real quality commands for that area.
-->

Run the full quality gate for the current code area. **cwd-aware** — runs the right toolchain for whichever code area you're in.

Stops on first failure. Reports per-step pass/fail with the first ~20 lines of error output. Does NOT auto-fix on failure.

## Step 0 — Detect mode

```bash
case "$(pwd)" in
  */{{CODE_AREA_2_BASENAME}}|*/{{CODE_AREA_2_BASENAME}}/*) MODE={{CODE_AREA_2_NAME}} ;;
  *)                                                      MODE={{CODE_AREA_NAME}} ;;
esac
```

Announce the detected mode to the user before running steps. If the mode looks wrong for the user's intent, surface the cwd and ask before proceeding.

---

## {{CODE_AREA_NAME}} mode (cwd is `{{CODE_AREA}}` or repo root)

### Step 1 — Sync dependencies
```bash
{{INSTALL_CMD}}
```

### Step 2 — Lint
```bash
{{LINT_CMD}}
```

### Step 3 — Format check
```bash
{{FORMAT_CHECK_CMD}}
```

### Step 4 — Type check
```bash
{{TYPECHECK_CMD}}
```

### Step 5 — Test
```bash
{{TEST_CMD}}
```

---

## {{CODE_AREA_2_NAME}} mode (cwd is `{{CODE_AREA_2}}` or below)

<!-- Delete this whole section for a single-code-area project. -->

### Step 1 — Sync dependencies
```bash
{{INSTALL_CMD_2}}
```

### Step 2 — Lint
```bash
{{LINT_CMD_2}}
```

### Step 3 — Format check
```bash
{{FORMAT_CHECK_CMD_2}}
```

### Step 4 — Type check
```bash
{{TYPECHECK_CMD_2}}
```

### Step 5 — Test
```bash
{{TEST_CMD_2}}
```

### Step 6 — Build
```bash
{{BUILD_CMD_2}}
```

<!-- Keep a build step only if the area's build catches a class of errors the
     type-checker alone doesn't (e.g. a frontend production build). -->

---

## Output

**Success:**
> "Preflight clean (<mode>): lint ✓ + format ✓ + types ✓ + N tests pass"

**Failure (either mode):**
> "Preflight failed at Step N: <step name>"
> <first ~20 lines of error output>

## Forbidden in this command

- **Auto-fixing on failure.** The gate exists to catch problems; fixing them silently defeats the purpose.
- **Modifying baseline / ignore files to suppress failures.** Fix the underlying error.
- **Skipping steps.** Run in order; stop on first failure.
- **Cross-mode contamination.** Don't run one area's toolchain from another area's cwd. If cwd is wrong, fail loud with a clear message.
