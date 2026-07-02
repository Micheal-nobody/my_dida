import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/checklist/widgets/checklist_selector.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/widgets/add_task/attribute_chips.dart';
import 'package:my_dida/features/tasks/widgets/add_task/checkpoint_list_view.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';
import 'package:provider/provider.dart';

class AddTaskFullScreenContent extends StatelessWidget {
  const AddTaskFullScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AddTaskStateScope.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Consumer<ChecklistProvider>(
          builder: (context, provider, child) {
            return ChecklistSelector(
              items: provider.allCheckLists,
              selectedValue: state.selectedChecklist,
              hintText: state.selectedChecklist?.name ?? '选择清单',
              isDense: true,
              onChanged: state.setSelectedChecklist,
            );
          },
        ),
        actions: [
          PopupMenuButton<TaskPriority>(
            initialValue: state.priority,
            icon: Icon(Icons.flag, color: state.priority.color),
            onSelected: state.setPriority,
            itemBuilder: (context) => const [
              PopupMenuItem(value: TaskPriority.high, child: Text('🔴 高优先级')),
              PopupMenuItem(value: TaskPriority.medium, child: Text('🟠 中优先级')),
              PopupMenuItem(value: TaskPriority.low, child: Text('🔵 低优先级')),
              PopupMenuItem(value: TaskPriority.none, child: Text('⚪ 无优先级')),
            ],
          ),
          IconButton(
            icon: Icon(Icons.check, color: context.theme.primary),
            onPressed: () => state.addTask(context),
            tooltip: '保存任务',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeDisplayRow(context, state),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _buildTextFields(context, state),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: AttributeChips(),
                  ),
                  const SizedBox(height: 8),
                  _buildFullScreenCheckpointsSection(context, state),
                ],
              ),
            ),
          ),
          _buildFullScreenBottomBar(context, state),
        ],
      ),
    );
  }

  Widget _buildTimeDisplayRow(
    BuildContext context,
    AddTaskBottomSheetState state,
  ) => InkWell(
    onTap: () => state.showDateTimePicker(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: context.theme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.getFullDateDisplayText(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.theme.textPrimary,
              ),
            ),
          ),
          if (state.dateTimePickerValue.selectedDate != null)
            IconButton(
              icon: Icon(
                Icons.clear,
                size: 18,
                color: context.theme.unselectedLabelColor,
              ),
              onPressed: state.clearDateTimePicker,
            )
          else
            Icon(
              Icons.chevron_right,
              color: context.theme.unselectedLabelColor,
              size: 20,
            ),
        ],
      ),
    ),
  );

  Widget _buildTextFields(
    BuildContext context,
    AddTaskBottomSheetState state,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: state.textController,
          autofocus: !state.hasInitPreset,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.theme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '准备做点什么？',
            errorText: state.hasError ? '请输入任务名称！' : null,
            errorStyle: TextStyle(color: context.theme.error),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: (val) {
            if (state.hasError && val.isNotEmpty) {
              state.setHasError(false);
            }
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: state.descController,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: TextStyle(fontSize: 16, color: context.theme.textPrimary),
          decoration: const InputDecoration(
            hintText: '描述',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    ),
  );

  Widget _buildFullScreenCheckpointsSection(
    BuildContext context,
    AddTaskBottomSheetState state,
  ) {
    if (state.checkpoints.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 4.0),
          child: Text(
            '检查点',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.theme.unselectedLabelColor,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: CheckpointListView(isFullScreen: true),
        ),
      ],
    );
  }

  Widget _buildFullScreenBottomBar(
    BuildContext context,
    AddTaskBottomSheetState state,
  ) => Container(
    decoration: BoxDecoration(
      color: context.theme.cardBackground,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, -1),
          blurRadius: 4,
        ),
      ],
    ),
    padding: EdgeInsets.only(
      left: 8.0,
      right: 8.0,
      bottom: MediaQuery.of(context).padding.bottom + 8.0,
      top: 8.0,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.label_outline,
                color: state.tags.isNotEmpty
                    ? context.theme.iconColor
                    : context.theme.unselectedLabelColor,
              ),
              onPressed: state.editTags,
              tooltip: '修改标签',
            ),
            IconButton(
              icon: Icon(
                Icons.format_list_bulleted,
                color: state.checkpoints.isNotEmpty
                    ? context.theme.iconColor
                    : context.theme.unselectedLabelColor,
              ),
              onPressed: state.addCheckpoint,
              tooltip: '添加检查点',
            ),
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: context.theme.unselectedLabelColor,
              ),
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('附件功能暂未集成')));
              },
              tooltip: '添加附件',
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.fullscreen_exit,
            color: context.theme.unselectedLabelColor,
          ),
          onPressed: state.cancelFullScreen,
          tooltip: '取消任务展开',
        ),
      ],
    ),
  );
}
