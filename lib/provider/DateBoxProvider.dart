import 'package:flutter/cupertino.dart';
import 'package:my_dida/provider/TaskProvider.dart';

import '../config/locator.dart';
import '../repository/TaskRepository.dart';

//TODO: CalenderPage 用的 Provider
class DateBoxProvider extends ChangeNotifier {
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  final TaskRepository _taskRepository;
  DateBoxProvider() : _taskRepository = locator<TaskRepository>();

  /// 根据时间点获取任务


}
