import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar_community/isar.dart';

part 'checklist_vo.freezed.dart';

/// 任务所属的家庭
@freezed
abstract class ChecklistVO with _$ChecklistVO {
  const factory ChecklistVO({
    required Id id,
    required String name,
    @Default(Color(0xFF000000)) Color color,
  }) = _ChecklistVO;

  const ChecklistVO._(); // 为自定义 getter 提供私有构造函数

  bool get isSmartList => id < 0;

  bool get isToday => id == -1;

  bool get isTomorrow => id == -2;

  bool get isNextSevenDays => id == -3;

  bool get isAll => id == -4;

  bool get isCompleted => id == -5;

  bool get isTrash => id == -6;

  bool get isInbox => id == 1;
}
