import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

import '../utils/nostr_avatar_colors.dart';

class NostrAvatar extends StatelessWidget {
  final String pubkey;
  final Metadata? metadata;
  final double radius;
  final VoidCallback? onTap;

  const NostrAvatar({
    super.key,
    required this.pubkey,
    this.metadata,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = getAvatarColorFromPubkey(pubkey);
    final pictureUrl = metadata?.picture;

    Widget avatar;
    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(pictureUrl),
        backgroundColor: avatarColor.background,
        onBackgroundImageError: (e, s) {},
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: avatarColor.background,
        child: Text(
          getInitialFromMetadata(pubkey, metadata?.displayName, metadata?.name),
          style: TextStyle(
            color: avatarColor.text,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.8,
          ),
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
