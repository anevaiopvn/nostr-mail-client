import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../utils/toast_helper.dart';

class SyncCodeExplanationView extends StatelessWidget {
  final RxBool _hasCopied = false.obs;

  SyncCodeExplanationView({super.key});

  void _copySyncCode(BuildContext context) {
    final authController = Get.find<AuthController>();
    final nsec = authController.getNsec();

    if (nsec == null) {
      if (context.mounted) {
        ToastHelper.error(context, 'Unable to retrieve sync code');
      }
      return;
    }

    Clipboard.setData(ClipboardData(text: nsec));
    _hasCopied.value = true;

    Future.delayed(const Duration(seconds: 2), () {
      _hasCopied.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),

        Text(
          'Your Sync Code',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        Text(
          'This code is the key to your account. It gives you full control and lets you:',
          style: textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        _buildFeatureItem(
          context,
          Icons.restore_page,
          'Restore your account on any device',
        ),
        _buildFeatureItem(
          context,
          Icons.backup_rounded,
          'Back up your identity securely',
        ),
        _buildFeatureItem(
          context,
          Icons.login_rounded,
          'Log in to other Nostr apps',
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.errorContainer, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Never share this code with anyone. Store it in a safe place. You can always find it later in Settings.',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        Obx(
          () => FilledButton.icon(
            onPressed: () => _copySyncCode(context),
            icon: Icon(_hasCopied.value ? Icons.check : Icons.copy_all_rounded),
            label: Text(
              _hasCopied.value ? 'Copied!' : 'Copy Sync Code',
              style: const TextStyle(fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 16),

        OutlinedButton(
          onPressed: () {
            final authController = Get.find<AuthController>();
            authController.continueToInbox();
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Continue to Inbox',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
