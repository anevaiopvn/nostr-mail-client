import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/debug_tools_controller.dart';
import '../../utils/responsive_helper.dart';
import '../shared/desktop_shell.dart';

class DebugToolsView extends StatelessWidget {
  const DebugToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DebugToolsController());
    final isWide = ResponsiveHelper.isNotMobile(context);

    Widget content = Scaffold(
      appBar: AppBar(title: const Text('Debug Tools')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 600,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Email Testing',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.createOldTrashedEmail(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Create Old Trashed Email'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Creates a test email in trash that is 31 days old. '
                    'Use this to test the "Delete old emails" feature.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isWide) {
      return DesktopShell(body: content);
    }
    return content;
  }
}
