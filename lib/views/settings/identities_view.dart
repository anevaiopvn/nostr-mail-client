import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/identities_controller.dart';
import '../../utils/responsive_helper.dart';
import '../shared/desktop_shell.dart';
import 'widgets/identities_empty_state.dart';
import 'widgets/identities_list.dart';

class IdentitiesView extends StatelessWidget {
  const IdentitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IdentitiesController>();
    final isWide = ResponsiveHelper.isNotMobile(context);

    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Identities'),
        actionsPadding: .only(right: 8),
        actions: [
          Obx(() {
            final canSave = controller.hasChanges && !controller.isSaving.value;
            return FilledButton(
              onPressed: canSave ? controller.saveChanges : null,
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Get.toNamed(AppRoutes.createIdentity);
          await controller.loadData();
        },
        tooltip: 'Create identity',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return ResponsiveCenter(
            maxWidth: 600,
            child: controller.identities.isEmpty
                ? const IdentitiesEmptyState()
                : const IdentitiesList(),
          );
        }),
      ),
    );

    final content = Obx(
      () => PopScope(
        canPop: !controller.hasChanges,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldDiscard = await _confirmDiscard();
          if (shouldDiscard == true) {
            Get.back();
          }
        },
        child: scaffold,
      ),
    );

    if (isWide) {
      return DesktopShell(body: content);
    }
    return content;
  }

  Future<bool?> _confirmDiscard() {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Leaving now will discard them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
