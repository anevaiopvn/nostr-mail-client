# AGENTS.md — Nostr Mail Client (Nmail)

This file contains project-specific context for AI coding agents. Read it before making any changes.

---

## Project Overview

**Nostr Mail Client** (branded as **Nmail**) is a cross-platform Flutter application that provides a decentralized, privacy-first email experience built on the [Nostr protocol](https://github.com/nostr-protocol/nips). Users own their identity (pubkey/npub) and data; there is no central authority that can revoke an address or scan messages.

The app communicates over Nostr relays, stores data locally, and supports sending/receiving encrypted messages both to other Nostr users and to traditional email addresses via bridge domains.

- **Primary platforms**: Android, Linux, Web
- **Secondary platform**: macOS (has CI workflow and runner files)
- **Pubspec version**: `0.10.0+14`
- **Dart SDK constraint**: `^3.10.8`

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (stable channel) |
| Language | Dart |
| State management & routing | `get` (GetX) |
| Nostr protocol | `ndk` + `ndk_flutter` (Nostr Development Kit) |
| Email domain logic | `nostr_mail` package |
| Local database | `sembast` (all platforms, including web via `sembast_web`) |
| Secure storage | `flutter_secure_storage` (handled by NDK) |
| Rich text editor | `flutter_quill` + `vsc_quill_delta_to_html` |
| MIME mail construction | `enough_mail_plus` |
| PDF viewer | `pdfrx` |
| HTML rendering | `flutter_widget_from_html_core` |
| Toast notifications | `toastification` |
| File handling | `file_picker`, `file_saver` |
| Icons / images | `flutter_svg` |
| Desktop window chrome | `window_manager` |
| Theming | `system_theme` (accent color on native) |

---

## Project Structure

```
lib/
├── main.dart                 # Entry point: initializes window manager, storage, NDK, theme, routes
├── app/
│   ├── bindings/
│   │   └── initial_binding.dart       # Lazy-puts SettingsController & ContactsService
│   ├── config/
│   │   ├── app_config.dart            # Sync debounce duration (60s)
│   │   └── nostr_config.dart          # Bootstrap relays, recommended DM/Blossom/bridge lists
│   └── routes/
│       ├── app_routes.dart            # GetX route definitions + constants
│       └── middlewares/
│           ├── auth_middleware.dart
│           ├── guest_middleware.dart
│           └── onboarding_middleware.dart
├── controllers/              # GetX controllers (business logic, observable state)
│   ├── auth_controller.dart
│   ├── compose_controller.dart
│   ├── inbox_controller.dart
│   ├── profile_controller.dart
│   ├── settings_controller.dart
│   └── debug_tools_controller.dart
├── models/                   # Plain Dart data classes
│   ├── contact.dart
│   ├── recipient.dart
│   ├── from_option.dart
│   ├── send_mode.dart
│   └── compose_attachment.dart
├── services/                 # Long-lived GetxServices and platform abstractions
│   ├── nostr_mail_service.dart        # Wraps NostrMailClient; relay/Blossom/DM list management
│   ├── storage_service.dart           # Sembast wrapper + settings store
│   ├── storage_service_io.dart        # IO-specific DB opener
│   ├── storage_service_stub.dart      # Web stub (falls back to sembast_web in storage_service)
│   ├── ndk_cache_service.dart         # Creates SembastCacheManager for NDK
│   ├── theme_service.dart             # Loads/saves custom light/dark ColorSchemes
│   ├── contacts_service.dart          # Aggregates contacts from email history, follows, etc.
│   └── android_file_saver.dart        # Platform-specific file save helper
├── utils/                    # Pure utility functions and extensions
│   ├── blossom_utils.dart
│   ├── relay_utils.dart
│   ├── format_date.dart
│   ├── format_date_time.dart
│   ├── get_attachements.dart
│   ├── get_mime_type.dart
│   ├── html_has_images.dart
│   ├── metadata_extensions.dart
│   ├── nostr_avatar_colors.dart       # NIP-avatar deterministic color derivation
│   ├── nostr_utils.dart
│   ├── platform_helper.dart
│   ├── responsive_helper.dart
│   ├── sender_name_helper.dart
│   ├── toast_helper.dart
│   ├── event_verifiers.dart           # SwitchableVerifier, WebEventVerifier, RustEventVerifier, NoVerifier
│   ├── confirm_open_link.dart
│   └── color_scheme_serializer.dart
├── views/                    # UI screens (one folder per feature)
│   ├── auth/
│   ├── compose/
│   ├── email/
│   ├── inbox/
│   ├── onboarding/
│   ├── profile/
│   ├── settings/
│   └── shared/              # Desktop shell, left rail, layout constants
└── widgets/                  # Reusable widgets shared across views
    ├── email_avatar.dart
    └── nostr_avatar.dart

test/
└── utils/
    ├── blossom_utils_test.dart
    └── relay_utils_test.dart
```

**Total Dart files in `lib/`**: ~106 files (~3,000+ lines across views alone).

---

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode (auto-detects platform)
flutter run

# Run on a specific device
flutter run -d chrome
flutter run -d linux
flutter run -d android

# Build for production
flutter build web
flutter build apk --release
flutter build appbundle --release
flutter build linux --release
flutter build macos --release
```

### Desktop-specific
On Linux desktop builds, `window_manager` is used with a hidden system title bar (`TitleBarStyle.hidden`). A custom drag-to-move area and window caption buttons are injected in `main.dart` via the `builder` callback of `GetMaterialApp`.

---

## Testing

The project currently has a **minimal test suite** (2 utility test files).

```bash
# Run all tests
flutter test
```

Existing tests cover:
- `utils/blossom_utils.dart` — URL formatting/normalization/validation
- `utils/relay_utils.dart` — Relay URL formatting/normalization/validation

When adding new features, **prefer adding unit tests for utility functions and business logic in controllers/services**. There are no integration or widget tests at this time.

---

## Code Style & Linting

- **Linter config**: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`.
- **Special rule**: `experimental_member_use` is set to `ignore`.
- Follow existing naming conventions:
  - Controllers end with `Controller` and extend `GetxController` (or `GetxService` for services).
  - Views end with `View` and are `StatelessWidget` (or `StatefulWidget` if needed).
  - Files are named with `snake_case`.
  - Rx observables are prefixed with `is`, `has`, or named as plural nouns (e.g., `isLoading`, `emails`).

---

## Architecture Conventions

### Dependency Injection (GetX)
- **Permanent singletons** initialized in `main.dart`:
  - `StorageService`
  - `SwitchableVerifier` (event verifier)
  - `Ndk`
  - `NdkFlutter`
  - `NostrMailService`
  - `AuthController`
  - `ThemeService`
- **Permanent singletons** from `InitialBinding`:
  - `SettingsController`
  - `ContactsService` (lazy)
- **Per-route lazy controllers** bound in `AppRoutes`:
  - `InboxController`, `ComposeController`, `ProfileController`

### Navigation / Routing
- Uses **GetX routing** (`GetPage`, `GetMaterialApp`).
- Route constants live in `AppRoutes`.
- Middleware stack order: `OnboardingMiddleware` → `AuthMiddleware`/`GuestMiddleware`.
- **Planned migration**: `TODO.md` mentions evaluating `go_router` for nested desktop/web shell navigation (fixed sidebar, changing body).

### State & Reactivity
- Heavy use of `Rx<T>` / `.obs` for reactive UI.
- Controllers use `onInit`/`onClose` for lifecycle management.
- `WidgetsBindingObserver` is used in `InboxController` to trigger background-to-foreground sync.

---

## Nostr Integration Details

The app is deeply coupled to the `ndk` ecosystem:

- **NDK** (`ndk` + `ndk_flutter`) handles accounts, relays, metadata, gift-wrap parsing, Blossom uploads, and event verification.
- **NostrMailClient** (from `nostr_mail` package) is the high-level email API. It is initialized via `NostrMailService.initClient()` after login.
- **Email events** are Nostr gift-wraps (kind `1059`).
- **Read/unread state** uses NIP-32 labels (`state:read`).
- **DM Relays** are stored as kind `10050` events.
- **NIP-65 relay lists** (kind `10002`) are managed for inbox/outbox.
- **Blossom servers** (kind `10063`) store attachments.
- **Bootstrap relays** and recommended defaults are centralized in `lib/app/config/nostr_config.dart`.

### Event Verification
`main.dart` sets up a `SwitchableVerifier` that can hot-swap between:
- `WebEventVerifier` (web platform)
- `RustEventVerifier` (native platforms)
- `NoVerifier` (when user toggles "skip event verification" in debug settings)

**TODO**: The project intends to remove the "skip event verification" logic entirely.

---

## Security & Privacy Considerations

- **Private keys** are managed by `ndk_flutter` / `flutter_secure_storage`; the app does not handle raw key strings directly except for `nsec` export in `AuthController`.
- **Event verification** is required by default; skipping it is only a debug option.
- **Local database** (`sembast`) stores emails, settings, and NDK cache on-device. No cloud backup.
- **Bridge domains** (e.g., `uid.ovh`) are used to relay messages to legacy SMTP inboxes. The app auto-selects a bridge `From` address when legacy recipients are detected.

---

## Deployment & CI/CD

All CI lives in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `firebase-hosting-merge.yml` | Push to `main` | Builds `flutter build web` and deploys to Firebase Hosting |
| `firebase-hosting-pull-request.yml` | PRs | Preview deploys for web |
| `release.yml` | Tag `v*` or manual | Builds Android (APK + AAB) + Linux (deb + AppImage), creates GitHub Release |
| `build-android.yml` | Manual | Build signed Android artifacts (uses secrets for keystore) |
| `build-linux.yml` | Manual | Build Linux packages via `fastforge` |
| `build-macos.yml` | Manual | Build macOS app |
| `deploy-redirect.yml` | Unknown | Deploys the redirect page (likely `redirect-page/`) |

### Release Tooling
- **Android**: Signed with a PKCS12 keystore (`russel.p12`) configured via repository secrets.
- **Linux**: Uses `fastforge` to generate `.deb` and `.AppImage` packages.
- **Web**: Hosted on Firebase (`nostr-mail` project). SPA rewrite rules send all routes to `index.html`.

### Build Configuration
`build-config.yaml` configures `fastforge` metadata:
- Display name: `Nmail`
- App ID: `app.nostrmail.client`
- Maintainer: Russell (`npub1kg4sdvz3l4fr99n2jdz2vdxe2mpacva87hkdetv76ywacsfq5leqquw5te`)

---

## Assets

- `icons/original_transparent_2x.svg` — App logo (SVG)
- `icons/original_transparent_3x.png` — App logo (PNG fallback)
- macOS icon is generated via `flutter_launcher_icons` from `icons/web/icon-512.png`.

---

## Outstanding TODOs

From `TODO.md` and inline comments:
1. Evaluate migrating from GetX routing to `go_router` for nested desktop/web layouts.
2. Add a broadcast retry queue for reliable event delivery.
3. Remove "skip event verification" debug logic from the codebase.
4. Allow attachment renaming (inline `TODO` in `ComposeController`).
5. Attachment file-size limits are not yet enforced.

---

## Tips for Agents

- **Do not assume this is a standard email app.** The core transport is Nostr gift-wraps, not SMTP/IMAP. If you need to understand how an email is fetched or sent, look at `nostr_mail_service.dart` and `NostrMailClient` (external package), not SMTP libraries.
- **Use `Get.find<T>()` carefully.** Many services are marked `permanent: true` and are expected to exist for the app lifetime. If you introduce a new service, register it in `main.dart` or `InitialBinding`.
- **Respect platform branching.** There are explicit `kIsWeb` and `PlatformHelper.isDesktop` checks throughout the UI (especially `main.dart` and file-saving code). Keep these branches intact.
- **When modifying routes**, update both `AppRoutes` constants and the `GetPage` list. Remember the middleware order matters.
- **Tests are minimal.** If you change utility functions in `utils/`, add or update tests in `test/utils/`. There is no test coverage for controllers/views.
