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
}
