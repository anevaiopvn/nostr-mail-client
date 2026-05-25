/// Path constants for all app routes.
///
/// Folder routes (`/inbox`, `/sent`, `/archive`, `/trash`) drive the
/// inbox view's current folder via the URL itself - the sidebar uses
/// `context.go` to switch folders, and the route builder syncs
/// `InboxController.currentFolder` from the URL.
///
/// `/:nostrId` is a root-level dispatcher for any NIP-19 bech32 entity
/// (nevent, note, npub, nprofile). The view inspects the prefix and
/// renders the appropriate sub-view.
class AppRoutes {
  // Public (no auth required)
  static const login = '/login';
  static const onboarding = '/onboarding';

  // Folders (drive InboxController.currentFolder from URL)
  static const inbox = '/inbox';
  static const sent = '/sent';
  static const archive = '/archive';
  static const trash = '/trash';

  // Actions
  static const compose = '/compose';
  static const profile = '/profile';

  // Settings (nested)
  static const settings = '/settings';
  static const settingsIdentities = '/settings/identities';
  static const settingsIdentitiesNew = '/settings/identities/new';
  static const settingsHosting = '/settings/hosting';
  static const settingsDebugTools = '/settings/debug-tools';

  // Backward compat: legacy in-app links keep working.
  // `/email/:id` redirects to `/:hex` which the nostr dispatcher resolves.
  static const emailLegacy = '/email/:id';

  // Root-level NIP-19 dispatcher (handles nevent, note, npub, nprofile)
  static const nostrIdParam = 'nostrId';
}
