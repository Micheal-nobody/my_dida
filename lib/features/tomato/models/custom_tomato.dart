import 'package:isar_community/isar.dart';
import 'package:my_dida/shared/models/revertible_entity.dart';

part 'custom_tomato.g.dart';

@Collection()
class CustomTomato extends RevertibleEntity {
  CustomTomato({required this.name, required this.focusMinutes});

  @Index(unique: true)
  String name;

  int focusMinutes;

  @override
  String toString() =>
      'CustomTomato{id: $id, name: $name, focusMinutes: $focusMinutes}';

  factory CustomTomato.fromJson(Map<String, dynamic> json) {
    final tomato = CustomTomato(
      name: json['name'] as String,
      focusMinutes: json['focusMinutes'] as int,
    );
    if (json['id'] != null) {
      tomato.id = json['id'] as int;
    }
    return tomato;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id == Isar.autoIncrement ? null : id,
    'name': name,
    'focusMinutes': focusMinutes,
  };

  @override
  String get displayName => name;
}
