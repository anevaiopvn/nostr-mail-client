import 'package:broadcast_queue_shim_for_ndk/broadcast_queue_shim_for_ndk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ndk/ndk.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/nostr_mail_service.dart';
import '../../../utils/blossom_utils.dart';
import '../../../app/config/nostr_config.dart';
import 'recommendation_chips.dart';

class BlossomServersSection extends StatefulWidget {
  const BlossomServersSection({super.key});

  @override
  State<BlossomServersSection> createState() => _BlossomServersSectionState();
}

class _BlossomServersSectionState extends State<BlossomServersSection> {
  List<String>? _originalServers;
  List<String>? _servers;
  final Set<String> _markedForDeletion = {};
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _hasChanges {
    if (_originalServers == null || _servers == null) return false;
    if (_markedForDeletion.isNotEmpty) return true;
    if (_originalServers!.length != _servers!.length) return true;
    for (int i = 0; i < _originalServers!.length; i++) {
      if (!_servers!.contains(_originalServers![i])) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final nostrMailService = Get.find<NostrMailService>();
    final servers = await nostrMailService.getBlossomServers();
    if (mounted) {
      setState(() {
        _originalServers = List.from(servers);
        _servers = List.from(servers);
        _isLoading = false;
      });
    }
  }

  Future<void> _addServer() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? errorText;
    String? preview;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.blossomAddTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l.blossomServerUrlHint,
                  labelText: l.blossomServerUrlLabel,
                  errorText: errorText,
                ),
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(
                    RegExp(r'\s'),
                    replacementString: '',
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    errorText = null;
                    final normalized = normalizeBlossomUrl(value.trim());
                    preview = (normalized != value.trim()) ? normalized : null;
                  });
                },
                onSubmitted: (value) {
                  final url = normalizeBlossomUrl(value.trim());
                  if (!isValidBlossomUrl(url)) {
                    setDialogState(() => errorText = l.blossomInvalidUrl);
                    return;
                  }
                  Navigator.pop(context, url);
                },
              ),
              if (preview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l.hostingWillBeAddedAs(preview!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.actionCancel),
            ),
            TextButton(
              onPressed: () {
                final url = normalizeBlossomUrl(controller.text.trim());
                if (!isValidBlossomUrl(url)) {
                  setDialogState(() => errorText = l.blossomInvalidUrl);
                  return;
                }
                Navigator.pop(context, url);
              },
              child: Text(l.actionAdd),
            ),
          ],
        ),
      ),
    );

    if (result != null && _servers != null && !_servers!.contains(result)) {
      setState(() => _servers!.add(result));
    }
  }

  void _toggleServerDeletion(String serverUrl) {
    setState(() {
      if (_markedForDeletion.contains(serverUrl)) {
        _markedForDeletion.remove(serverUrl);
      } else {
        _markedForDeletion.add(serverUrl);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final serversToSave = _servers!
          .where((s) => !_markedForDeletion.contains(s))
          .toList();

      final ndk = Get.find<Ndk>();
      final account = ndk.accounts.getLoggedAccount()!;
      final unsigned = Nip01Event(
        pubKey: account.pubkey,
        kind: blossomServerListKind,
        tags: [
          for (final s in serversToSave) ['server', s],
        ],
        content: '',
      );
      final signed = await account.signer.sign(unsigned);
      await ndk.config.cache.saveEvent(signed);
      // Signaling event: broadcast widely (popular + outbox).
      final outbox = await Get.find<NostrMailService>().getOutboxRelays();
      await Get.find<OfflineBroadcast>().broadcast(
        signed,
        relays: {...NostrConfig.popularRelays, ...outbox}.toList(),
      );

      setState(() {
        _servers = serversToSave;
        _originalServers = List.from(serversToSave);
        _markedForDeletion.clear();
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_isLoading) {
      return ListTile(
        leading: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(l.stateLoadingEllipsis),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          title: Text(
            l.blossomSectionTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: _addServer,
            tooltip: l.blossomAddTooltip,
          ),
        ),
        RecommendationChips(
          recommendations: NostrConfig.recommendedBlossomServers,
          isAlreadyAdded: (r) => _servers != null && _servers!.contains(r),
          onAdd: (server) => setState(() => _servers!.add(server)),
          formatLabel: formatBlossomUrl,
        ),
        if (_servers == null || _servers!.isEmpty)
          ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: Text(l.blossomEmpty),
            subtitle: Text(l.blossomEmptyHint),
          )
        else
          ..._servers!.map((server) {
            final isMarked = _markedForDeletion.contains(server);
            return ListTile(
              leading: Icon(
                Icons.cloud_outlined,
                color: isMarked ? Theme.of(context).disabledColor : null,
              ),
              title: Text(
                formatBlossomUrl(server),
                style: TextStyle(
                  fontSize: 14,
                  decoration: isMarked ? TextDecoration.lineThrough : null,
                  color: isMarked ? Theme.of(context).disabledColor : null,
                ),
              ),
              trailing: IconButton(
                icon: Icon(isMarked ? Icons.undo : Icons.close, size: 18),
                onPressed: () => _toggleServerDeletion(server),
                tooltip: isMarked ? l.actionUndo : l.blossomRemoveTooltip,
              ),
            );
          }),
        if (_hasChanges)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.actionSave),
              ),
            ),
          ),
      ],
    );
  }
}
