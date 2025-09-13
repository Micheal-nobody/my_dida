import 'package:flutter/material.dart';
import 'CalendarWidget.dart';
import 'TimeSlotTabWidget.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final Function(DateTime) onDateChanged;
  final Function(TimeOfDay?, TimeOfDay?) onTimeChanged;
  final Function(bool) onAllDayChanged;
  final VoidCallback onClear;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = widget.selectedDate;
    _startTime = widget.startTime;
    _endTime = widget.endTime;
    _isAllDay = widget.isAllDay;
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
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                      widget.onDateChanged(date);
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
