import 'package:flutter/material.dart';

import '../../../controllers/create_identity_controller.dart';

class DisplayNameField extends StatelessWidget {
  final CreateIdentityController controller;

  const DisplayNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.nameController,
      decoration: const InputDecoration(labelText: 'Display Name'),
      textCapitalization: TextCapitalization.words,
    );
  }
}
