# Project-Scoped Rules

- **Unified Patch is Primary**: The unified patch file (`patches/0000-unified-fluffybeep.patch`) is the primary artifact of this project. The `fluffychat_src` directory serves as a reference/working area.
- **Generate Patches**: Whenever modifications are made to files in `fluffychat_src/`, always regenerate the unified patch file by running `git diff` inside `fluffychat_src` and saving the output to `patches/0000-unified-fluffybeep.patch`.
- **Line Endings & Encoding**: Ensure the patch file is saved with Unix line endings (LF) and raw UTF-8 binary encoding to prevent compilation/application failures on Linux runners.
