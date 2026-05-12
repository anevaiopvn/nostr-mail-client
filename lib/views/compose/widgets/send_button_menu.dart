import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nostr_mail_client/controllers/compose_controller.dart';
import 'package:nostr_mail_client/models/send_mode.dart';

class SendButtonMenu extends StatelessWidget {
  const SendButtonMenu({super.key, this.isMobile = false});

  final bool isMobile;

  IconData _getModeIcon(SendMode mode) {
    switch (mode) {
      case SendMode.normal:
        return Icons.lock;
      case SendMode.signed:
        return Icons.draw;
      case SendMode.public:
        return Icons.public;
    }
  }

  String _getModeLabel(SendMode mode) {
    switch (mode) {
      case SendMode.normal:
        return 'Private deniable';
      case SendMode.signed:
        return 'Private signed';
      case SendMode.public:
        return 'Public';
    }
  }

  String _getModeDescription(SendMode mode) {
    switch (mode) {
      case SendMode.normal:
        return 'Send as encrypted email. No signature - deniable if needed.';
      case SendMode.signed:
        return 'Send as encrypted email. Signed - proves you\'re the author.';
      case SendMode.public:
        return 'Send as a public event. Anyone can read this. No encryption.';
    }
  }

  Future<void> _showModeMenu(BuildContext context, SendMode currentMode) async {
    final selected = await showModalBottomSheet<SendMode>(
      showDragHandle: true,
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose send mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildModeOption(SendMode.normal),
              _buildModeOption(SendMode.signed),
              _buildModeOption(SendMode.public),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      Get.find<ComposeController>().sendMode.value = selected;
      await Get.find<ComposeController>().firstSend();
    }
  }

  Widget _buildModeOption(SendMode mode) {
    return ListTile(
      leading: Icon(_getModeIcon(mode)),
      title: Text(_getModeLabel(mode)),
      subtitle: Text(_getModeDescription(mode)),
      onTap: () => Get.back(result: mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ComposeController>();

    return Obx(() {
      final isSending = controller.isSending.value;

      Widget button;

      // On mobile, use a custom button with long-press support
      if (isMobile) {
        button = FilledButton(
          onPressed: isSending ? null : () => controller.firstSend(),
          onLongPress: isSending
              ? null
              : () => _showModeMenu(context, SendMode.normal),
          child: isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Send'),
        );
      } else {
        // Desktop: use FilledButton with dropdown
        button = FilledButton(
          onPressed: isSending ? null : () => controller.firstSend(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Visibility(
                visible: !isSending,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Send')],
                ),
              ),
              Visibility(
                visible: isSending,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ),
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          if (!isMobile) ...[
            const SizedBox(width: 4),
            MenuAnchor(
              alignmentOffset: const Offset(-8, 0),
              style: MenuStyle(
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      width: 2,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              builder: (context, menuController, child) {
                return IconButton(
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  tooltip: 'More send options',
                  onPressed: () {
                    if (menuController.isOpen) {
                      menuController.close();
                    } else {
                      menuController.open();
                    }
                  },
                );
              },
              menuChildren: [
                MenuItemButton(
                  leadingIcon: Icon(_getModeIcon(SendMode.normal)),
                  onPressed: () async {
                    controller.sendMode.value = SendMode.normal;
                    await controller.firstSend();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getModeLabel(SendMode.normal)),
                      Text(
                        _getModeDescription(SendMode.normal),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                MenuItemButton(
                  leadingIcon: Icon(_getModeIcon(SendMode.signed)),
                  onPressed: () async {
                    controller.sendMode.value = SendMode.signed;
                    await controller.firstSend();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getModeLabel(SendMode.signed)),
                      Text(
                        _getModeDescription(SendMode.signed),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                MenuItemButton(
                  leadingIcon: Icon(_getModeIcon(SendMode.public)),
                  onPressed: () async {
                    controller.sendMode.value = SendMode.public;
                    await controller.firstSend();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getModeLabel(SendMode.public)),
                      Text(
                        _getModeDescription(SendMode.public),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}
