import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatDateTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMd(locale).add_Hm().format(date);
}
