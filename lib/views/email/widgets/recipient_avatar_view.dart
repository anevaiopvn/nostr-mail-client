import 'package:flutter/material.dart';
import 'package:nostr_mail_client/views/email/email_controller.dart';
import 'package:nostr_mail_client/views/email/widgets/main_recipient_avatar_view.dart';

import 'recipient_bridge_badge_view.dart';

class RecipientAvatarView extends StatelessWidget {
  const RecipientAvatarView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mainAvatar = MainRecipientAvatarView();

    if (!EmailController.to.recipientHasBridge) {
      return mainAvatar;
    }

    // Show bridge badge on avatar
    return Stack(
      clipBehavior: Clip.none,
      children: [
        mainAvatar,
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 1.5),
            ),
            child: RecipientBridgeBadgeView(),
          ),
        ),
      ],
    );
  }
}
