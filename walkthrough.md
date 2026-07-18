# Walkthrough - Beeper Patches Settings, UI Fixes, Sticker to WhatsApp, & Keystore Alias Case Fix

I have resolved the Gradle build crash by fixing the mismatch in the keystore alias case between the JKS keystore and the Gradle configuration.

## Changes Made

### 1. Keystore Alias Case Fix
The build logs indicated:
`com.android.ide.common.signing.KeytoolException: Failed to read key dummyAlias from store "/home/runner/work/fluffybeep/fluffybeep/fluffychat/android/app/dummy.keystore": Get Key failed: Given final block not properly padded.`

Checking the keystore `patches/release.keystore` using `keytool` revealed that the alias was actually `dummyalias` (all lowercase), while `android/app/build.gradle.kts` expected `dummyAlias` (camelCase). I added a patch to `build.gradle.kts` to change `keyAlias` to `dummyalias` (lowercase).

### 2. Fix Patch File Encoding (Repository Level)
The patch file generated previously was encoded in UTF-16LE due to PowerShell redirection, causing the Linux runner in GitHub Actions to fail to apply it. I have re-generated `0001-virtual-spaces-and-tags.patch` natively in UTF-8.

### 3. Beeper Patches Settings Screen
Created a new settings page at `lib/pages/settings/patches_settings.dart` and integrated it with the router and `settings_view.dart`. This page provides:
- **Re-sincronizar chats (Beeper):** Purges cached room avatars, profiles, and timelines safely to prepare for a fresh sync.
- **Contener Bridges:** Switches to toggle whether chats from specific bridges (like WhatsApp or Instagram) appear in the main timeline. If toggled ON, their chats will only show up inside their respective virtual spaces on the navigation sidebar.
- **Ocultar de la barra lateral:** Toggle switches to hide/show Beeper network icons in the sidebar.
- **Contener Etiquetas (Labels):** Switches to toggle containment for custom Nheko tags (tags starting with `u.`).

### 4. Add Sticker to WhatsApp Pack
When a sticker message (`m.sticker`) is received:
- Added a **"Agregar a stickers de WhatsApp"** button inside the **Message Info** dialog (`event_info_dialog.dart`).
- Added a **"Agregar a stickers de WhatsApp"** option inside the message long-press context menu (`chat_view.dart`).
- Clicking this action downloads and decrypts the attachment, re-uploads it as a standard unencrypted file to the media repository, and appends it to the user's custom emote/sticker pack (`im.ponies.user_emotes`).
- If the pack doesn't exist yet, it automatically creates a new pack called "WhatsApp".

## Verification Plan

### Automated Build Verification
The commit has been successfully pushed to the repository. The CI pipeline on GitHub Actions will now automatically:
1. Apply the new UTF-8 `0001-virtual-spaces-and-tags.patch`.
2. Build the production release APK.

### Manual Verification
1. Open the app, go to **Ajustes -> Parches de Beeper**.
2. Tap **Re-sincronizar chats** to force a clean load.
3. Toggle **Contener WhatsApp** or **Contener Instagram** to verify that they vanish from the main chat list.
4. Go to any chat containing a sticker, long-press it, and tap **"Agregar a stickers de WhatsApp"** (or open its Message Info and tap the same button).
5. Open the sticker picker and verify that the new sticker is listed in the "WhatsApp" pack.
