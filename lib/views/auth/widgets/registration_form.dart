import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';

class RegistrationForm extends GetView<AuthController> {
  const RegistrationForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'What should others see?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.usernameController,
            enabled: !controller.isLoading.value,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (value) {
              if (value.trim().isEmpty) return;
              if (controller.isLoading.value) return;
              controller.register();
            },
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'e.g. Alice',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed:
                controller.username.value.isEmpty || controller.isLoading.value
                ? null
                : controller.register,
            child: const Text('Continue'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: controller.isLoading.value
                ? null
                : () {
                    controller.isRegistering.value = false;
                    controller.usernameController.clear();
                  },
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }
}
