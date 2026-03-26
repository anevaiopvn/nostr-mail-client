import 'package:flutter/material.dart';

// TODO: Update EmailAvatar to take a MailAddress object as parameter instead of String
class EmailAvatar extends StatelessWidget {
  final String email;
  final double radius;
  final VoidCallback? onTap;

  const EmailAvatar({
    super.key,
    required this.email,
    this.radius = 20,
    this.onTap,
  });

  Color _getAvatarColor(BuildContext context) {
    if (email.isEmpty) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    final hash = email.hashCode;
    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    ).withValues(alpha: 1);
  }

  String _getInitial() {
    if (email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(context);

    final isDark =
        ThemeData.estimateBrightnessForColor(avatarColor) == Brightness.dark;

    final avatar = CircleAvatar(
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

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
