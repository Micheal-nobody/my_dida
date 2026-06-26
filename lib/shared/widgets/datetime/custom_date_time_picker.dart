import 'package:flutter/material.dart';
import 'package:my_dida/core/utils/time_utils.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';

import 'package:my_dida/shared/widgets/datetime/calendar_widget.dart';
import 'package:my_dida/shared/widgets/datetime/time_slot_tab_widget.dart';

class CustomDateTimePickerValue {
  const CustomDateTimePickerValue({
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.startDate,
    this.endDate,
    this.isAllDay = false,
    this.rrule = const RepeatPattern.none(),
    this.isTimeOnlyDate = false,
    this.reminderOffsets = const [],
    this.notificationEnabled = false,
  });

  factory CustomDateTimePickerValue.cleared() {
    final now = DateTime.now().toBeijingTime().dateOnly;
    return CustomDateTimePickerValue(
      selectedDate: now,
      reminderOffsets: const [],
      notificationEnabled: false,
    );
  }

  static const Object _sentinel = Object();

  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final RepeatPattern rrule;
  final bool isTimeOnlyDate;
  final List<int> reminderOffsets;
  final bool notificationEnabled;

  CustomDateTimePickerValue copyWith({
    Object? selectedDate = _sentinel,
    Object? startTime = _sentinel,
    Object? endTime = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    bool? isAllDay,
    Object? rrule = _sentinel,
    bool? isTimeOnlyDate,
    List<int>? reminderOffsets,
    bool? notificationEnabled,
  }) => CustomDateTimePickerValue(
    selectedDate: identical(selectedDate, _sentinel)
        ? this.selectedDate
        : selectedDate as DateTime?,
    startTime: identical(startTime, _sentinel)
        ? this.startTime
        : startTime as TimeOfDay?,
    endTime: identical(endTime, _sentinel)
        ? this.endTime
        : endTime as TimeOfDay?,
    startDate: identical(startDate, _sentinel)
        ? this.startDate
        : startDate as DateTime?,
    endDate: identical(endDate, _sentinel)
        ? this.endDate
        : endDate as DateTime?,
    isAllDay: isAllDay ?? this.isAllDay,
    rrule: identical(rrule, _sentinel) ? this.rrule : rrule as RepeatPattern,
    isTimeOnlyDate: isTimeOnlyDate ?? this.isTimeOnlyDate,
    reminderOffsets: reminderOffsets ?? this.reminderOffsets,
    notificationEnabled: notificationEnabled ?? this.notificationEnabled,
  );
}

class CustomDateTimePickerModal {
  static Future<CustomDateTimePickerValue?> show({
    required BuildContext context,
    required CustomDateTimePickerValue initialValue,
  }) => showModalBottomSheet<CustomDateTimePickerValue>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: CustomDateTimePicker(initialValue: initialValue),
    ),
  );
}

class CustomDateTimePicker extends StatefulWidget {
  const CustomDateTimePicker({required this.initialValue, super.key});

  final CustomDateTimePickerValue initialValue;

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late CustomDateTimePickerValue _value;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _value = widget.initialValue;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  CustomDateTimePickerValue _normalizeValue() {
    DateTime? startDateTime;
    DateTime? endDateTime;

    if (_value.startTime != null && _value.startDate != null) {
      startDateTime = DateTime(
        _value.startDate!.year,
        _value.startDate!.month,
        _value.startDate!.day,
        _value.startTime!.hour,
        _value.startTime!.minute,
      );
    }

    if (_value.endTime != null && _value.endDate != null) {
      endDateTime = DateTime(
        _value.endDate!.year,
        _value.endDate!.month,
        _value.endDate!.day,
        _value.endTime!.hour,
        _value.endTime!.minute,
      );
    }

    if (_tabController.index == 1 && _value.isAllDay) {
      startDateTime = null;
      endDateTime = null;
    } else if (_tabController.index == 1) {
      if (startDateTime == null && endDateTime == null) {
        final baseDate =
            _value.startDate ??
            _value.endDate ??
            _value.selectedDate ??
            DateTime.now();
        startDateTime = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          9,
        );
        endDateTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 10);
      } else if (startDateTime != null && endDateTime == null) {
        endDateTime = startDateTime.add(const Duration(hours: 1));
      } else if (startDateTime == null && endDateTime != null) {
        startDateTime = endDateTime.subtract(const Duration(hours: 1));
      }

      if (startDateTime != null &&
          endDateTime != null &&
          (endDateTime.isBefore(startDateTime) ||
              endDateTime.isAtSameMomentAs(startDateTime))) {
        endDateTime = startDateTime.add(const Duration(minutes: 1));
      }
    }

    return _value.copyWith(
      startDate: startDateTime != null
          ? DateTime(startDateTime.year, startDateTime.month, startDateTime.day)
          : _value.startDate,
      endDate: endDateTime != null
          ? DateTime(endDateTime.year, endDateTime.month, endDateTime.day)
          : _value.endDate,
      startTime: startDateTime != null
          ? TimeOfDay.fromDateTime(startDateTime)
          : null,
      endTime: endDateTime != null ? TimeOfDay.fromDateTime(endDateTime) : null,
      isAllDay: _tabController.index == 0
          ? (_value.startTime == null)
          : _value.isAllDay,
      rrule: _value.rrule,
      reminderOffsets: _value.reminderOffsets,
      notificationEnabled: _value.notificationEnabled,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.of(context).size.height * 0.8,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '日期'),
                    Tab(text: '时间段'),
                  ],
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.orange,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.orange),
                onPressed: () {
                  Navigator.pop(context, _normalizeValue());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CalendarWidget(
                  initialValue: CalendarWidgetValue(
                    selectedDate: _value.selectedDate,
                    selectedTime: _value.startTime,
                    rrule: _value.rrule,
                    isTimeOnlyDate: _value.isTimeOnlyDate,
                    reminderOffsets: _value.reminderOffsets,
                    notificationEnabled: _value.notificationEnabled,
                  ),
                  onChanged: (calendarValue) {
                    setState(() {
                      _value = _value.copyWith(
                        selectedDate: calendarValue.selectedDate,
                        startTime: calendarValue.selectedTime,
                        endTime: _value.endTime,
                        startDate:
                            calendarValue.selectedDate ?? _value.startDate,
                        endDate: _value.endDate ?? calendarValue.selectedDate,
                        rrule: calendarValue.rrule,
                        isTimeOnlyDate: calendarValue.isTimeOnlyDate,
                        reminderOffsets: calendarValue.reminderOffsets,
                        notificationEnabled: calendarValue.notificationEnabled,
                      );
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TimeSlotTabWidget(
                  initialValue: TimeSlotTabValue(
                    selectedDate: _value.selectedDate,
                    startTime: _value.startTime,
                    endTime: _value.endTime,
                    startDate: _value.startDate ?? _value.selectedDate,
                    endDate: _value.endDate ?? _value.selectedDate,
                    isAllDay: _value.isAllDay,
                    rrule: _value.rrule,
                  ),
                  onChanged: (timeSlotValue) {
                    setState(() {
                      _value = _value.copyWith(
                        selectedDate: timeSlotValue.selectedDate,
                        startTime: timeSlotValue.startTime,
                        endTime: timeSlotValue.endTime,
                        startDate: timeSlotValue.startDate,
                        endDate: timeSlotValue.endDate,
                        isAllDay: timeSlotValue.isAllDay,
                        rrule: timeSlotValue.rrule,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context, CustomDateTimePickerValue.cleared());
              },
              child: const Text('清除', style: TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ],
    ),
  );
}
