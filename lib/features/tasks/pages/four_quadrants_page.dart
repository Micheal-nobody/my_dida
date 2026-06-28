import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_dida/core/constants/dimension_constants.dart';
import 'package:my_dida/core/logger/logger.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/core/utils/task_filter.dart';
import 'package:my_dida/features/settings/providers/sidebar_config_provider.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';
import 'package:provider/provider.dart';

class FourQuadrantsPage extends StatelessWidget {
  const FourQuadrantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final configProvider = Provider.of<SidebarConfigProvider>(context);
    final config = configProvider.config;
    final colorTheme = context.theme;

    return Scaffold(
      backgroundColor: colorTheme.background,
      appBar: AppBar(
        title: const Text('四象限', style: TextStyle(fontWeight: FontWeight.bold)),
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
          final filteredTasks = allTasks.filterByIsDone(
            config.quadrantHideCompleted,
          );

          return LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildQuadrantCard(
                          context: context,
                          title: '重要且紧急',
                          tasks: filteredTasks.filterByPriority(
                            TaskPriority.high,
                          ),
                          priority: TaskPriority.high,
                          taskProvider: taskProvider,
                        ),
                      ),
                      Expanded(
                        child: _buildQuadrantCard(
                          context: context,
                          title: '重要不紧急',
                          tasks: filteredTasks.filterByPriority(
                            TaskPriority.medium,
                          ),
                          priority: TaskPriority.medium,
                          taskProvider: taskProvider,
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
                          title: '紧急不重要',
                          tasks: filteredTasks.filterByPriority(
                            TaskPriority.low,
                          ),

                          priority: TaskPriority.low,
                          taskProvider: taskProvider,
                        ),
                      ),
                      Expanded(
                        child: _buildQuadrantCard(
                          context: context,
                          title: '不重要不紧急',
                          tasks: filteredTasks.filterByPriority(
                            TaskPriority.none,
                          ),
                          priority: TaskPriority.none,
                          taskProvider: taskProvider,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuadrantCard({
    required BuildContext context,
    required String title,
    required List<Task> tasks,
    required TaskPriority priority,
    required TaskProvider taskProvider,
  }) {
    final activeCount = tasks.where((t) => !t.isDone).length;
    final color = priority.color;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.priority != priority,
      onAcceptWithDetails: (details) async {
        final task = details.data;
        logger.i(
          'Dragged task "${task.name}" to quadrant with priority $priority',
        );
        await taskProvider.execute(UpdatePriority(task, priority));
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
                      onPressed: () => AddTaskBottomSheet.show(
                        context: context,
                        initTask: Task(
                          name: '',
                          isAllDay: true,
                          priority: priority,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0.5),

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
                          final priorityColor = task.priority.color;
                          final cardWidget = Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                // 方框：点击切换完成状态
                                GestureDetector(
                                  key: ValueKey('task_checkbox_${task.name}'),
                                  onTap: () async {
                                    await taskProvider.execute(
                                      UpdateTaskIsDone(task, !task.isDone),
                                    );
                                  },
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: priorityColor,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                      color: task.isDone
                                          ? priorityColor
                                          : Colors.transparent,
                                    ),
                                    child: task.isDone
                                        ? const Icon(
                                            Icons.check,
                                            size: 11,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 任务名：点击进入详情
                                Expanded(
                                  child: GestureDetector(
                                    key: ValueKey('task_name_${task.name}'),
                                    onTap: () =>
                                        TaskDetailPage.show(context, task),
                                    child: Text(
                                      task.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        decoration: task.isDone
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        color: task.isDone
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      builder: (context) => _FourQuadrantsSettingsSheet(provider: provider),
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

  @override
  void initState() {
    super.initState();
    final config = widget.provider.config;
    _hideCompleted = config.quadrantHideCompleted;
  }

  @override
  Widget build(BuildContext context) => Padding(
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
            activeThumbColor: Colors.orange,
            onChanged: (val) {
              setState(() {
                _hideCompleted = val;
              });
              widget.provider.updateQuadrantHideCompleted(val);
            },
          ),
        ],
      ),
    ),
  );
}
