import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/revertible_entity.dart';

part 'checklist.g.dart';

/// 任务所属的家庭
@Collection()
class Checklist extends RevertibleEntity {
  // 任务列表中的任务

  Checklist({required this.name, this.colorValue = 0xFFFF9800});

  @Index()
  String name;
  int colorValue; // 任务列表的颜色

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
      };

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
    )..id = json['id'] as int;
  }
}
