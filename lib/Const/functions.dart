import 'package:intl/intl.dart';

String prettifyPhonenumber({required String phonenumber}) {
  return phonenumber.substring(0, 3) +
      " " +
      phonenumber.substring(3, 8) +
      " " +
      phonenumber.substring(8, phonenumber.length);
}

String getDayFromDate(
    {required DateTime curruntTime, required DateTime msgTime}) {
  DateTime now = curruntTime;
  DateTime localDateTime = msgTime.toLocal();
  // if (!localDateTime.difference(justNow).isNegative) {
  //   return "just now";
  // }
  if (localDateTime.day == now.day &&
      localDateTime.month == now.month &&
      localDateTime.year == now.year) {
    return "Today";
  }
  String roughTimeString = DateFormat('EEE, d/M/y').format(msgTime);
  if (localDateTime.day == now.day &&
      localDateTime.month == now.month &&
      localDateTime.year == now.year) {
    return roughTimeString;
  }
  DateTime yesterday = now.subtract(const Duration(days: 1));
  if (localDateTime.day == yesterday.day &&
      localDateTime.month == now.month &&
      localDateTime.year == now.year) {
    return "yesterday";
  }

  return ' $roughTimeString';
}
