import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/model/entity/CheckPoint.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:my_dida/provider/BelongingBoxProvider.dart';

// 任务详情 BottomSheet（由 TaskCard 的 onTap 触发）
class TaskDetailPage extends StatefulWidget {
  final int taskId;
  final ScrollController? scrollController;

  const TaskDetailPage(this.taskId, {super.key, this.scrollController});

  @override
  State<StatefulWidget> createState() {
    return _TaskDetailPageState();
  }
}

//TODO：修复以下bug：原地修改任务名、检查点内容时，键盘弹出于是该组件自动刷新，导致无法输入任何文字（因为widget刷新后键盘会落下）
class _TaskDetailPageState extends State<TaskDetailPage> {
  late TaskProvider _taskProvider;
  Task? _currentTask;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Map<int, TextEditingController> _checkpointControllers = {};
  final Map<int, bool> _checkpointEditingStates = {};
  bool _isEditingTitle = false;
  bool _isEditingDescription = false;

  @override
  void initState() {
    super.initState();
    _taskProvider = Provider.of<TaskProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _checkpointControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildHeader(Task task) {
    final DateTime now = DateTime.now();
    final String dateText = "今天, ${now.month}月${now.day}日";
    final boxes = context.read<BelongingBoxProvider>().all_belongingBoxes;

    // 检查是否可以返回（有调用栈）
    final bool canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              canPop ? Icons.arrow_back : Icons.close,
              color: Colors.orange,
            ),
            onPressed: () {
              if (canPop) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
          const Icon(Icons.event_note, color: Colors.orange),
          const SizedBox(width: 6),
          Text(
            dateText,
            style: const TextStyle(color: Colors.orange, fontSize: 14),
          ),
          const Spacer(),
          DropdownButton<int?>(
            value: task.belongingBoxId,
            underline: const SizedBox.shrink(),
            items: [
              for (final b in boxes)
                DropdownMenuItem<int?>(value: b.id, child: Text(b.name)),
            ],
            onChanged: (v) async {
              await _taskProvider.updateBelongingBox(task, v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(Task task) {
    // 更新控制器文本，如果任务发生变化且不在编辑状态
    if (_currentTask?.id != task.id ||
        (!_isEditingTitle && _titleController.text != task.name)) {
      _titleController.text = task.name;
      _currentTask = task;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _titleController,
        decoration: const InputDecoration(border: InputBorder.none),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
          decoration: TextDecoration.underline,
        ),
        onTap: () {
          if (!_isEditingTitle) {
            setState(() {
              _isEditingTitle = true;
            });
          }
        },
        onSubmitted: (v) async {
          final value = v.trim();
          if (value.isNotEmpty && value != task.name) {
            await _taskProvider.updateTitle(task, value);
          }
          setState(() {
            _isEditingTitle = false;
          });
        },
        onEditingComplete: () {
          setState(() {
            _isEditingTitle = false;
          });
        },
      ),
    );
  }

  Widget _buildDescription(Task task) {
    // 更新控制器文本，如果任务发生变化且不在编辑状态
    if (_currentTask?.id != task.id ||
        (!_isEditingDescription &&
            _descriptionController.text != task.description)) {
      _descriptionController.text = task.description;
      _currentTask = task;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _descriptionController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '添加备注...',
                border: InputBorder.none,
              ),
              onTap: () {
                if (!_isEditingDescription) {
                  setState(() {
                    _isEditingDescription = true;
                  });
                }
              },
              onSubmitted: (v) async {
                await _taskProvider.updateDescription(task, v.trim());
                setState(() {
                  _isEditingDescription = false;
                });
              },
              onEditingComplete: () {
                setState(() {
                  _isEditingDescription = false;
                });
              },
            ),
          ),
          if (task.description.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black38),
              onPressed: () async {
                await _taskProvider.updateDescription(task, '');
                _descriptionController.clear();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCheckpoints(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.checkpoints.isEmpty) const SizedBox.shrink(),

        // 含义：遍历任务的检查点，并显示在列表中（未完成在前，完成在后，完成项半透明）
        for (final entry in ([
          ...task.checkpoints.where((e) => !e.isDone),
          ...task.checkpoints.where((e) => e.isDone),
        ]).asMap().entries)
          _buildCheckpointItem(task, entry.key, entry.value),
      ],
    );
  }

  Widget _buildCheckpointItem(Task task, int index, CheckPoint checkpoint) {
    // 为每个检查点创建或获取控制器
    if (!_checkpointControllers.containsKey(index)) {
      _checkpointControllers[index] = TextEditingController(
        text: checkpoint.name,
      );
      _checkpointEditingStates[index] = false;
    }

    final controller = _checkpointControllers[index]!;
    final isEditing = _checkpointEditingStates[index] ?? false;

    // 更新控制器文本，如果检查点发生变化且不在编辑状态
    if (!isEditing && controller.text != checkpoint.name) {
      controller.text = checkpoint.name;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Checkbox(
          value: checkpoint.isDone,
          onChanged: (v) {
            if (v == null) return;
            _taskProvider.toggleCheckpoint(task, index, v);
          },
        ),
        title: isEditing
            ? TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  color: checkpoint.isDone ? Colors.black38 : null,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (value) async {
                  final trimmedValue = value.trim();
                  if (trimmedValue.isNotEmpty &&
                      trimmedValue != checkpoint.name) {
                    await _taskProvider.renameCheckpoint(
                      task,
                      index,
                      trimmedValue,
                    );
                  }
                  setState(() {
                    _checkpointEditingStates[index] = false;
                  });
                },
                onEditingComplete: () {
                  setState(() {
                    _checkpointEditingStates[index] = false;
                  });
                },
              )
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _checkpointEditingStates[index] = true;
                  });
                },
                child: Text(
                  checkpoint.name,
                  style: TextStyle(
                    color: checkpoint.isDone ? Colors.black38 : null,
                  ),
                ),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            // 清理控制器
            _checkpointControllers[index]?.dispose();
            _checkpointControllers.remove(index);
            _checkpointEditingStates.remove(index);
            await _taskProvider.removeCheckpoint(task, index);
          },
        ),
      ),
    );
  }

  Widget _buildSubTaskSection(Task task) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2E8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              FutureBuilder<List<Task>>(
                future: _taskProvider.getTasksByIds(task.subTaskIds),
                builder: (context, snapshot) {
                  final List<Task> subs = snapshot.data ?? [];
                  if (subs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      for (final st in subs)
                        ListTile(
                          leading: Checkbox(
                            value: st.isDone,
                            onChanged: (v) async {
                              if (v == null) return;
                              await _taskProvider.updateTaskIsDone(st, v);
                            },
                          ),
                          title: GestureDetector(
                            onTap: () {
                              _navigateToSubTask(st.id);
                            },
                            child: Text(st.name),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await _taskProvider.deleteSubTask(task, st.id);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSubTask(int subTaskId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(subTaskId),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<Task?>(
        stream: _taskProvider.watchTaskById(widget.taskId),
        builder: (context, snapshot) {
          final Task? task = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting ||
              task == null) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          // 更新当前任务引用
          _currentTask = task;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(task),
                      const SizedBox(height: 6),
                      _buildTitle(task),
                      const SizedBox(height: 8),
                      _buildDescription(task),
                      _buildCheckpoints(task),
                      const SizedBox(height: 10),
                      _buildSubTaskSection(task),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // 底部按钮栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await _taskProvider.addCheckpoint(task);
                      },
                      icon: const Icon(Icons.checklist, color: Colors.orange),
                      label: const Text(
                        '新检查点',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await _taskProvider.createSubTask(task);
                      },
                      icon: const Icon(
                        Icons.subdirectory_arrow_right,
                        color: Colors.orange,
                      ),
                      label: const Text(
                        '新子任务',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
