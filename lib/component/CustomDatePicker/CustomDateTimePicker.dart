import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'CalendarWidget.dart';
import 'TimeSlotTabWidget.dart';

/// 显示自定义日期时间选择器的通用方法
///
/// 使用示例:
/// ```dart
/// await CustomDateTimePicker.show(
///   context: context,
///   selectedDate: _selectedDate,
///   startTime: _startTime,
///   endTime: _endTime,
///   isAllDay: _isAllDay,
///   onDateChanged: (date) => setState(() => _selectedDate = date),
///   onTimeChanged: (start, end) => setState(() {
///     _startTime = start;
///     _endTime = end;
///   }),
///   onDateTimeChanged: (startDateTime, endDateTime) => setState(() {
///     _startDateTime = startDateTime;
///     _endDateTime = endDateTime;
///   }),
///   onAllDayChanged: (isAllDay) => setState(() => _isAllDay = isAllDay),
///   onClear: () => setState(() {
///     _selectedDate = DateTime.now();
///     _startTime = null;
///     _endTime = null;
///     _startDateTime = null;
///     _endDateTime = null;
///     _isAllDay = false;
///   }),
/// );
/// ```
class CustomDateTimePickerModal {
  static Future<void> show({
    required BuildContext context,
    DateTime? selectedDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool isAllDay = false,
    String? initialRRule,
    bool isTimeOnlyDate = false,
    required Function(DateTime) onDateChanged,
    required Function(TimeOfDay?, TimeOfDay?) onTimeChanged,
    Function(DateTime?, DateTime?)? onDateTimeChanged,
    required Function(bool) onAllDayChanged,
    required VoidCallback onClear,
    Function(String?)? onRepeatChanged,
    Function(DateTime?, DateTime?)? onStartEndDateChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CustomDateTimePicker(
            selectedDate: selectedDate,
            startTime: startTime,
            endTime: endTime,
            isAllDay: isAllDay,
            initialRRule: initialRRule,
            isTimeOnlyDate: isTimeOnlyDate,
            onDateChanged: onDateChanged,
            onTimeChanged: onTimeChanged,
            onDateTimeChanged: onDateTimeChanged,
            onAllDayChanged: onAllDayChanged,
            onClear: onClear,
            onRepeatChanged: onRepeatChanged,
            onStartEndDateChanged: onStartEndDateChanged,
          ),
        );
      },
    );
  }
}

class CustomDateTimePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final Function(DateTime) onDateChanged;
  final Function(TimeOfDay?, TimeOfDay?) onTimeChanged;
  final Function(DateTime?, DateTime?)? onDateTimeChanged;
  final Function(bool) onAllDayChanged;
  final VoidCallback onClear;
  final Function(String?)? onRepeatChanged;
  final String? initialRRule;
  final bool isTimeOnlyDate;
  final Function(DateTime?, DateTime?)? onStartEndDateChanged;

  const CustomDateTimePicker({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onAllDayChanged,
    required this.onClear,
    this.onRepeatChanged,
    this.initialRRule,
    this.onDateTimeChanged,
    this.isTimeOnlyDate = false,
    this.onStartEndDateChanged,
  });

  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isAllDay = false;
  String? _rrule;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = widget.selectedDate;
    _startTime = widget.startTime;
    _endTime = widget.endTime;
    _startDate = widget.selectedDate;
    _endDate = widget.selectedDate;
    _isAllDay = widget.isAllDay;
    _rrule = widget.initialRRule;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
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
                    // Apply selections only on confirm
                    // logger 当前处于哪个tab
                    logger.i("当前处于哪个tab: ${_tabController.index}");

                    // Use independent start and end dates
                    DateTime? startDateTime;
                    DateTime? endDateTime;

                    if (_startTime != null && _startDate != null) {
                      startDateTime = DateTime(
                        _startDate!.year,
                        _startDate!.month,
                        _startDate!.day,
                        _startTime!.hour,
                        _startTime!.minute,
                      );
                    }

                    if (_endTime != null && _endDate != null) {
                      endDateTime = DateTime(
                        _endDate!.year,
                        _endDate!.month,
                        _endDate!.day,
                        _endTime!.hour,
                        _endTime!.minute,
                      );
                    }

                    // 只在时间段区域且为全天任务时清空时间
                    if (_tabController.index == 1 && _isAllDay) {
                      startDateTime = null;
                      endDateTime = null;
                    } else if (_tabController.index == 1) {
                      // 在时间段区域，确保时间有效性
                      if (startDateTime == null && endDateTime == null) {
                        // 如果用户没有设置任何时间，提供默认值
                        final baseDate =
                            _startDate ??
                            _endDate ??
                            _selectedDate ??
                            DateTime.now();
                        startDateTime = DateTime(
                          baseDate.year,
                          baseDate.month,
                          baseDate.day,
                          9,
                          0,
                        );
                        endDateTime = DateTime(
                          baseDate.year,
                          baseDate.month,
                          baseDate.day,
                          10,
                          0,
                        );
                      } else if (startDateTime != null && endDateTime == null) {
                        // 如果只有开始时间，自动计算结束时间
                        endDateTime = startDateTime.add(
                          const Duration(hours: 1),
                        );
                      } else if (startDateTime == null && endDateTime != null) {
                        // 如果只有结束时间，自动计算开始时间
                        startDateTime = endDateTime.subtract(
                          const Duration(hours: 1),
                        );
                      }

                      // 确保结束时间大于开始时间（至少1分钟）
                      if (startDateTime != null && endDateTime != null) {
                        if (endDateTime.isBefore(startDateTime) ||
                            endDateTime.isAtSameMomentAs(startDateTime)) {
                          endDateTime = startDateTime.add(
                            const Duration(minutes: 1),
                          );
                        }
                      }
                    }

                    // Convert back to TimeOfDay for the callback
                    TimeOfDay? start = startDateTime != null
                        ? TimeOfDay.fromDateTime(startDateTime)
                        : null;
                    TimeOfDay? end = endDateTime != null
                        ? TimeOfDay.fromDateTime(endDateTime)
                        : null;

                    if (_selectedDate != null) {
                      widget.onDateChanged(_selectedDate!);
                    }
                    widget.onTimeChanged(start, end);

                    // Pass complete DateTime information if callback is provided
                    if (widget.onDateTimeChanged != null) {
                      widget.onDateTimeChanged!(startDateTime, endDateTime);
                    }

                    widget.onAllDayChanged(_isAllDay);

                    // Update RRULE if it has changed
                    if (widget.onRepeatChanged != null) {
                      widget.onRepeatChanged!(_rrule);
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 日期 区域
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CalendarWidget(
                    selectedDate: _selectedDate,
                    initialTime: _startTime,
                    initialRRule: _rrule,
                    isTimeOnlyDate: widget.isTimeOnlyDate,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    onTimeChanged: (start, end) {
                      setState(() {
                        _startTime = start;
                        _endTime = end;
                      });
                    },
                    onRepeatChanged: (rrule) {
                      setState(() {
                        _rrule = rrule;
                      });
                    },
                  ),
                ),
                // 时间段 区域
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Builder(
                    builder: (context) {
                      return TimeSlotTabWidget(
                        selectedDate: _selectedDate,
                        startTime: _startTime,
                        endTime: _endTime,
                        isAllDay: _isAllDay,
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        onTimeChanged: (start, end) {
                          setState(() {
                            _startTime = start;
                            _endTime = end;
                          });
                        },
                        onAllDayChanged: (isAllDay) {
                          setState(() {
                            _isAllDay = isAllDay;
                          });
                        },
                        onRepeatChanged: (rrule) {
                          setState(() {
                            _rrule = rrule;
                          });
                        },
                        onSwitchToDateTab: () {
                          _tabController.animateTo(0);
                        },
                        onStartEndDateChanged: (startDate, endDate) {
                          setState(() {
                            _startDate = startDate;
                            _endDate = endDate;
                          });
                          // 通知外部回调
                          if (widget.onStartEndDateChanged != null) {
                            widget.onStartEndDateChanged!(startDate, endDate);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextButton(
                onPressed: () {
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: const Text('清除', style: TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
