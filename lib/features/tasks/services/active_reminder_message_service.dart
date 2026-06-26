import 'dart:async';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/router/go_router.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/services/active_reminder_manager.dart';
import 'package:my_dida/features/tasks/widgets/task_remind_dialog.dart';

class ActiveReminderMessageService {
  ActiveReminderMessageService({ActiveReminderManager? reminderManager})
    : _reminderManager = reminderManager ?? getIt<ActiveReminderManager>();

  final ActiveReminderManager _reminderManager;
  StreamSubscription<Task>? _subscription;

  /// 显式的初始化方法，在依赖注入配置完毕后手动调用
  void initialize() {
    _subscription?.cancel();
    _subscription = _reminderManager.activeTriggers.listen((task) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        TaskRemindDialog.show(context, task);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
