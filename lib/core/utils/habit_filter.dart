import 'package:my_dida/features/habits/models/habit.dart';

extension HabitFilter on List<Habit> {
  // 获取所有进行中的习惯（未归档），并按 sortOrder 排序
  List<Habit> get activeHabits =>
      where((h) => !h.isArchived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  // 获取所有已归档的习惯，按 sortOrder 排序
  List<Habit> get archivedHabits =>
      where((h) => h.isArchived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
