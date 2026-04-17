import 'package:flutter/material.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/views/email/widgets/sender_bridge_badge_view.dart';

import 'main_sender_avatar_view.dart';

class SenderAvatarView extends StatelessWidget {
  const SenderAvatarView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mainAvatar = MainSenderAvatarView(email: EmailController.to.email!);

    if (!EmailController.to.senderHasBridge) {
      return mainAvatar;
    }

    // Show bridge badge on avatar
    return Stack(
      clipBehavior: Clip.none,
      children: [
        mainAvatar,
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 2),
            ),
            child: SenderBridgeBadgeView(email: EmailController.to.email!),
          ),
        ),
      ],
    );
  }
}
