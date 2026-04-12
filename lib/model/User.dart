// import 'package:isar_community/isar.dart';

// @collection
import 'package:isar_community/isar.dart';


part 'User.g.dart';

@Collection()
class User {
  Id id = Isar.autoIncrement; // 你也可以用 id = null 来表示 id 是自增的

  String? name;
  int? age;
}
