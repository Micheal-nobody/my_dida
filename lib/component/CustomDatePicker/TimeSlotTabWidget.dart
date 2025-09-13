import 'package:flutter/material.dart';

class TimeSlotTabWidget extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final Function(DateTime) onDateChanged;
  final Function(TimeOfDay?, TimeOfDay?) onTimeChanged;
  final Function(bool) onAllDayChanged;
  final VoidCallback onSwitchToDateTab;

  const TimeSlotTabWidget({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onAllDayChanged,
    required this.onSwitchToDateTab,
  });

  @override
  State<TimeSlotTabWidget> createState() => _TimeSlotTabWidgetState();
}

class _TimeSlotTabWidgetState extends State<TimeSlotTabWidget> {
  String _formatDate(DateTime date) {
    const months = [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ];
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return '${months[date.month - 1]}${date.day}日, ${weekdays[date.weekday - 1]}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getDuration() {
    if (widget.startTime != null && widget.endTime != null) {
      final startMinutes =
          widget.startTime!.hour * 60 + widget.startTime!.minute;
      final endMinutes = widget.endTime!.hour * 60 + widget.endTime!.minute;
      final duration = endMinutes - startMinutes;
      final hours = duration ~/ 60;
      final minutes = duration % 60;

      if (hours > 0 && minutes > 0) {
        return '${hours}小时${minutes}分钟';
      } else if (hours > 0) {
        return '${hours}小时';
      } else {
        return '${minutes}分钟';
      }
    }
    return '';
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (widget.startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (widget.endTime ?? const TimeOfDay(hour: 10, minute: 0)),
    );

    if (picked != null) {
      TimeOfDay? newStartTime = widget.startTime;
      TimeOfDay? newEndTime = widget.endTime;

      if (isStartTime) {
        newStartTime = picked;
        // Auto-set end time to 1 hour later if not set
        if (newEndTime == null) {
          final endHour = (picked.hour + 1) % 24;
          newEndTime = TimeOfDay(hour: endHour, minute: picked.minute);
        }
      } else {
        newEndTime = picked;
      }

      widget.onTimeChanged(newStartTime, newEndTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Date and Time cards
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onSwitchToDateTab,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '日期',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedDate != null
                            ? _formatDate(widget.selectedDate!)
                            : '选择日期',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      if (widget.selectedDate != null)
                        Text(
                          '${DateTime.now().difference(widget.selectedDate!).inDays.abs()}天前',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectTime(true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '时间',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.startTime != null && widget.endTime != null
                            ? '${_formatTime(widget.startTime!)} - ${_formatTime(widget.endTime!)}'
                            : '选择时间',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      if (widget.startTime != null && widget.endTime != null)
                        Text(
                          '持续时间: ${_getDuration()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // All day toggle
        Row(
          children: [
            const Text('全天'),
            const Spacer(),
            Switch(value: widget.isAllDay, onChanged: widget.onAllDayChanged),
          ],
        ),

        const SizedBox(height: 20),

        // Reminder setting
        Row(
          children: [
            const Icon(Icons.alarm, color: Colors.grey),
            const SizedBox(width: 12),
            const Text('提醒'),
            const Spacer(),
            const Text('准时 ×'),
          ],
        ),

        const SizedBox(height: 20),

        // Repeat setting
        Row(
          children: [
            const Icon(Icons.refresh, color: Colors.grey),
            const SizedBox(width: 12),
            const Text('重复'),
            const Spacer(),
            const Text('无 >'),
          ],
        ),
      ],
    );
  }
}
