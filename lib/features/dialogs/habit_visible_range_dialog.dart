import 'package:flutter/material.dart';
import 'package:my_dida/provider/habit_provider.dart';
import 'package:provider/provider.dart';

class HabitVisibleRangeDialog extends StatefulWidget {
  const HabitVisibleRangeDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const HabitVisibleRangeDialog(),
    );
  }

  @override
  State<HabitVisibleRangeDialog> createState() =>
      _HabitVisibleRangeDialogState();
}

class _HabitVisibleRangeDialogState extends State<HabitVisibleRangeDialog> {
  late HabitStatusFilter _tempStatus;
  late HabitTimeSlotFilter _tempTime;
  late HabitFrequencyFilter _tempFrequency;

  @override
  void initState() {
    super.initState();
    final provider = context.read<HabitProvider>();
    _tempStatus = provider.statusFilter;
    _tempTime = provider.timeFilter;
    _tempFrequency = provider.frequencyFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '显示范围',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempStatus = HabitStatusFilter.all;
                    _tempTime = HabitTimeSlotFilter.all;
                    _tempFrequency = HabitFrequencyFilter.all;
                  });
                },
                child: const Text('重置'),
              ),
            ],
          ),
          const Divider(),
          const Text(
            '打卡状态',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterChip(
                label: '全部',
                selected: _tempStatus == HabitStatusFilter.all,
                onSelected: () =>
                    setState(() => _tempStatus = HabitStatusFilter.all),
              ),
              _buildFilterChip(
                label: '未完成',
                selected: _tempStatus == HabitStatusFilter.incomplete,
                onSelected: () =>
                    setState(() => _tempStatus = HabitStatusFilter.incomplete),
              ),
              _buildFilterChip(
                label: '已完成',
                selected: _tempStatus == HabitStatusFilter.completed,
                onSelected: () =>
                    setState(() => _tempStatus = HabitStatusFilter.completed),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '提醒时段',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterChip(
                label: '全天',
                selected: _tempTime == HabitTimeSlotFilter.all,
                onSelected: () =>
                    setState(() => _tempTime = HabitTimeSlotFilter.all),
              ),
              _buildFilterChip(
                label: '早上',
                selected: _tempTime == HabitTimeSlotFilter.morning,
                onSelected: () =>
                    setState(() => _tempTime = HabitTimeSlotFilter.morning),
              ),
              _buildFilterChip(
                label: '中午',
                selected: _tempTime == HabitTimeSlotFilter.afternoon,
                onSelected: () =>
                    setState(() => _tempTime = HabitTimeSlotFilter.afternoon),
              ),
              _buildFilterChip(
                label: '晚上',
                selected: _tempTime == HabitTimeSlotFilter.evening,
                onSelected: () =>
                    setState(() => _tempTime = HabitTimeSlotFilter.evening),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '习惯频次',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterChip(
                label: '全部',
                selected: _tempFrequency == HabitFrequencyFilter.all,
                onSelected: () =>
                    setState(() => _tempFrequency = HabitFrequencyFilter.all),
              ),
              _buildFilterChip(
                label: '每日',
                selected: _tempFrequency == HabitFrequencyFilter.daily,
                onSelected: () =>
                    setState(() => _tempFrequency = HabitFrequencyFilter.daily),
              ),
              _buildFilterChip(
                label: '每周',
                selected: _tempFrequency == HabitFrequencyFilter.weekly,
                onSelected: () =>
                    setState(() => _tempFrequency = HabitFrequencyFilter.weekly),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    context.read<HabitProvider>().setFilters(
                      status: _tempStatus,
                      time: _tempTime,
                      frequency: _tempFrequency,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Colors.blue.shade100,
      onSelected: (_) => onSelected(),
    );
  }
}
