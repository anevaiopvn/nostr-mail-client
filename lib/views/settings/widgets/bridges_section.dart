import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/config/nostr_config.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/nostr_mail_service.dart';
import 'recommendation_chips.dart';

// TODO: Convert to StatelessWidget with GetX (Obx) — consistent with app patterns.
// All other sections (nip65, dm, blossom, relay_connectivity, sync_status) are
// also StatefulWidget and should be migrated together.
class BridgesSection extends StatefulWidget {
  const BridgesSection({super.key});

  @override
  State<BridgesSection> createState() => _BridgesSectionState();
}

class _BridgesSectionState extends State<BridgesSection> {
  List<String>? _originalBridges;
  List<String>? _bridges;
  final Set<String> _markedForDeletion = {};
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _hasChanges {
    if (_originalBridges == null || _bridges == null) return false;
    if (_markedForDeletion.isNotEmpty) return true;
    if (_originalBridges!.length != _bridges!.length) return true;
    for (int i = 0; i < _originalBridges!.length; i++) {
      if (!_bridges!.contains(_originalBridges![i])) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final nostrMailService = Get.find<NostrMailService>();
      final settings = await nostrMailService.client.getPrivateSettings();
      final bridges = settings?.bridges ?? [];
      if (mounted) {
        setState(() {
          _originalBridges = List.from(bridges);
          _bridges = List.from(bridges);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _originalBridges = [];
          _bridges = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addBridge() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l.bridgeAddTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l.bridgeDomainHint,
              labelText: l.bridgeDomainLabel,
              errorText: errorText,
            ),
            autofocus: true,
            keyboardType: TextInputType.url,
            inputFormatters: [
              FilteringTextInputFormatter.deny(
                RegExp(r'\s'),
                replacementString: '',
              ),
            ],
            onChanged: (value) {
              setDialogState(() => errorText = null);
            },
            onSubmitted: (value) {
              final domain = value.trim().toLowerCase();
              if (domain.isEmpty || !domain.contains('.')) {
                setDialogState(() => errorText = l.bridgeInvalidDomain);
                return;
              }
              Navigator.pop(context, domain);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.actionCancel),
            ),
            TextButton(
              onPressed: () {
                final domain = controller.text.trim().toLowerCase();
                if (domain.isEmpty || !domain.contains('.')) {
                  setDialogState(() => errorText = l.bridgeInvalidDomain);
                  return;
                }
                Navigator.pop(context, domain);
              },
              child: Text(l.actionAdd),
            ),
          ],
        ),
      ),
    );

    if (result != null && _bridges != null && !_bridges!.contains(result)) {
      setState(() => _bridges!.add(result));
    }
  }

  void _toggleBridgeDeletion(String bridge) {
    setState(() {
      if (_markedForDeletion.contains(bridge)) {
        _markedForDeletion.remove(bridge);
      } else {
        _markedForDeletion.add(bridge);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final nostrMailService = Get.find<NostrMailService>();
      final bridgesToSave = _bridges!
          .where((b) => !_markedForDeletion.contains(b))
          .toList();
      await nostrMailService.client.updatePrivateSettings(
        bridges: bridgesToSave,
      );
      setState(() {
        _bridges = bridgesToSave;
        _originalBridges = List.from(bridgesToSave);
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
            l.bridgeSectionTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: _addBridge,
            tooltip: l.bridgeAddTooltip,
          ),
        ),
        RecommendationChips(
          recommendations: NostrConfig.recommendedBridges,
          isAlreadyAdded: (r) => _bridges != null && _bridges!.contains(r),
          onAdd: (bridge) => setState(() => _bridges!.add(bridge)),
          formatLabel: (bridge) => bridge,
        ),
        if (_bridges == null || _bridges!.isEmpty)
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(l.bridgeEmpty),
            subtitle: Text(l.bridgeEmptyHint),
          )
        else
          ..._bridges!.map((bridge) {
            final isMarked = _markedForDeletion.contains(bridge);
            final isDefault = bridge == 'uid.ovh';
            return ListTile(
              leading: Icon(
                Icons.alternate_email,
                color: isMarked ? Theme.of(context).disabledColor : null,
              ),
              title: Text(
                bridge,
                style: TextStyle(
                  fontSize: 14,
                  decoration: isMarked ? TextDecoration.lineThrough : null,
                  color: isMarked ? Theme.of(context).disabledColor : null,
                ),
              ),
              subtitle: isDefault
                  ? Text(
                      l.bridgeDefault,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null,
              trailing: IconButton(
                icon: Icon(isMarked ? Icons.undo : Icons.close, size: 18),
                onPressed: () => _toggleBridgeDeletion(bridge),
                tooltip: isMarked ? l.actionUndo : l.actionRemove,
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
