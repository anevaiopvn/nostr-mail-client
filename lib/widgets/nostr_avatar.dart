import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

import '../utils/nostr_avatar_colors.dart';

class NostrAvatar extends StatelessWidget {
  final String pubkey;
  final Metadata? metadata;
  final double radius;

  const NostrAvatar({
    super.key,
    required this.pubkey,
    this.metadata,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = getAvatarColorFromPubkey(pubkey);
    final pictureUrl = metadata?.picture;

    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(pictureUrl),
        backgroundColor: avatarColor.background,
        onBackgroundImageError: (e, s) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor.background,
      child: Text(
        getInitialFromMetadata(pubkey, metadata),
        style: TextStyle(
          color: avatarColor.text,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
