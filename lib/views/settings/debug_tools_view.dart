import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';
import '../shared/desktop_shell.dart';

class DebugToolsView extends StatelessWidget {
  const DebugToolsView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debug button pressed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Test Button'),
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
