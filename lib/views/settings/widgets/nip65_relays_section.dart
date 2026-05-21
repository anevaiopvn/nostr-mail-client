import 'package:broadcast_queue_shim_for_ndk/broadcast_queue_shim_for_ndk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/nostr_mail_service.dart';
import '../../../utils/relay_utils.dart';
import '../../../app/config/nostr_config.dart';
import 'recommendation_chips.dart';

class Nip65RelaysSection extends StatefulWidget {
  const Nip65RelaysSection({super.key});

  @override
  State<Nip65RelaysSection> createState() => _Nip65RelaysSectionState();
}

class _Nip65RelaysSectionState extends State<Nip65RelaysSection> {
  Map<String, ReadWriteMarker>? _originalRelays;
  Map<String, ReadWriteMarker>? _relays;
  final Set<String> _markedForDeletion = {};
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _hasChanges {
    if (_originalRelays == null || _relays == null) return false;
    if (_markedForDeletion.isNotEmpty) return true;
    if (_originalRelays!.length != _relays!.length) return true;
    for (final entry in _originalRelays!.entries) {
      if (!_relays!.containsKey(entry.key)) return true;
      if (_relays![entry.key] != entry.value) return true;
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
    final relays = await nostrMailService.getNip65Relays();
    if (mounted) {
      setState(() {
        _originalRelays = Map.from(relays);
        _relays = Map.from(relays);
        _isLoading = false;
      });
    }
  }

  Future<void> _addRelay() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? errorText;
    String? preview;
    ReadWriteMarker marker = ReadWriteMarker.readWrite;

    final result = await showDialog<MapEntry<String, ReadWriteMarker>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.relayAddTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l.relayUrlHint,
                  labelText: l.relayUrlLabel,
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
                    final normalized = normalizeRelayUrl(value.trim());
                    preview = (normalized != value.trim()) ? normalized : null;
                  });
                },
                onSubmitted: (value) {
                  final url = normalizeRelayUrl(value.trim());
                  if (!isValidRelayUrl(url)) {
                    setDialogState(() => errorText = l.relayInvalidUrl);
                    return;
                  }
                  Navigator.pop(context, MapEntry(url, marker));
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
              const SizedBox(height: 16),
              Text(
                l.relayDirection,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ReadWriteMarker>(
                segments: [
                  ButtonSegment(
                    value: ReadWriteMarker.readWrite,
                    label: Text(l.relayReadWrite),
                  ),
                  ButtonSegment(
                    value: ReadWriteMarker.readOnly,
                    label: Text(l.relayRead),
                  ),
                  ButtonSegment(
                    value: ReadWriteMarker.writeOnly,
                    label: Text(l.relayWrite),
                  ),
                ],
                selected: {marker},
                onSelectionChanged: (selected) {
                  setDialogState(() => marker = selected.first);
                },
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
                final url = normalizeRelayUrl(controller.text.trim());
                if (!isValidRelayUrl(url)) {
                  setDialogState(() => errorText = l.relayInvalidUrl);
                  return;
                }
                Navigator.pop(context, MapEntry(url, marker));
              },
              child: Text(l.actionAdd),
            ),
          ],
        ),
      ),
    );

    if (result != null &&
        _relays != null &&
        !_relays!.containsKey(result.key)) {
      setState(() => _relays![result.key] = result.value);
    }
  }

  void _toggleRelayDeletion(String relayUrl) {
    setState(() {
      if (_markedForDeletion.contains(relayUrl)) {
        _markedForDeletion.remove(relayUrl);
      } else {
        _markedForDeletion.add(relayUrl);
      }
    });
  }

  void _cycleMarker(String relayUrl) {
    if (_relays == null || !_relays!.containsKey(relayUrl)) return;
    setState(() {
      final current = _relays![relayUrl]!;
      _relays![relayUrl] = switch (current) {
        ReadWriteMarker.readWrite => ReadWriteMarker.readOnly,
        ReadWriteMarker.readOnly => ReadWriteMarker.writeOnly,
        ReadWriteMarker.writeOnly => ReadWriteMarker.readWrite,
      };
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final relaysToSave = Map<String, ReadWriteMarker>.from(_relays!)
        ..removeWhere((key, _) => _markedForDeletion.contains(key));

      final ndk = Get.find<Ndk>();
      final account = ndk.accounts.getLoggedAccount()!;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final userRelayList = UserRelayList(
        pubKey: account.pubkey,
        relays: relaysToSave,
        createdAt: now,
        refreshedTimestamp: now,
      );
      final signed = await account.signer.sign(
        userRelayList.toNip65().toEvent(),
      );
      await ndk.config.cache.saveUserRelayList(userRelayList);
      // Signaling event: broadcast widely (popular + outbox derived from
      // the new list itself).
      await Get.find<OfflineBroadcast>().broadcast(
        signed,
        relays: {
          ...NostrConfig.popularRelays,
          ...userRelayList.writeUrls,
        }.toList(),
      );

      setState(() {
        _relays = relaysToSave;
        _originalRelays = Map.from(relaysToSave);
        _markedForDeletion.clear();
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _markerLabel(AppLocalizations l, ReadWriteMarker marker) {
    return switch (marker) {
      ReadWriteMarker.readWrite => l.relayMarkerReadWrite,
      ReadWriteMarker.readOnly => l.relayMarkerRead,
      ReadWriteMarker.writeOnly => l.relayMarkerWrite,
    };
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
            l.relayInboxOutboxTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: _addRelay,
            tooltip: l.relayAddTooltip,
          ),
        ),
        RecommendationChips(
          recommendations: NostrConfig.recommendedInboxOutboxRelays,
          isAlreadyAdded: (r) => _relays != null && _relays!.containsKey(r),
          onAdd: (relay) =>
              setState(() => _relays![relay] = ReadWriteMarker.readWrite),
          formatLabel: formatRelayUrl,
        ),
        if (_relays == null || _relays!.isEmpty)
          ListTile(
            leading: const Icon(Icons.warning_rounded),
            title: Text(l.relayInboxOutboxEmpty),
            subtitle: Text(l.relayEmptyHint),
          )
        else
          ..._relays!.entries.map((entry) {
            final relay = entry.key;
            final marker = entry.value;
            final isMarked = _markedForDeletion.contains(relay);
            return ListTile(
              leading: Icon(
                Icons.dns_outlined,
                color: isMarked ? Theme.of(context).disabledColor : null,
              ),
              title: Text(
                formatRelayUrl(relay),
                style: TextStyle(
                  fontSize: 14,
                  decoration: isMarked ? TextDecoration.lineThrough : null,
                  color: isMarked ? Theme.of(context).disabledColor : null,
                ),
              ),
              subtitle: GestureDetector(
                onTap: isMarked ? null : () => _cycleMarker(relay),
                child: Text(
                  _markerLabel(l, marker),
                  style: TextStyle(
                    fontSize: 12,
                    color: isMarked
                        ? Theme.of(context).disabledColor
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: Icon(isMarked ? Icons.undo : Icons.close, size: 18),
                onPressed: () => _toggleRelayDeletion(relay),
                tooltip: isMarked ? l.actionUndo : l.relayRemoveTooltip,
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
