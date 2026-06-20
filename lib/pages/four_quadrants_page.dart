import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/config/logger.dart';
import 'package:my_dida/constants/colors_constants.dart';
import 'package:my_dida/constants/dimension_constants.dart';
import 'package:my_dida/constants/ui_constants.dart';
import 'package:my_dida/features/cards/task_card.dart';
import 'package:my_dida/features/dialogs/add_task_dialog.dart';
import 'package:my_dida/features/task_detail/task_detail_page.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/checklist_provider.dart';
import 'package:my_dida/provider/sidebar_config_provider.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

class FourQuadrantsPage extends StatelessWidget {
  const FourQuadrantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final configProvider = Provider.of<SidebarConfigProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final config = configProvider.config;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '时间管理四象限',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsBottomSheet(context, configProvider),
          ),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: taskProvider.watchAllTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }

          final allTasks = snapshot.data ?? [];

          // 过滤已完成任务
          final filteredTasks = config.quadrantHideCompleted
              ? allTasks.where((t) => !t.isDone).toList()
              : allTasks;

          // 按照优先级进行分类
          final highTasks = filteredTasks
              .where((t) => t.priority == TaskPriority.high)
              .toList();
          final mediumTasks = filteredTasks
              .where((t) => t.priority == TaskPriority.medium)
              .toList();
          final lowTasks = filteredTasks
              .where((t) => t.priority == TaskPriority.low)
              .toList();
          final noneTasks = filteredTasks
              .where((t) => t.priority == TaskPriority.none)
              .toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuadrantCard(
                            context: context,
                            title: config.quadrantName1,
                            color: Color(config.quadrantColor1),
                            tasks: highTasks,
                            priority: TaskPriority.high,
                            taskProvider: taskProvider,
                            allChecklists: checklistProvider.allCheckLists,
                          ),
                        ),
                        Expanded(
                          child: _buildQuadrantCard(
                            context: context,
                            title: config.quadrantName2,
                            color: Color(config.quadrantColor2),
                            tasks: mediumTasks,
                            priority: TaskPriority.medium,
                            taskProvider: taskProvider,
                            allChecklists: checklistProvider.allCheckLists,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuadrantCard(
                            context: context,
                            title: config.quadrantName3,
                            color: Color(config.quadrantColor3),
                            tasks: lowTasks,
                            priority: TaskPriority.low,
                            taskProvider: taskProvider,
                            allChecklists: checklistProvider.allCheckLists,
                          ),
                        ),
                        Expanded(
                          child: _buildQuadrantCard(
                            context: context,
                            title: config.quadrantName4,
                            color: Color(config.quadrantColor4),
                            tasks: noneTasks,
                            priority: TaskPriority.none,
                            taskProvider: taskProvider,
                            allChecklists: checklistProvider.allCheckLists,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuadrantCard({
    required BuildContext context,
    required String title,
    required Color color,
    required List<Task> tasks,
    required TaskPriority priority,
    required TaskProvider taskProvider,
    required List<dynamic> allChecklists,
  }) {
    final activeCount = tasks.where((t) => !t.isDone).length;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.priority != priority,
      onAcceptWithDetails: (details) async {
        final task = details.data;
        logger.i(
          'Dragged task "${task.name}" to quadrant with priority $priority',
        );
        await taskProvider.updatePriority(task, priority);
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isOver
                ? color.withValues(alpha: 0.15)
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(
              color: isOver ? color : color.withValues(alpha: 0.3),
              width: isOver ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部标题栏
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$activeCount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: color, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _addNewTask(context, priority),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),

              // 任务列表
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          '暂无任务',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final cardWidget = TaskCard(
                            task: task,
                            checklistName: _getChecklistName(
                              task.checklistId,
                              allChecklists,
                            ),
                            onToggleDone: (val) async {
                              await taskProvider.updateTaskIsDone(task, val!);
                            },
                            onTap: () => TaskDetailPage.show(context, task),
                          );

                          return LongPressDraggable<Task>(
                            data: task,
                            feedback: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.43,
                                child: cardWidget,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: cardWidget,
                            ),
                            child: cardWidget,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getChecklistName(int? id, List<dynamic> allChecklists) {
    if (id == null) return '';
    final cl = allChecklists.firstWhere(
      (c) => c.id == id,
      orElse: () => allChecklists.first,
    );
    return cl.name;
  }

  void _addNewTask(BuildContext context, TaskPriority priority) {
    final presetTask = Task(name: '', isAllDay: true, priority: priority);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTaskDialog(presetTask: presetTask),
      ),
    );
  }

  void _showSettingsBottomSheet(
    BuildContext context,
    SidebarConfigProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _FourQuadrantsSettingsSheet(provider: provider);
      },
    );
  }
}

class _FourQuadrantsSettingsSheet extends StatefulWidget {
  const _FourQuadrantsSettingsSheet({required this.provider});

  final SidebarConfigProvider provider;

  @override
  State<_FourQuadrantsSettingsSheet> createState() =>
      _FourQuadrantsSettingsSheetState();
}

class _FourQuadrantsSettingsSheetState
    extends State<_FourQuadrantsSettingsSheet> {
  late bool _hideCompleted;
  late TextEditingController _name1Controller;
  late TextEditingController _name2Controller;
  late TextEditingController _name3Controller;
  late TextEditingController _name4Controller;

  late int _color1;
  late int _color2;
  late int _color3;
  late int _color4;

  final List<int> _presetColors = [
    0xFFE57373, // 红色
    0xFFFFB74D, // 橙色/黄色
    0xFF64B5F6, // 蓝色
    0xFF81C784, // 绿色
    0xFFBA68C8, // 紫色
    0xFF90A4AE, // 灰蓝色
  ];

  @override
  void initState() {
    super.initState();
    final config = widget.provider.config;
    _hideCompleted = config.quadrantHideCompleted;
    _name1Controller = TextEditingController(text: config.quadrantName1);
    _name2Controller = TextEditingController(text: config.quadrantName2);
    _name3Controller = TextEditingController(text: config.quadrantName3);
    _name4Controller = TextEditingController(text: config.quadrantName4);

    _color1 = config.quadrantColor1;
    _color2 = config.quadrantColor2;
    _color3 = config.quadrantColor3;
    _color4 = config.quadrantColor4;
  }

  @override
  void dispose() {
    _name1Controller.dispose();
    _name2Controller.dispose();
    _name3Controller.dispose();
    _name4Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '四象限视图设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('隐藏已完成任务'),
              subtitle: const Text('开启后只显示未完成的待办'),
              value: _hideCompleted,
              activeColor: Colors.orange,
              onChanged: (val) {
                setState(() {
                  _hideCompleted = val;
                });
                widget.provider.updateQuadrantHideCompleted(val);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '自定义象限名称与颜色',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            _buildQuadrantEditor(
              1,
              _name1Controller,
              _color1,
              (color) {
                setState(() => _color1 = color);
                widget.provider.updateQuadrantColors(color1: color);
              },
              (text) {
                widget.provider.updateQuadrantNames(name1: text);
              },
            ),
            const SizedBox(height: 12),
            _buildQuadrantEditor(
              2,
              _name2Controller,
              _color2,
              (color) {
                setState(() => _color2 = color);
                widget.provider.updateQuadrantColors(color2: color);
              },
              (text) {
                widget.provider.updateQuadrantNames(name2: text);
              },
            ),
            const SizedBox(height: 12),
            _buildQuadrantEditor(
              3,
              _name3Controller,
              _color3,
              (color) {
                setState(() => _color3 = color);
                widget.provider.updateQuadrantColors(color3: color);
              },
              (text) {
                widget.provider.updateQuadrantNames(name3: text);
              },
            ),
            const SizedBox(height: 12),
            _buildQuadrantEditor(
              4,
              _name4Controller,
              _color4,
              (color) {
                setState(() => _color4 = color);
                widget.provider.updateQuadrantColors(color4: color);
              },
              (text) {
                widget.provider.updateQuadrantNames(name4: text);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantEditor(
    int index,
    TextEditingController controller,
    int selectedColor,
    ValueChanged<int> onColorChanged,
    ValueChanged<String> onNameSubmitted,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: Color(selectedColor)),
                const SizedBox(width: 8),
                Text(
                  '第 $index 象限',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                      hintText: '请输入象限名称',
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: onNameSubmitted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presetColors.map((hexColor) {
                  final isSelected = selectedColor == hexColor;
                  return GestureDetector(
                    onTap: () => onColorChanged(hexColor),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Color(hexColor),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black87, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
