import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../controllers/inbox_controller.dart';
import '../../../l10n/generated/app_localizations.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = Get.isRegistered<InboxController>()
        ? Get.find<InboxController>()
        : Get.put(InboxController());

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.compose),
                icon: const Icon(Icons.edit),
                label: Text(l.inboxCompose),
              ),
            ),
          ),
          Obx(
            () => _NavItem(
              icon: Icons.inbox_outlined,
              selectedIcon: Icons.inbox,
              label: l.folderInbox,
              selected: controller.currentFolder.value == MailFolder.inbox,
              onTap: () {
                controller.setFolder(MailFolder.inbox);
                if (Get.currentRoute == AppRoutes.inbox) return;
                Get.until((route) => route.settings.name == AppRoutes.inbox);
              },
            ),
          ),
          Obx(
            () => _NavItem(
              icon: Icons.send_outlined,
              selectedIcon: Icons.send,
              label: l.folderSent,
              selected: controller.currentFolder.value == MailFolder.sent,
              onTap: () {
                controller.setFolder(MailFolder.sent);
                if (Get.currentRoute == AppRoutes.inbox) return;
                Get.until((route) => route.settings.name == AppRoutes.inbox);
              },
            ),
          ),
          Obx(
            () => _NavItem(
              icon: Icons.archive_outlined,
              selectedIcon: Icons.archive,
              label: l.folderArchive,
              selected: controller.currentFolder.value == MailFolder.archive,
              onTap: () {
                controller.setFolder(MailFolder.archive);
                if (Get.currentRoute == AppRoutes.inbox) return;
                Get.until((route) => route.settings.name == AppRoutes.inbox);
              },
            ),
          ),
          Obx(
            () => _NavItem(
              icon: Icons.delete_outlined,
              selectedIcon: Icons.delete,
              label: l.folderTrash,
              selected: controller.currentFolder.value == MailFolder.trash,
              onTap: () {
                controller.setFolder(MailFolder.trash);
                if (Get.currentRoute == AppRoutes.inbox) return;
                Get.until((route) => route.settings.name == AppRoutes.inbox);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          selected ? selectedIcon : icon,
          color: selected ? colorScheme.onSecondaryContainer : null,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? colorScheme.onSecondaryContainer : null,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
        selected: selected,
        selectedTileColor: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        onTap: onTap,
      ),
    );
  }
}
