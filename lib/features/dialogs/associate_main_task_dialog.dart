import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

class AssociateMainTaskDialog extends StatefulWidget {
  const AssociateMainTaskDialog({required this.currentTask, super.key});

  final Task currentTask;

  @override
  State<AssociateMainTaskDialog> createState() =>
      _AssociateMainTaskDialogState();

  static void show(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AssociateMainTaskDialog(currentTask: task),
    );
  }
}

class _AssociateMainTaskDialogState extends State<AssociateMainTaskDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Task> _tasks = [];
  Task? _selectedTask;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentTasks() async {
    setState(() {
      _isLoading = true;
    });

    final taskProvider = context.read<TaskProvider>();
    final tasks = await taskProvider.searchIncompleteTasks('');

    setState(() {
      _tasks = tasks.where((task) => task.id != widget.currentTask.id).toList();
      _isLoading = false;
    });
  }

  Future<void> _searchTasks(String query) async {
    setState(() {
      _isLoading = true;
    });

    final taskProvider = context.read<TaskProvider>();
    final tasks = await taskProvider.searchIncompleteTasks(query);

    setState(() {
      _tasks = tasks.where((task) => task.id != widget.currentTask.id).toList();
      _isLoading = false;
    });
  }

  void _selectTask(Task task) {
    setState(() {
      _selectedTask = _selectedTask?.id == task.id ? null : task;
    });
  }

  Future<void> _confirmAssociation() async {
    if (_selectedTask == null) return;

    final taskProvider = context.read<TaskProvider>();
    await taskProvider.associateMainTask(widget.currentTask, _selectedTask!);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Search Box
          _buildSearchBox(),

          // Task List
          Expanded(child: _buildTaskList()),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
    ),
    child: Row(
      children: [
        // 退出按钮
        IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),

        // 标题
        const Expanded(
          child: Text(
            '关联主任务',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        // 确认按钮
        IconButton(
          icon: Icon(
            Icons.check,
            color: _selectedTask != null ? Colors.orange : Colors.grey,
          ),
          onPressed: _selectedTask != null ? _confirmAssociation : null,
        ),
      ],
    ),
  );

  Widget _buildSearchBox() => Container(
    padding: const EdgeInsets.all(16),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索任务...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
      onChanged: _searchTasks,
    ),
  );

  Widget _buildTaskList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Text(
          '没有找到任务',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isSelected = _selectedTask?.id == task.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.orange : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.orange : Colors.grey,
              ),
              onPressed: () => _selectTask(task),
            ),
            title: Text(
              task.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.orange : Colors.black,
              ),
            ),
            subtitle: task.startTime != null
                ? Text(
                    _formatDateTime(task.startTime!),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.orange.shade700
                          : Colors.grey.shade600,
                    ),
                  )
                : null,
            onTap: () => _selectTask(task),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) =>
      "${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
}
