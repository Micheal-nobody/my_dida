String? mapSelectionToRRule(String selection, DateTime? baseDate) {
  if (selection == '无') return null;
  if (selection == '每天') return 'RRULE:FREQ=DAILY';
  if (selection.startsWith('每周')) {
    if (selection.startsWith('每周工作日')) {
      return 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
    }
    final DateTime date = baseDate ?? DateTime.now();
    const codes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    final code = codes[(date.weekday - 1).clamp(0, 6)];
    return 'RRULE:FREQ=WEEKLY;BYDAY=$code';
  }
  if (selection.startsWith('每月')) {
    final DateTime date = baseDate ?? DateTime.now();
    return 'RRULE:FREQ=MONTHLY;BYMONTHDAY=${date.day}';
  }
  if (selection.startsWith('每年')) {
    final DateTime date = baseDate ?? DateTime.now();
    return 'RRULE:FREQ=YEARLY;BYMONTH=${date.month};BYMONTHDAY=${date.day}';
  }
  if (selection.startsWith('每周工作日')) {
    return 'RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
  }
  return null;
}

String rruleToSelection(String? rrule) {
  if (rrule == null || rrule.isEmpty) return '无';
  if (rrule.contains('FREQ=DAILY')) return '每天';
  if (rrule.contains('FREQ=WEEKLY') && rrule.contains('BYDAY=MO,TU,WE,TH,FR')) {
    return '每周工作日';
  }
  if (rrule.contains('FREQ=WEEKLY')) return '每周';
  if (rrule.contains('FREQ=MONTHLY')) return '每月';
  if (rrule.contains('FREQ=YEARLY')) return '每年';
  return '无';
}

List<String> buildRepeatOptions(DateTime? baseDate) {
  String weekdayCn(int weekday) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  String weeklyLabel() {
    if (baseDate == null) return '每周';
    return '每周 (周${weekdayCn(baseDate.weekday)})';
  }

  String monthlyLabel() {
    if (baseDate == null) return '每月';
    return '每月 (${baseDate.day}日)';
  }

  String yearlyLabel() {
    if (baseDate == null) return '每年';
    return '每年 (${baseDate.month}月${baseDate.day}日)';
  }

  return [
    '无',
    '每天',
    weeklyLabel(),
    monthlyLabel(),
    yearlyLabel(),
    '每周工作日 (周一至周五)',
    '法定工作日',
    '艾宾浩斯记忆法',
    '自定义重复',
  ];
}
