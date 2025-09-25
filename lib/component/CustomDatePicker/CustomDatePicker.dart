import 'package:flutter/material.dart';
import 'CalendarWidget.dart';
import 'TimeSlotTabWidget.dart';

//TODO：CustomDatePicker 并没有成功修改Task的rrule!（可能是TODO： CustomRepeatPicker 的原因，也可能是调用 CustomRepeatPicker 或者 调用 CustomDatePicker 的地方的原因）
class CustomDatePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final Function(DateTime) onDateChanged;
  final Function(TimeOfDay?, TimeOfDay?) onTimeChanged;
  final Function(bool) onAllDayChanged;
  final VoidCallback onClear;
  final Function(String?)? onRepeatChanged;
  final String? initialRRule;

  const CustomDatePicker({
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
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  String? _rrule;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = widget.selectedDate;
    _startTime = widget.startTime;
    _endTime = widget.endTime;
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
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Date tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CalendarWidget(
                    selectedDate: _selectedDate,
                    initialTime: _startTime,
                    initialRRule: _rrule,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                      widget.onDateChanged(date);
                    },
                    onTimeChanged: (start, end) {
                      setState(() {
                        _startTime = start;
                        _endTime = end;
                      });
                      widget.onTimeChanged(start, end);
                    },
                    onRepeatChanged: (rrule) {
                      setState(() {
                        _rrule = rrule;
                      });
                      if (widget.onRepeatChanged != null) {
                        widget.onRepeatChanged!(rrule);
                      }
                    },
                  ),
                ),
                // Time slot tab
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TimeSlotTabWidget(
                    selectedDate: _selectedDate,
                    startTime: _startTime,
                    endTime: _endTime,
                    isAllDay: _isAllDay,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                      widget.onDateChanged(date);
                    },
                    onTimeChanged: (start, end) {
                      setState(() {
                        _startTime = start;
                        _endTime = end;
                      });
                      widget.onTimeChanged(start, end);
                    },
                    onAllDayChanged: (isAllDay) {
                      setState(() {
                        _isAllDay = isAllDay;
                      });
                      widget.onAllDayChanged(isAllDay);
                    },
                    onSwitchToDateTab: () {
                      _tabController.animateTo(0);
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
