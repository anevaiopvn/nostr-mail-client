import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';
import 'package:nostr_mail/nostr_mail.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/inbox_controller.dart';
import '../../../utils/nostr_utils.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widgets/email_avatar.dart';
import '../../../widgets/nostr_avatar.dart';

class EmailTile extends StatefulWidget {
  final Email email;
  final VoidCallback onTap;
  final bool isSelected;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  const EmailTile({
    super.key,
    required this.email,
    required this.onTap,
    this.isSelected = false,
    this.onToggleSelect,
    this.onReply,
    this.onForward,
    this.onDelete,
    this.onArchive,
    this.onRestore,
  });

  @override
  State<EmailTile> createState() => _EmailTileState();
}

class _EmailTileState extends State<EmailTile> {
  Metadata? _contactMetadata;
  Metadata? _bridgeMetadata;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  /// Check if I am the sender of this email
  bool get _isSentByMe {
    final myPubkey = Get.find<AuthController>().publicKey;
    return widget.email.senderPubkey == myPubkey;
  }

  /// Get the address to display (to for sent emails, from for received)
  String get _displayAddress {
    if (_isSentByMe) {
      return widget.email.mime.to?.firstOrNull?.encode() ?? '';
    } else {
      return widget.email.sender?.encode() ?? '';
    }
  }

  /// Get the contact pubkey (extracted from to/from address)
  String? get _contactPubkey => extractPubkeyFromAddress(_displayAddress);

  /// Get the bridge pubkey (recipientPubkey for sent, senderPubkey for received)
  String get _bridgePubkey =>
      _isSentByMe ? widget.email.recipientPubkey : widget.email.senderPubkey;

  /// Check if this email was relayed through a bridge
  bool get _hasBridge => widget.email.isBridged;

  Future<void> _loadMetadata() async {
    try {
      final ndk = Get.find<Ndk>();
      final contactPubkey = _contactPubkey;
      final hasBridge = contactPubkey == null || contactPubkey != _bridgePubkey;

      // Always load bridge metadata
      final bridgeMeta = await ndk.metadata.loadMetadata(_bridgePubkey);
      if (mounted && bridgeMeta != null) {
        setState(() {
          if (hasBridge) {
            _bridgeMetadata = bridgeMeta;
          } else {
            // No bridge: bridge pubkey IS the contact
            _contactMetadata = bridgeMeta;
          }
        });
      }

      // If there's a bridge and we can extract contact pubkey, load it too
      if (hasBridge && contactPubkey != null) {
        final contactMeta = await ndk.metadata.loadMetadata(contactPubkey);
        if (mounted && contactMeta != null) {
          setState(() => _contactMetadata = contactMeta);
        }
      }
    } catch (_) {}
  }

  String get _displayName {
    if (_contactMetadata?.name != null && _contactMetadata!.name!.isNotEmpty) {
      return _contactMetadata!.name!;
    }
    return _displayAddress;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveHelper.isDesktop(context);
    final currentFolder = Get.find<InboxController>().currentFolder.value;
    final isInTrash = currentFolder == MailFolder.trash;
    final isInArchive = currentFolder == MailFolder.archive;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Dismissible(
          key: ValueKey(widget.email.id),
          direction: isInTrash
              ? DismissDirection.endToStart
              : DismissDirection.horizontal,
          background: Container(
            color: isInArchive ? Colors.blue : Colors.green,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              isInArchive ? Icons.inbox : Icons.archive,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              // Swipe right - archive (or restore from archive)
              if (isInArchive) {
                widget.onRestore?.call();
              } else {
                widget.onArchive?.call();
              }
            } else if (direction == DismissDirection.endToStart) {
              // Swipe left - delete
              widget.onDelete?.call();
            }
          },
          child: GestureDetector(
            onSecondaryTapUp: (details) =>
                _showContextMenu(context, position: details.globalPosition),
            onLongPress: () => _showContextMenu(context),
            child: isWide
                ? _buildCompactTile(context, colorScheme)
                : _buildDefaultTile(context),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _showContextMenu(BuildContext context, {Offset? position}) {
    final currentFolder = Get.find<InboxController>().currentFolder.value;
    final isInTrash = currentFolder == MailFolder.trash;
    final isInArchive = currentFolder == MailFolder.archive;
    final colorScheme = Theme.of(context).colorScheme;

    // Right-click (desktop) → popup menu at cursor position
    // Long-press (mobile) → bottom sheet
    if (position != null) {
      // Desktop: popup menu
      final menuChildren = <Widget>[
        if (!isInTrash) ...[
          MenuItemButton(
            leadingIcon: const Icon(Icons.reply),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onReply?.call();
            },
            child: const Text('Reply'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.forward),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onForward?.call();
            },
            child: const Text('Forward'),
          ),
          const Divider(height: 1),
          if (!isInArchive)
            MenuItemButton(
              leadingIcon: const Icon(Icons.archive),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onArchive?.call();
              },
              child: const Text('Archive'),
            )
          else
            MenuItemButton(
              leadingIcon: const Icon(Icons.unarchive),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onRestore?.call();
              },
              child: const Text('Unarchive'),
            ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            child: const Text('Move to trash'),
          ),
        ] else ...[
          MenuItemButton(
            leadingIcon: const Icon(Icons.restore_from_trash),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRestore?.call();
            },
            child: const Text('Restore'),
          ),
          MenuItemButton(
            leadingIcon: Icon(Icons.delete_forever, color: colorScheme.error),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            child: Text(
              'Delete permanently',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ];

      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: () => Navigator.of(context).pop()),
            ),
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                surfaceTintColor: colorScheme.surfaceTint,
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: menuChildren,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile: bottom sheet
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              if (!isInTrash) ...[
                ListTile(
                  leading: const Icon(Icons.reply),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onReply?.call();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.forward),
                  title: const Text('Forward'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onForward?.call();
                  },
                ),
                const Divider(height: 1),
                if (!isInArchive)
                  ListTile(
                    leading: const Icon(Icons.archive),
                    title: const Text('Archive'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onArchive?.call();
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.unarchive),
                    title: const Text('Unarchive'),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onRestore?.call();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Move to trash'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete?.call();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.restore_from_trash),
                  title: const Text('Restore'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onRestore?.call();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: colorScheme.error),
                  title: Text(
                    'Delete permanently',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCompactTile(BuildContext context, ColorScheme colorScheme) {
    final subject = (widget.email.subject?.isEmpty ?? true)
        ? '(No subject)'
        : widget.email.subject!;

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        color: widget.isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: widget.isSelected,
                onChanged: widget.onToggleSelect != null
                    ? (_) => widget.onToggleSelect!()
                    : null,
              ),
            ),
            SizedBox(
              width: 160,
              child: Row(
                children: [
                  _buildAvatar(context, compact: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('—', style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 3,
                    child: Text(
                      widget.email.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _formatDate(widget.email.date),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultTile(BuildContext context) {
    return ListTile(
      onTap: widget.onTap,
      leading: _buildAvatar(context),
      title: Text(
        (widget.email.subject?.isEmpty ?? true)
            ? '(No subject)'
            : widget.email.subject!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            widget.email.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
      trailing: Text(
        _formatDate(widget.email.date),
        style: TextStyle(color: Colors.grey[500], fontSize: 11),
      ),
      isThreeLine: true,
    );
  }

  Widget _buildAvatar(BuildContext context, {bool compact = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = compact ? 14.0 : 20.0;
    final mainAvatar = _buildMainAvatar(colorScheme, radius: radius);

    if (!_hasBridge) {
      return mainAvatar;
    }

    // Show bridge badge on avatar
    final badgeRadius = compact ? 7.0 : 10.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        mainAvatar,
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 2),
            ),
            child: _buildBridgeBadge(colorScheme, radius: badgeRadius),
          ),
        ),
      ],
    );
  }

  Widget _buildBridgeBadge(ColorScheme colorScheme, {double radius = 10}) {
    return NostrAvatar(
      pubkey: _bridgePubkey,
      metadata: _bridgeMetadata,
      radius: radius,
    );
  }

  Widget _buildMainAvatar(ColorScheme colorScheme, {double radius = 20}) {
    final contactPubkey = _contactPubkey;
    if (contactPubkey == null) {
      return EmailAvatar(email: _displayAddress, radius: radius);
    }

    return NostrAvatar(
      pubkey: contactPubkey,
      metadata: _contactMetadata,
      radius: radius,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
