import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/cards/HabitCard.dart';
import '../components/dialogs/AddHabitDialog.dart';
import '../provider/HabitProvider.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  void initState() {
    super.initState();
    // 加载习惯数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HabitProvider>(context, listen: false).loadAllHabits();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('习惯管理'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),

    body: Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.habits;

        if (habits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '还没有创建任何习惯',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '点击右下角的 + 按钮创建第一个习惯吧！',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: habits.length,
          itemBuilder: (context, index) => HabitCard(habits[index]),
        );
      },
    ),

    floatingActionButton: FloatingActionButton(
      onPressed: () {
        AddHabitDialog.show(context);
      },
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
}
