# Plan - Implement Universal Task Creation Module (create_task)

## Context
The goal is to implement a universal task creation module based on the design images and requirements described in E:\code\AndroidApp\my_dida\docs\create_task\PRD.md.
This module will serve as the single entrance for task creation across the entire application (including task views, calendar views, priority quadrants, subtask detail additions, etc.).
Key constraints:
1. It must directly use CustomDatePickerDialog for date selection (located at lib/shared/widgets/datetime/custom_date_picker_dialog.dart), without displaying quick shortcuts such as "今天", "明天", "后天", "周末".
2. Pre-filling task attributes (priority, checklist, start/end dates, parentTask, tags) must be fully supported.
3. The UI will support three states: Quick Add Bottom Sheet (collapsed state), Expanded Bottom Sheet (showing note description and checkpoints), and Full Page Task Editor (scaffold route).

---

## Proposed Changes

### 1. Refactor AddTaskDialog (`lib/features/dialogs/add_task_dialog.dart`)
- **Visual States Configuration**: Add a state variable `_visualState` with values: `'quick'` (collapsed bottom sheet), `'expanded'` (bottom sheet showing notes and checkpoints), and `'fullScreen'` (renders a full Scaffold page layout).
- **Initialization**: Read `presetTask` and `parentTask` parameters, pre-filling state variables:
  - `_nameController`, `_descriptionController`
  - `_startTime`, `_endTime`, `_isAllDay`, `_rrule`
  - `_notificationEnabled`, `_reminderOffsetMinutes`
  - `_priority`, `_tags`, `_checkpoints`, `_selectedChecklist`, `_parentTaskId`
- **Component Layouts**:
  - **Quick Add**: Text field for task title, a checklist selector widget, and a bottom icon toolbar.
  - **Expanded**: Adds notes textarea and checkpoints list view below the title.
  - **Full Page Editor**: Pushes as a separate route if requested or when fullscreen button is clicked. It will contain an AppBar (Cancel and Save buttons) and clean ListTiles/cards for each task attribute.
- **Controls**:
  - **Date Picker**: Tap date icon to show `CustomDatePickerDialog` directly. No quick date shortcuts will be displayed.
  - **Priority Popup Menu**: Inline button showing flag icon, opening a popup menu to choose `TaskPriority`.
  - **Tags Dialog**: Dialog with a comma-separated text field to input/edit tags.
  - **Reminder/Repeat Popup**: Configures recurrence (RRule via CustomRepeatPicker) and notification offset minutes.
  - **Checkpoints Builder**: Renders interactive checkpoints with checkbox toggles, text edits, and delete/add buttons.

### 2. Update Task Lifecycle Manager (`lib/services/task_lifecycle_manager.dart`)
- Enhance the task creation process to ensure `priority`, `tags`, and `checkpoints` are parsed and saved to the Isar DB repository when `addTask` is invoked.

---

## Verification Plan

### End-to-End Visual & Feature Verification
1. Run `flutter run` to launch the application.
2. Verify task creation from the home floating action button (Quick Add Bottom Sheet):
   - Confirm layout contains input box and toolbar.
   - Verify tapping calendar icon opens `CustomDatePickerDialog` directly with no quick shortcuts.
   - Verify tapping flag icon opens priority popup menu.
   - Verify toggling expand button shows description and checkpoint list.
   - Verify tapping fullscreen icon closes sheet and opens full editor page.
3. Verify pre-filling attributes by creating tasks from the Four Quadrants Page and Board View:
   - Confirm quadrant task creation pre-fills matching priority.
   - Confirm board view task creation pre-fills column-matching priority/checklist/date.
   - Confirm adding subtask in Task Details View pre-fills `parentTaskId` and inherits checklist.
4. Run `flutter test` to verify no regressions in existing task creation tests.
