import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/nostr_mail_service.dart';
import '../../../utils/relay_utils.dart';
import '../../../app/config/nostr_config.dart';
import 'recommendation_chips.dart';

class DmRelaysSection extends StatefulWidget {
  const DmRelaysSection({super.key});

  @override
  State<DmRelaysSection> createState() => _DmRelaysSectionState();
}

class _DmRelaysSectionState extends State<DmRelaysSection> {
  List<String>? _originalDmRelays;
  List<String>? _dmRelays;
  final Set<String> _markedForDeletion = {};
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _hasChanges {
    if (_originalDmRelays == null || _dmRelays == null) return false;
    if (_markedForDeletion.isNotEmpty) return true;
    if (_originalDmRelays!.length != _dmRelays!.length) return true;
    for (int i = 0; i < _originalDmRelays!.length; i++) {
      if (!_dmRelays!.contains(_originalDmRelays![i])) return true;
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
    final dmRelays = await nostrMailService.getDmRelays();
    if (mounted) {
      setState(() {
        _originalDmRelays = List.from(dmRelays);
        _dmRelays = List.from(dmRelays);
        _isLoading = false;
      });
    }
  }

  Future<void> _addRelay() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? errorText;
    String? preview;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.dmRelayAddTitle),
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
                final url = normalizeRelayUrl(controller.text.trim());
                if (!isValidRelayUrl(url)) {
                  setDialogState(() => errorText = l.relayInvalidUrl);
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

    if (result != null && _dmRelays != null && !_dmRelays!.contains(result)) {
      setState(() => _dmRelays!.add(result));
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

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final nostrMailService = Get.find<NostrMailService>();
      final relaysToSave = _dmRelays!
          .where((r) => !_markedForDeletion.contains(r))
          .toList();
      await nostrMailService.saveDmRelays(relaysToSave);
      setState(() {
        _dmRelays = relaysToSave;
        _originalDmRelays = List.from(relaysToSave);
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
            l.dmRelaySectionTitle,
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
          recommendations: NostrConfig.recommendedDmRelays,
          isAlreadyAdded: (r) => _dmRelays != null && _dmRelays!.contains(r),
          onAdd: (relay) => setState(() => _dmRelays!.add(relay)),
          formatLabel: formatRelayUrl,
        ),
        if (_dmRelays == null || _dmRelays!.isEmpty)
          ListTile(
            leading: const Icon(Icons.warning_rounded),
            title: Text(l.dmRelayEmpty),
            subtitle: Text(l.relayEmptyHint),
          )
        else
          ..._dmRelays!.map((relay) {
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
