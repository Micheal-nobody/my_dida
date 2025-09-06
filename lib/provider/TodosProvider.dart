import 'package:flutter/material.dart';
import 'package:my_dida/utils/TimeUtils.dart';

import '../model/TodoItem.dart';

//TODO: 这个类将要被TaskProvider取代了，找个时间删了吧！
class TodosProvider extends ChangeNotifier {
  /// 当前的待办事项列表
  Map<DateTime,List<TodoItem>> all_todos = {}; // 当前日期的待办事项列表，按日期分组
  List<TodoItem> cur_todos = []; // 当前显示的待办事项列表
  DateTime cur_date = DateTime.now().dateOnly; // 当前日期，用于筛选待办事项

  void init_todos() {
    generateTestAllTodos();
    cur_todos = all_todos[cur_date] ?? [];
    //更详细的all_todos数据:
    notifyListeners();
  }

  void generateTestAllTodos() {
    for (int i = -5; i <= 5; i++) {
      /// 生成只包含年月日的 DateTime
      DateTime date = DateTime.now().add(Duration(days: i)).dateOnly;

      List<TodoItem> todosForDate = [];

      // 每个日期添加2个待办事项
      todosForDate.add(TodoItem(
        name: "任务 $i-1",
        description: "描述：这是第 $i 天的任务 1",
        endTime: date,
        isDone: false,
      ));

      todosForDate.add(TodoItem(
        name: "任务 $i-2",
        description: "描述：这是第 $i 天的任务 2",
        endTime: date,
        isDone: i % 2 == 0, // 偶数天的标记为已完成
      ));

      all_todos[date] = todosForDate;
    }

    notifyListeners(); // 通知监听者状态已更改
  }



  // 生成一个待办事项的卡片
  static Card generateCard(TodoItem item) {

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,

      /// elevation 设置卡片的阴影效果
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      /// 卡片的边距
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          /// crossAxisAlignment 设置子组件在交叉轴上的对齐方式
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Row 用于水平布局
            Row(
              children: [
                Icon(
                  item.isDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: item.isDone ? Colors.green : Colors.grey,
                ),

                /// SizedBox 用于设置子组件的宽度
                const SizedBox(width: 12),

                /// Expanded 用于在 Row 中占据剩余空间
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    print("Remove successful");
                  },
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text(
                  item.endTime != null
                      ? '截止: ${item.endTime!.toLocal().toString().split(' ')[0]}'
                      : '无截止时间',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 添加一个新的待办事项
  void addTodo(String todo) {
    // notifyListeners(); // 通知所有监听者状态已改变
  }

  /// 删除一个待办事项
  void removeTodo(String todo) {
    // notifyListeners(); // 通知所有监听者状态已改变
  }

  /// 清空所有待办事项
  void clearTodos() {
    // notifyListeners(); // 通知所有监听者状态已改变
  }
}
