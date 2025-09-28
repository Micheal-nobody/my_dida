extension DateOnly on DateTime {
  DateTime get dateOnly {
    return DateTime(year, month, day);
  }

  DateTime get dateAndTime {
    return DateTime(year, month, day, hour, minute);
  }

  DateTime toBeijingTime(){
    return toUtc().add(Duration(hours: 8));
  }

  bool isToday() {
    return dateOnly.isAtSameMomentAs(DateTime.now().dateOnly);
  }

  bool hasTime() {
    return hour != 0 || minute != 0;
  }

  bool justDate() {
    return hour == 0 && minute == 0;
  }
}
