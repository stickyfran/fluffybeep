# Project-Scoped Rules

- **Unified Patch is Primary**: The unified patch file (`patches/0000-unified-fluffybeep.patch`) is the primary artifact of this project. The `fluffychat_src` directory serves as a reference/working area.

- **Generate Patches — CRITICAL RULE**:
  1. After modifying files in `fluffychat_src/`, **commit all changes first**: `git add -A` then `git commit -m "..."`.
  2. Then regenerate the patch using **`git diff c9c58c24f HEAD`** (NOT plain `git diff`). The upstream base commit is `c9c58c24f04304cc2ec263d891073805468383b8` (v2.9.4).
  3. Save the output as raw UTF-8 binary to `patches/0000-unified-fluffybeep.patch` using Python: `python -c "import subprocess; d = subprocess.check_output(['git', 'diff', 'c9c58c24f', 'HEAD']); open('../patches/0000-unified-fluffybeep.patch', 'wb').write(d)"`
  4. **NEVER use plain `git diff`** — it only captures unstaged changes and misses all previously committed Beeper modifications, causing CI patch failures.
  5. **NEVER use PowerShell redirection** (`>`) to write the patch — it produces UTF-16 encoding. Always use Python's binary write.

- **Validate the Patch**: After generating the patch, validate it applies cleanly by running `./patches/patch-manager.sh validate` from within `fluffychat_src/`. This will test the patch against a clean upstream worktree. Alternatively run: `git worktree add /tmp/test c9c58c24f && cd /tmp/test && git apply --check /path/to/patch`.

- **Why This Matters**: The CI (`build-fluffybeep.yml`) checks out the upstream FluffyChat at commit `c9c58c24f` and applies the patch to a **clean directory**. If the patch is wrong, the entire build fails with "patch does not apply" errors.

- **Line Endings & Encoding**: Ensure the patch file is saved with Unix line endings (LF) and raw UTF-8 binary encoding to prevent compilation/application failures on Linux runners.

- **patch-manager.sh commands**:
  - `regenerate` — Correct way to regenerate the patch (commits must be clean)
  - `validate` — Check patch applies cleanly to the upstream base
  - `patch-only` — Apply the patch (used by CI)
  - `clean` — Reverse the patch

---

# Critical Architectural Invariants (DO NOT VIOLATE)

### 1. WhatsApp Voice Notes & Audio Pipeline
- **Strict RFC 7845 OGG Opus Required**: The WhatsApp Beeper bridge (`mautrix-whatsapp`) and WhatsApp iOS/Android clients **strictly require** native `audio/ogg` Opus files with `.ogg` extensions for Push-to-Talk (PTT) voice bubbles with waveforms.
- **NEVER Fallback to AAC / .m4a**: Never convert recorded voice messages to `.m4a`, AAC, or generic audio attachments in `recording_view_model.dart` or `chat.dart`.
- **FFmpegKit Dependency**: Must strictly use `ffmpeg_kit_flutter_new_min: ^2.1.0` in `pubspec.yaml` to prevent JNI `.so` duplicate symbol conflicts (`mergeReleaseNativeLibs`) with `whisper_ggml`.
- **Remuxing via Stream Copy**: Normalization in `recording_view_model.dart` must ONLY use stream copy (`-c:a copy`) into a clean OGG container or pass through the native recorded `.ogg` Opus file.
- **Gradle Packaging**: `android/app/build.gradle.kts` must always preserve `packaging { jniLibs { pickFirsts += listOf(...) } }` to guard against native library collisions.

### 2. Beeper UI & Controllers Invariants
- **`ChatListController`**: Must retain all Beeper performance-cached getters (`roomCacheNotifier`, `spaceDelegateCandidates`, `hiddenInboxRoomIds`, `allRoomsSorted`, `roomDisplayNames`).
- **`ChatController`**: Must retain `isInputEmptyNotifier`, debouncing timers, and bridge-specific room handling.
- **Imports**: `space_view.dart` must always import `package:fluffychat/config/setting_keys.dart`.

### 3. Branch Base Commits
- **`main` branch (Active)**: Upstream FluffyChat base is `c9c58c24f04304cc2ec263d891073805468383b8` (v2.9.4).
- **`legacy-2.8` branch (Legacy)**: Upstream FluffyChat base is `259bc72fb897e99303058712fcdfaee033bd4d33` (v2.8.0).

