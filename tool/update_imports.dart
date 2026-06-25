import 'dart:io';

// Exact absolute package paths mappings for anything we moved
final Map<String, String> pathMappings = {
  "package:my_dida/constants/app_constants.dart":
      "package:my_dida/core/constants/app_constants.dart",
  "package:my_dida/constants/colors_constants.dart":
      "package:my_dida/core/constants/colors_constants.dart",
  "package:my_dida/constants/dimension_constants.dart":
      "package:my_dida/core/constants/dimension_constants.dart",
  "package:my_dida/constants/icon_constants.dart":
      "package:my_dida/core/constants/icon_constants.dart",
  "package:my_dida/constants/ui_constants.dart":
      "package:my_dida/core/constants/ui_constants.dart",

  "package:my_dida/config/logger.dart":
      "package:my_dida/core/logger/logger.dart",
  "package:my_dida/config/locator.dart": "package:my_dida/core/di/locator.dart",
  "package:my_dida/router/go_router.dart":
      "package:my_dida/core/router/go_router.dart",
  "package:my_dida/router/shell_scaffold_key.dart":
      "package:my_dida/core/router/shell_scaffold_key.dart",

  "package:my_dida/core/validators/form_validators.dart":
      "package:my_dida/core/validators/form_validators.dart",
  "package:my_dida/core/validators/task_validator.dart":
      "package:my_dida/features/tasks/validators/task_validator.dart",
  "package:my_dida/core/errors/exceptions.dart":
      "package:my_dida/core/errors/exceptions.dart",
  "package:my_dida/core/errors/failures.dart":
      "package:my_dida/core/errors/failures.dart",
  "package:my_dida/core/ui/app_message_service.dart":
      "package:my_dida/core/ui/app_message_service.dart",
  "package:my_dida/core/ui/app_message_type.dart":
      "package:my_dida/core/ui/app_message_type.dart",

  "package:my_dida/utils/PerformanceMonitor.dart":
      "package:my_dida/core/utils/performance_monitor.dart",
  "package:my_dida/utils/RRuleUtil.dart":
      "package:my_dida/core/utils/rrule_util.dart",
  "package:my_dida/utils/TimeUtils.dart":
      "package:my_dida/core/utils/time_utils.dart",
  "package:my_dida/utils/time_formatter.dart":
      "package:my_dida/core/utils/time_formatter.dart",
  "package:my_dida/utils/search_history_manager.dart":
      "package:my_dida/features/tasks/services/search_history_manager.dart",

  "package:my_dida/model/entity/checklist.dart":
      "package:my_dida/features/checklist/models/checklist.dart",
  "package:my_dida/model/entity/checklist.g.dart":
      "package:my_dida/features/checklist/models/checklist.g.dart",
  "package:my_dida/model/vo/checklist_vo.dart":
      "package:my_dida/features/checklist/models/checklist_vo.dart",

  "package:my_dida/model/entity/task.dart":
      "package:my_dida/features/tasks/models/task.dart",
  "package:my_dida/model/entity/task.g.dart":
      "package:my_dida/features/tasks/models/task.g.dart",
  "package:my_dida/model/entity/check_point.dart":
      "package:my_dida/features/tasks/models/check_point.dart",
  "package:my_dida/model/entity/check_point.g.dart":
      "package:my_dida/features/tasks/models/check_point.g.dart",
  "package:my_dida/model/vo/task_reminder_plan.dart":
      "package:my_dida/features/tasks/models/task_reminder_plan.dart",
  "package:my_dida/model/vo/repeat_pattern.dart":
      "package:my_dida/features/tasks/models/repeat_pattern.dart",
  "package:my_dida/model/domain/task_operation.dart":
      "package:my_dida/features/tasks/models/task_operation.dart",

  "package:my_dida/model/entity/habit.dart":
      "package:my_dida/features/habits/models/habit.dart",
  "package:my_dida/model/entity/habit.g.dart":
      "package:my_dida/features/habits/models/habit.g.dart",
  "package:my_dida/model/entity/habit_check_in_record.dart":
      "package:my_dida/features/habits/models/habit_check_in_record.dart",
  "package:my_dida/model/entity/habit_check_in_record.g.dart":
      "package:my_dida/features/habits/models/habit_check_in_record.g.dart",

  "package:my_dida/model/entity/custom_tomato.dart":
      "package:my_dida/features/tomato/models/custom_tomato.dart",
  "package:my_dida/model/entity/custom_tomato.g.dart":
      "package:my_dida/features/tomato/models/custom_tomato.g.dart",
  "package:my_dida/model/entity/tomato_record.dart":
      "package:my_dida/features/tomato/models/tomato_record.dart",
  "package:my_dida/model/entity/tomato_record.g.dart":
      "package:my_dida/features/tomato/models/tomato_record.g.dart",
  "package:my_dida/model/domain/tomato_ticker.dart":
      "package:my_dida/features/tomato/models/tomato_ticker.dart",

  "package:my_dida/model/entity/calendar_page_config.dart":
      "package:my_dida/features/calendar/models/calendar_page_config.dart",
  "package:my_dida/model/entity/calendar_page_config.g.dart":
      "package:my_dida/features/calendar/models/calendar_page_config.g.dart",
  "package:my_dida/model/vo/task_calendar_view_data.dart":
      "package:my_dida/features/calendar/models/task_calendar_view_data.dart",

  "package:my_dida/model/entity/operation.dart":
      "package:my_dida/features/operation_undo/models/operation.dart",
  "package:my_dida/model/entity/operation.g.dart":
      "package:my_dida/features/operation_undo/models/operation.g.dart",

  "package:my_dida/model/entity/sidebar_config.dart":
      "package:my_dida/features/settings/models/sidebar_config.dart",
  "package:my_dida/model/entity/sidebar_config.g.dart":
      "package:my_dida/features/settings/models/sidebar_config.g.dart",

  "package:my_dida/model/entity/base_entity.dart":
      "package:my_dida/shared/models/base_entity.dart",
  "package:my_dida/model/entity/revertible_entity.dart":
      "package:my_dida/shared/models/revertible_entity.dart",

  "package:my_dida/repository/base_repository.dart":
      "package:my_dida/shared/repositories/base_repository.dart",
  "package:my_dida/repository/checklist_repository.dart":
      "package:my_dida/features/checklist/repositories/checklist_repository.dart",
  "package:my_dida/repository/task_repository.dart":
      "package:my_dida/features/tasks/repositories/task_repository.dart",
  "package:my_dida/repository/habit_repository.dart":
      "package:my_dida/features/habits/repositories/habit_repository.dart",
  "package:my_dida/repository/habit_check_in_record_repository.dart":
      "package:my_dida/features/habits/repositories/habit_check_in_record_repository.dart",
  "package:my_dida/repository/tomato_record_repository.dart":
      "package:my_dida/features/tomato/repositories/tomato_record_repository.dart",
  "package:my_dida/repository/custom_tomato_repository.dart":
      "package:my_dida/features/tomato/repositories/custom_tomato_repository.dart",

  "package:my_dida/provider/checklist_provider.dart":
      "package:my_dida/features/checklist/providers/checklist_provider.dart",
  "package:my_dida/provider/task_provider.dart":
      "package:my_dida/features/tasks/providers/task_provider.dart",
  "package:my_dida/provider/habit_provider.dart":
      "package:my_dida/features/habits/providers/habit_provider.dart",
  "package:my_dida/provider/tomato_provider.dart":
      "package:my_dida/features/tomato/providers/tomato_provider.dart",
  "package:my_dida/provider/calendar_page_provider.dart":
      "package:my_dida/features/calendar/providers/calendar_page_provider.dart",
  "package:my_dida/provider/operation_stack_provider.dart":
      "package:my_dida/features/operation_undo/providers/operation_stack_provider.dart",
  "package:my_dida/provider/sidebar_config_provider.dart":
      "package:my_dida/features/settings/providers/sidebar_config_provider.dart",
  "package:my_dida/provider/custom_theme_provider.dart":
      "package:my_dida/features/settings/providers/custom_theme_provider.dart",
  "package:my_dida/provider/ui_status_provider.dart":
      "package:my_dida/features/settings/providers/ui_status_provider.dart",

  "package:my_dida/services/checklist_lifecycle_manager.dart":
      "package:my_dida/features/checklist/services/checklist_lifecycle_manager.dart",
  "package:my_dida/services/task_lifecycle_manager.dart":
      "package:my_dida/features/tasks/services/task_lifecycle_manager.dart",
  "package:my_dida/services/task_reminder_service.dart":
      "package:my_dida/features/tasks/services/task_reminder_service.dart",
  "package:my_dida/services/task_reminder_scheduler_port.dart":
      "package:my_dida/features/tasks/services/task_reminder_scheduler_port.dart",
  "package:my_dida/services/flutter_local_task_reminder_scheduler.dart":
      "package:my_dida/features/tasks/services/flutter_local_task_reminder_scheduler.dart",
  "package:my_dida/services/noop_task_reminder_scheduler.dart":
      "package:my_dida/features/tasks/services/noop_task_reminder_scheduler.dart",
  "package:my_dida/services/notification_service.dart":
      "package:my_dida/features/tasks/services/notification_service.dart",
  "package:my_dida/services/task_notification_navigation_service.dart":
      "package:my_dida/features/tasks/services/task_notification_navigation_service.dart",
  "package:my_dida/services/habit_lifecycle_manager.dart":
      "package:my_dida/features/habits/services/habit_lifecycle_manager.dart",
  "package:my_dida/services/task_calendar_projection_service.dart":
      "package:my_dida/features/calendar/services/task_calendar_projection_service.dart",
  "package:my_dida/services/operation_reverter.dart":
      "package:my_dida/features/operation_undo/services/operation_reverter.dart",

  "package:my_dida/pages/task_page.dart":
      "package:my_dida/features/tasks/pages/task_page.dart",
  "package:my_dida/pages/task_detail_route_page.dart":
      "package:my_dida/features/tasks/pages/task_detail_route_page.dart",
  "package:my_dida/pages/four_quadrants_page.dart":
      "package:my_dida/features/tasks/pages/four_quadrants_page.dart",
  "package:my_dida/pages/search_page.dart":
      "package:my_dida/features/tasks/pages/search_page.dart",
  "package:my_dida/pages/habits_page.dart":
      "package:my_dida/features/habits/pages/habits_page.dart",
  "package:my_dida/pages/habit_archived_page.dart":
      "package:my_dida/features/habits/pages/habit_archived_page.dart",
  "package:my_dida/pages/habit_data_summary_page.dart":
      "package:my_dida/features/habits/pages/habit_data_summary_page.dart",
  "package:my_dida/pages/habit_manage_page.dart":
      "package:my_dida/features/habits/pages/habit_manage_page.dart",
  "package:my_dida/pages/tomato_page.dart":
      "package:my_dida/features/tomato/pages/tomato_page.dart",
  "package:my_dida/pages/tomato_summary_page.dart":
      "package:my_dida/features/tomato/pages/tomato_summary_page.dart",
  "package:my_dida/pages/tomato_timer_full_screen_page.dart":
      "package:my_dida/features/tomato/pages/tomato_timer_full_screen_page.dart",
  "package:my_dida/pages/calendar_page.dart":
      "package:my_dida/features/calendar/pages/calendar_page.dart",
  "package:my_dida/pages/operation_page.dart":
      "package:my_dida/features/operation_undo/pages/operation_page.dart",
  "package:my_dida/pages/settings_page.dart":
      "package:my_dida/features/settings/pages/settings_page.dart",
  "package:my_dida/pages/sidebar_settings_page.dart":
      "package:my_dida/features/settings/pages/sidebar_settings_page.dart",
  "package:my_dida/pages/smart_lists_settings_page.dart":
      "package:my_dida/features/settings/pages/smart_lists_settings_page.dart",

  "package:my_dida/features/todo_page/board_view.dart":
      "package:my_dida/features/tasks/widgets/board_view.dart",
  "package:my_dida/features/todo_page/task_drawer.dart":
      "package:my_dida/features/tasks/widgets/task_drawer.dart",
  "package:my_dida/features/cards/task_card.dart":
      "package:my_dida/features/tasks/widgets/task_card.dart",
  "package:my_dida/features/dialogs/add_task_dialog.dart":
      "package:my_dida/features/tasks/widgets/add_task_dialog.dart",
  "package:my_dida/features/dialogs/associate_main_task_dialog.dart":
      "package:my_dida/features/tasks/widgets/associate_main_task_dialog.dart",
  "package:my_dida/features/task_detail/task_detail_page.dart":
      "package:my_dida/features/tasks/pages/task_detail_page.dart",
  "package:my_dida/features/task_detail/widgets/checkpoint_item_widget.dart":
      "package:my_dida/features/tasks/widgets/task_detail/widgets/checkpoint_item_widget.dart",
  "package:my_dida/features/task_detail/widgets/sub_task_section.dart":
      "package:my_dida/features/tasks/widgets/task_detail/widgets/sub_task_section.dart",
  "package:my_dida/features/task_detail/widgets/task_detail_header.dart":
      "package:my_dida/features/tasks/widgets/task_detail/widgets/task_detail_header.dart",
  "package:my_dida/features/task_detail/widgets/task_time_section.dart":
      "package:my_dida/features/tasks/widgets/task_detail/widgets/task_time_section.dart",
  "package:my_dida/features/pickers/task_date_time_picker.dart":
      "package:my_dida/features/tasks/widgets/task_date_time_picker.dart",
  "package:my_dida/features/cards/habit_card.dart":
      "package:my_dida/features/habits/widgets/habit_card.dart",
  "package:my_dida/features/dialogs/add_habit_dialog.dart":
      "package:my_dida/features/habits/widgets/add_habit_dialog.dart",
  "package:my_dida/features/dialogs/edit_habit_dialog.dart":
      "package:my_dida/features/habits/widgets/edit_habit_dialog.dart",
  "package:my_dida/features/dialogs/habit_check_in_dialog.dart":
      "package:my_dida/features/habits/widgets/habit_check_in_dialog.dart",
  "package:my_dida/features/dialogs/habit_visible_range_dialog.dart":
      "package:my_dida/features/habits/widgets/habit_visible_range_dialog.dart",
  "package:my_dida/features/tomato/widgets/associate_task_dialog.dart":
      "package:my_dida/features/tomato/widgets/associate_task_dialog.dart",
  "package:my_dida/features/tomato/widgets/tomato_charts.dart":
      "package:my_dida/features/tomato/widgets/tomato_charts.dart",
  "package:my_dida/features/calendar_page/calendar_all_day_task_section.dart":
      "package:my_dida/features/calendar/widgets/calendar_all_day_task_section.dart",
  "package:my_dida/features/calendar_page/calendar_entry_builders.dart":
      "package:my_dida/features/calendar/widgets/calendar_entry_builders.dart",
  "package:my_dida/features/calendar_page/calendar_time_task_section.dart":
      "package:my_dida/features/calendar/widgets/calendar_time_task_section.dart",
  "package:my_dida/features/calendar_page/calendar_widgets/calendar_date_header.dart":
      "package:my_dida/features/calendar/widgets/calendar_widgets/calendar_date_header.dart",
  "package:my_dida/features/calendar_page/calendar_widgets/calendar_entry_card.dart":
      "package:my_dida/features/calendar/widgets/calendar_widgets/calendar_entry_card.dart",
  "package:my_dida/features/calendar_page/calendar_widgets/calendar_scrollable_content.dart":
      "package:my_dida/features/calendar/widgets/calendar_widgets/calendar_scrollable_content.dart",
  "package:my_dida/features/calendar_page/calendar_widgets/calendar_task_list_bottom.dart":
      "package:my_dida/features/calendar/widgets/calendar_widgets/calendar_task_list_bottom.dart",
  "package:my_dida/features/calendar_page/calendar_widgets/future_tasks_area.dart":
      "package:my_dida/features/calendar/widgets/calendar_widgets/future_tasks_area.dart",
  "package:my_dida/features/calendar_page/calendar_widgets/virtualized_calendar_time_area.dart":
      "package:my_dida/features/calendar/widgets/calendar_widgets/virtualized_calendar_time_area.dart",
  "package:my_dida/features/dialogs/calendar_visible_range_dialog.dart":
      "package:my_dida/features/calendar/widgets/calendar_visible_range_dialog.dart",
  "package:my_dida/features/operation/operation_habit_renderer.dart":
      "package:my_dida/features/operation_undo/widgets/operation_habit_renderer.dart",
  "package:my_dida/features/operation/operation_task_renderer.dart":
      "package:my_dida/features/operation_undo/widgets/operation_task_renderer.dart",
  "package:my_dida/features/dialogs/sort_and_group_dialog.dart":
      "package:my_dida/features/settings/widgets/sort_and_group_dialog.dart",
  "package:my_dida/features/dialogs/view_changer_dialog.dart":
      "package:my_dida/features/settings/widgets/view_changer_dialog.dart",
  "package:my_dida/features/dialogs/visible_range_dialog.dart":
      "package:my_dida/features/settings/widgets/visible_range_dialog.dart",
  "package:my_dida/features/dialogs/add_checklist_dialog.dart":
      "package:my_dida/features/checklist/widgets/add_checklist_dialog.dart",
  "package:my_dida/shared/widgets/checklist_selector.dart":
      "package:my_dida/features/checklist/widgets/checklist_selector.dart",
  "package:my_dida/shared/widgets/task_schedule_trigger.dart":
      "package:my_dida/features/tasks/widgets/task_schedule_trigger.dart",

  "package:my_dida/shared/common/base_form_dialog.dart":
      "package:my_dida/shared/widgets/base_form_dialog.dart",
  "package:my_dida/shared/common/common_widgets.dart":
      "package:my_dida/shared/widgets/common_widgets.dart",
  "package:my_dida/shared/common/custom_floating_action_button.dart":
      "package:my_dida/shared/widgets/custom_floating_action_button.dart",
  "package:my_dida/shared/common/selection_row.dart":
      "package:my_dida/shared/widgets/selection_row.dart",
};

// Global mapping of file types to domain features
String getFeatureNameForEntity(String entityName) {
  if (entityName == 'task' ||
      entityName == 'check_point' ||
      entityName == 'repeat_pattern' ||
      entityName == 'task_reminder_plan') {
    return 'tasks';
  } else if (entityName == 'habit' || entityName == 'habit_check_in_record') {
    return 'habits';
  } else if (entityName == 'checklist' || entityName == 'checklist_vo') {
    return 'checklist';
  } else if (entityName == 'custom_tomato' ||
      entityName == 'tomato_record' ||
      entityName == 'tomato_ticker') {
    return 'tomato';
  } else if (entityName == 'calendar_page_config' ||
      entityName == 'task_calendar_view_data') {
    return 'calendar';
  } else if (entityName == 'operation') {
    return 'operation_undo';
  } else if (entityName == 'sidebar_config') {
    return 'settings';
  }
  return '';
}

// Map dynamic paths of files based on their type
String mapOldPackagePath(String pkgPath) {
  if (pathMappings.containsKey(pkgPath)) {
    return pathMappings[pkgPath]!;
  }

  // Handle entity / VO / Domain sub-paths dynamic mapping
  final entityRegex = RegExp(
    r"package:my_dida/model/entity/([a-zA-Z_0-9]+)\.(dart|g\.dart)",
  );
  if (entityRegex.hasMatch(pkgPath)) {
    final match = entityRegex.firstMatch(pkgPath)!;
    String entityName = match.group(1)!;
    String ext = match.group(2)!;
    String featureName = getFeatureNameForEntity(entityName);
    if (featureName.isNotEmpty) {
      return "package:my_dida/features/$featureName/models/$entityName.$ext";
    }
  }

  final voRegex = RegExp(r"package:my_dida/model/vo/([a-zA-Z_0-9]+)\.dart");
  if (voRegex.hasMatch(pkgPath)) {
    final match = voRegex.firstMatch(pkgPath)!;
    String entityName = match.group(1)!;
    String featureName = getFeatureNameForEntity(entityName);
    if (featureName.isNotEmpty) {
      return "package:my_dida/features/$featureName/models/$entityName.dart";
    }
  }

  final domainRegex = RegExp(
    r"package:my_dida/model/domain/([a-zA-Z_0-9]+)\.dart",
  );
  if (domainRegex.hasMatch(pkgPath)) {
    final match = domainRegex.firstMatch(pkgPath)!;
    String entityName = match.group(1)!;
    String featureName = getFeatureNameForEntity(entityName);
    if (featureName.isNotEmpty) {
      return "package:my_dida/features/$featureName/models/$entityName.dart";
    }
  }

  final repoRegex = RegExp(r"package:my_dida/repository/([a-zA-Z_0-9]+)\.dart");
  if (repoRegex.hasMatch(pkgPath)) {
    final match = repoRegex.firstMatch(pkgPath)!;
    String repoName = match.group(1)!;
    if (repoName == 'base_repository') {
      return "package:my_dida/shared/repositories/base_repository.dart";
    }
    String entityName = repoName
        .replaceAll("repository", "")
        .replaceAll("_", "");
    String featureName = getFeatureNameForEntity(entityName);
    if (featureName.isNotEmpty) {
      return "package:my_dida/features/$featureName/repositories/$repoName.dart";
    }
  }

  final serviceRegex = RegExp(
    r"package:my_dida/services/([a-zA-Z_0-9]+)\.dart",
  );
  if (serviceRegex.hasMatch(pkgPath)) {
    final match = serviceRegex.firstMatch(pkgPath)!;
    String sName = match.group(1)!;
    String featureName = "";
    if (sName.startsWith("checklist"))
      featureName = "checklist";
    else if (sName.startsWith("task") ||
        sName.startsWith("flutter_local") ||
        sName.startsWith("noop") ||
        sName.startsWith("notification"))
      featureName = "tasks";
    else if (sName.startsWith("habit"))
      featureName = "habits";
    else if (sName.startsWith("operation"))
      featureName = "operation_undo";
    else if (sName.contains("projection"))
      featureName = "calendar";
    if (featureName.isNotEmpty) {
      return "package:my_dida/features/$featureName/services/$sName.dart";
    }
  }

  final providerRegex = RegExp(
    r"package:my_dida/provider/([a-zA-Z_0-9]+)\.dart",
  );
  if (providerRegex.hasMatch(pkgPath)) {
    final match = providerRegex.firstMatch(pkgPath)!;
    String pName = match.group(1)!;
    String featureName = "";
    if (pName.contains("checklist"))
      featureName = "checklist";
    else if (pName.contains("task"))
      featureName = "tasks";
    else if (pName.contains("habit"))
      featureName = "habits";
    else if (pName.contains("tomato"))
      featureName = "tomato";
    else if (pName.contains("calendar"))
      featureName = "calendar";
    else if (pName.contains("operation"))
      featureName = "operation_undo";
    else if (pName.contains("sidebar") ||
        pName.contains("theme") ||
        pName.contains("ui_status"))
      featureName = "settings";
    if (featureName.isNotEmpty) {
      return "package:my_dida/features/$featureName/providers/$pName.dart";
    }
  }

  return pkgPath;
}

// Custom normalize resolver
String resolveRelativePath(String currentFilePath, String relativeImport) {
  currentFilePath = currentFilePath.replaceAll('\\', '/');
  relativeImport = relativeImport.replaceAll('\\', '/');

  List<String> parts = currentFilePath.split('/');
  parts.removeLast(); // Remove filename to leave only directories

  List<String> relParts = relativeImport.split('/');
  for (String part in relParts) {
    if (part == '.' || part == '') {
      continue;
    } else if (part == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(part);
    }
  }

  // Convert "lib/..." to package import
  if (parts.isNotEmpty && parts[0] == 'lib') {
    parts[0] = 'package:my_dida';
  }
  return parts.join('/');
}

// Build new-to-old dictionary from git status --porcelain
Map<String, String> buildNewToOldMap() {
  final Map<String, String> map = {};

  final result = Process.runSync('git', ['status', '--porcelain']);
  if (result.exitCode == 0) {
    final lines = (result.stdout as String).split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('R ')) {
        final pathsPart = line.substring(2).trim();
        final arrowIndex = pathsPart.indexOf('->');
        if (arrowIndex != -1) {
          String oldPath = pathsPart.substring(0, arrowIndex).trim();
          String newPath = pathsPart.substring(arrowIndex + 2).trim();

          if (oldPath.startsWith('"') && oldPath.endsWith('"')) {
            oldPath = oldPath.substring(1, oldPath.length - 1);
          }
          if (newPath.startsWith('"') && newPath.endsWith('"')) {
            newPath = newPath.substring(1, newPath.length - 1);
          }

          oldPath = oldPath.replaceAll('\\', '/');
          newPath = newPath.replaceAll('\\', '/');

          map[newPath] = oldPath;
        }
      }
    }
  }

  // Manual mappings for build_runner files which are not tracked by git
  map['lib/features/checklist/models/checklist.g.dart'] =
      'lib/model/entity/checklist.g.dart';
  map['lib/features/tasks/models/task.g.dart'] = 'lib/model/entity/task.g.dart';
  map['lib/features/tasks/models/check_point.g.dart'] =
      'lib/model/entity/check_point.g.dart';
  map['lib/features/habits/models/habit.g.dart'] =
      'lib/model/entity/habit.g.dart';
  map['lib/features/habits/models/habit_check_in_record.g.dart'] =
      'lib/model/entity/habit_check_in_record.g.dart';
  map['lib/features/tomato/models/custom_tomato.g.dart'] =
      'lib/model/entity/custom_tomato.g.dart';
  map['lib/features/tomato/models/tomato_record.g.dart'] =
      'lib/model/entity/tomato_record.g.dart';
  map['lib/features/calendar/models/calendar_page_config.g.dart'] =
      'lib/model/entity/calendar_page_config.g.dart';
  map['lib/features/operation_undo/models/operation.g.dart'] =
      'lib/model/entity/operation.g.dart';
  map['lib/features/settings/models/sidebar_config.g.dart'] =
      'lib/model/entity/sidebar_config.g.dart';

  return map;
}

void processDirectory(Directory dir, Map<String, String> newToOldMap) {
  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final file = entity;
      final fileNormPath = file.path.replaceAll('\\', '/');

      final originalFilePath = newToOldMap[fileNormPath] ?? fileNormPath;

      String content = file.readAsStringSync();
      String originalContent = content;
      int fileReplacements = 0;

      // 1. Replace all relative imports (including those not starting with dot, but having no colon)
      // We look for: import 'path/to/file.dart'; without colon, i.e., relative or lib-relative
      // e.g. import 'config/locator.dart'; or import '../config/locator.dart';
      final importRegex = RegExp(
        r"import\s+[\x27\x22]([^\x27\x22]+)[\x27\x22];",
      );
      if (importRegex.hasMatch(content)) {
        content = content.replaceAllMapped(importRegex, (match) {
          String path = match.group(1)!;
          if (path.contains(':')) {
            // It is an absolute package or dart import, skip here
            return match.group(0)!;
          }

          // It is a relative path. Let's make sure if it doesn't start with '.',
          // but points to lib-relative folders (e.g. 'config/locator.dart'), we treat it
          // as relative to 'lib/'. Otherwise we resolve relative to the original file's folder.
          String relPath = path;
          String baseFilePath = originalFilePath;
          if (!path.startsWith('.')) {
            // E.g. 'config/locator.dart' -> resolve relative to 'lib/' folder
            baseFilePath = 'lib/dummy.dart';
          }

          // Resolve and immediately translate it to the new refactored package path
          String absPkgPath = mapOldPackagePath(
            resolveRelativePath(baseFilePath, relPath),
          );
          fileReplacements++;
          return "import '$absPkgPath';";
        });
      }

      // 2. Next, apply mappings on absolute package:my_dida imports (just in case they weren't caught)
      final packageImportRegex = RegExp(
        r"import\s+[\x27\x22](package:my_dida/[^\x27\x22]+)[\x27\x22];",
      );
      if (packageImportRegex.hasMatch(content)) {
        content = content.replaceAllMapped(packageImportRegex, (match) {
          String pkgPath = match.group(1)!;
          String mappedPkgPath = mapOldPackagePath(pkgPath);
          if (mappedPkgPath != pkgPath) {
            fileReplacements++;
            return "import '$mappedPkgPath';";
          }
          return match.group(0)!;
        });
      }

      if (content != originalContent) {
        file.writeAsStringSync(content);
        print('Updated: ${file.path} ($fileReplacements replacements)');
      }
    }
  });
}

void main() {
  final newToOldMap = buildNewToOldMap();
  print(
    'Loaded ${newToOldMap.length} moved files from git status rename info.',
  );

  processDirectory(Directory('lib'), newToOldMap);
  processDirectory(Directory('test'), newToOldMap);
  print('Smart import update completed.');
}
