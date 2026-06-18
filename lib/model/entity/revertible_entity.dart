import 'package:my_dida/model/entity/base_entity.dart';

abstract class RevertibleEntity extends BaseEntity {
  Map<String, dynamic> toJson();
}
