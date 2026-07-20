# Project-Scoped Rules

- **Unified Patch is Primary**: The unified patch file (`patches/0000-unified-fluffybeep.patch`) is the primary artifact of this project. The `fluffychat_src` directory serves as a reference/working area.

- **Generate Patches — CRITICAL RULE**:
  1. After modifying files in `fluffychat_src/`, **commit all changes first**: `git add -A` then `git commit -m "..."`.
  2. Then regenerate the patch using **`git diff 259bc72 HEAD`** (NOT plain `git diff`). The upstream base commit is `259bc72fb897e99303058712fcdfaee033bd4d33`.
  3. Save the output as raw UTF-8 binary to `patches/0000-unified-fluffybeep.patch` using Python: `python -c "import subprocess; d = subprocess.check_output(['git', 'diff', '259bc72', 'HEAD']); open('../patches/0000-unified-fluffybeep.patch', 'wb').write(d)"`
  4. **NEVER use plain `git diff`** — it only captures unstaged changes and misses all previously committed Beeper modifications, causing CI patch failures.
  5. **NEVER use PowerShell redirection** (`>`) to write the patch — it produces UTF-16 encoding. Always use Python's binary write.

- **Validate the Patch**: After generating the patch, validate it applies cleanly by running `./patches/patch-manager.sh validate` from within `fluffychat_src/`. This will test the patch against a clean upstream worktree. Alternatively run: `git worktree add /tmp/test 259bc72 && cd /tmp/test && git apply --check /path/to/patch`.

- **Why This Matters**: The CI (`build-fluffybeep.yml`) checks out the upstream FluffyChat at commit `259bc72` and applies the patch to a **clean directory**. If the patch is wrong, the entire build fails with "patch does not apply" errors.

- **Line Endings & Encoding**: Ensure the patch file is saved with Unix line endings (LF) and raw UTF-8 binary encoding to prevent compilation/application failures on Linux runners.

- **patch-manager.sh commands**:
  - `regenerate` — Correct way to regenerate the patch (commits must be clean)
  - `validate` — Check patch applies cleanly to the upstream base
  - `patch-only` — Apply the patch (used by CI)
  - `clean` — Reverse the patch
