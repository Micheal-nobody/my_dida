import 'package:flutter/material.dart';
import 'package:my_dida/component/CustomFloatingActionButton.dart';
import 'package:my_dida/component/StatelessWidget/CalendarDateHeader.dart';
import 'package:my_dida/component/StatelessWidget/CalendarScrollableContent.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

//TOOD:
class _CalendarPageState extends State<CalendarPage> {
  final DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  int _dateRange = 7; // 7-day view by default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar 区域：左侧是当前月份
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = DateTime.now();
            });
          },
          child: Text(
            DateFormat('M月').format(_currentDate),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _dateRange == 7 ? Icons.view_list : Icons.view_week,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _dateRange = _dateRange == 7 ? 3 : 7;
              });
            },
          ),
          SizedBox(width: 8),
          Icon(Icons.more_vert, color: Colors.grey[600]),
          SizedBox(width: 16),
        ],
      ),

      body: Column(
        children: [
          // 2. Header：显示日期和对应的星期
          CalendarDateHeader(
            selectedDate: _selectedDate,
            dateRange: _dateRange,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),

          // 主要内容区域
          Expanded(
            child: CalendarScrollableContent(selectedDate: _selectedDate),
          ),
        ],
      ),

      // 3. FloatingActionButton：用于添加任务
      floatingActionButton: CustomFloatingActionButton(),
    );
  }
}
