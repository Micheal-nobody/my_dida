import 'package:isar_community/isar.dart';
import 'package:my_dida/model/entity/base_entity.dart';

part 'custom_tomato.g.dart';

@Collection()
class CustomTomato extends BaseEntity {
  CustomTomato({
    required this.name,
    required this.focusMinutes,
  });

  @Index(unique: true)
  String name;

  int focusMinutes;

  @override
  String toString() =>
      'CustomTomato{id: $id, name: $name, focusMinutes: $focusMinutes}';
}
