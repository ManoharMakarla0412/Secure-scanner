import 'package:intl/intl.dart';
import '../../services/language_service.dart';

class DateHelper {
  static String formatHistoryDate(DateTime dateTime) {
    final locale = LanguageController.instance.currentLanguageCode;
    return DateFormat.yMMMd(locale).add_jm().format(dateTime.toLocal());
  }

  static String formatCreatedDate(DateTime dateTime) {
    // Legacy format support if needed: "dd MMM yyyy | hh:mm am/pm"
    final d = dateTime.day.toString().padLeft(2, '0');
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = months[dateTime.month - 1];
    final y = dateTime.year.toString();
    int hour = dateTime.hour;
    final min = dateTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'pm' : 'am';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return "$d $m $y | $hour:$min $ampm";
  }
}
