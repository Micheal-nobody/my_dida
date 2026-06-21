import 'package:my_dida/shared/models/base_entity.dart';

abstract class RevertibleEntity extends BaseEntity {
  Map<String, dynamic> toJson();
}
