import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

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

  Color _getAvatarColor(BuildContext context) {
    if (pubkey.isEmpty) {
      return Theme.of(context).colorScheme.primaryContainer;
    }

    //!! WARNING: pubkey.hashCode can be negative, potentially creating invalid colors
    // Consider using pubkey.hashCode.abs() or a proper hash function
    final hash = pubkey.hashCode;
    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    ).withValues(alpha: 1);
  }

  String _getInitial() {
    if (metadata?.name != null && metadata!.name!.isNotEmpty) {
      return metadata!.name![0].toUpperCase();
    }
    if (metadata?.displayName != null && metadata!.displayName!.isNotEmpty) {
      return metadata!.displayName![0].toUpperCase();
    }
    if (pubkey.length >= 2) {
      return pubkey.substring(0, 2).toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(context);
    final pictureUrl = metadata?.picture;

    Widget avatar;
    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(pictureUrl),
        backgroundColor: avatarColor,
        onBackgroundImageError: (e, s) {},
      );
    } else {
      final isDark =
          ThemeData.estimateBrightnessForColor(avatarColor) == Brightness.dark;
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: avatarColor,
        child: Text(
          _getInitial(),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
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
