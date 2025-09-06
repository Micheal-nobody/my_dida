import 'package:flutter/material.dart';
import 'package:my_dida/utils/TimeUtils.dart';

import '../model/TodoItem.dart';

//TODO: 这个Provider封装了一系列的待办事项操作，包括添加、删除、清空待办事项等功能。这些都要与 isar 数据库进行交互，
class TodosProvider extends ChangeNotifier {
  /// 当前的待办事项列表
  Map<DateTime,List<TodoItem>> all_todos = {}; // 当前日期的待办事项列表，按日期分组
  List<TodoItem> cur_todos = []; // 当前显示的待办事项列表
  DateTime cur_date = DateTime.now().dateOnly; // 当前日期，用于筛选待办事项

  //TODO: FutureProvider 管理一次性异步任务，可以用来读取一次数据！
  void init_todos() {
    //TODO: 优先使用 getApplicationDocumentsDirectory() 存放核心数据库/数据文件。不需要手动创建复杂的日期文件夹结构来存储核心日程数据，数据库查询是更优解。共享存储空间主要用于用户明确交互的媒体或文件。
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
  //TODO: 美化Card的样式
  static Card generateCard(TodoItem item) {
    //TODO:如果item已完成，那么就不生成Card了。
    //TODO:是否显示已完成的待办事项可以通过一个开关来控制，用一个Provider来记录开关的状态

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
                    //TODO: 删除操作
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
    // todos.add(todo);
    // notifyListeners(); // 通知所有监听者状态已改变
  }

  /// 删除一个待办事项
  void removeTodo(String todo) {
    // todos.remove(todo);
    // notifyListeners(); // 通知所有监听者状态已改变
  }

  /// 清空所有待办事项
  void clearTodos() {
    // todos.clear();
    // notifyListeners(); // 通知所有监听者状态已改变
  }
}
