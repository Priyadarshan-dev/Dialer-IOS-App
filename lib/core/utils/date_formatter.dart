import 'package:intl/intl.dart';

class DateFormatter {
  static String formatCallTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (callDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (callDate == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('dd MMM, h:mm a').format(dateTime);
    }
  }
}
