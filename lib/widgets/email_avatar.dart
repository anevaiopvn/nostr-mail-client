import 'package:enough_mail_plus/enough_mail.dart';
import 'package:flutter/material.dart';

class EmailAvatar extends StatelessWidget {
  final MailAddress mailAddress;
  final double radius;
  final VoidCallback? onTap;

  const EmailAvatar({
    super.key,
    required this.mailAddress,
    this.radius = 20,
    this.onTap,
  });

  Color _getAvatarColor(BuildContext context) {
    if (mailAddress.email.isEmpty) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    final hash = mailAddress.hashCode;
    return Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
    ).withValues(alpha: 1);
  }

  String _getInitial() {
    if (mailAddress.email.isEmpty) return '?';
    // Use personal name if available, otherwise use first letter of email address
    if (mailAddress.hasPersonalName) {
      return mailAddress.personalName![0].toUpperCase();
    }
    if (mailAddress.email.isNotEmpty) {
      return mailAddress.email[0].toUpperCase();
    }
    return '?';
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
