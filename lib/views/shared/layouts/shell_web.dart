import 'package:flutter/material.dart';
import 'package:nostr_mail_client/views/shared/layouts/wide_layout.dart';

import '../layout_constants.dart';

class ShellWeb extends StatelessWidget {
  final Widget body;

  const ShellWeb({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: LayoutConstants.shellPadding,
        right: LayoutConstants.shellPadding,
        bottom: LayoutConstants.shellPadding,
      ),
      child: WideLayout(body: body),
    );
  }
}
