import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/nostr_mail_service.dart';
import '../../../utils/relay_utils.dart';

class SyncStatusSection extends StatefulWidget {
  const SyncStatusSection({super.key});

  @override
  State<SyncStatusSection> createState() => _SyncStatusSectionState();
}

class _SyncStatusSectionState extends State<SyncStatusSection> {
  List<EmailSyncStatus>? _syncStatus;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final nostrMailService = Get.find<NostrMailService>();
    final status = await nostrMailService.getEmailSyncStatus();
    if (mounted) {
      setState(() {
        _syncStatus = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _resync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final nostrMailService = Get.find<NostrMailService>();
      await nostrMailService.client.resync();
      await _loadData();
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  String _formatTimestamp(AppLocalizations l, String locale, int? timestamp) {
    if (timestamp == null) return '-';
    if (timestamp == 0) return l.syncStatusBeginningOfTime;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat.yMd(locale).add_Hm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
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
            l.syncStatusSectionTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (_syncStatus == null || _syncStatus!.isEmpty)
          ListTile(
            leading: const Icon(Icons.sync_disabled),
            title: Text(l.syncStatusEmpty),
            subtitle: Text(l.syncStatusEmptyHint),
          )
        else
          ..._syncStatus!.map(
            (status) => ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(
                formatRelayUrl(status.relayUrl),
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                '${_formatTimestamp(l, locale, status.oldestTimestamp)} → ${_formatTimestamp(l, locale, status.newestTimestamp)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        // TODO: add description explaining when to use Resync
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isSyncing ? null : _resync,
              child: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.syncStatusResync),
            ),
          ),
        ),
      ],
    );
  }
}
