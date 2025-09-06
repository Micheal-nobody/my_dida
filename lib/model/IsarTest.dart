import 'package:isar/isar.dart';

/// part 作用是告诉 dart 编译器，运行 flutter pub run build_runner build 后，会自动生成 IsarTest.g.dart 文件
part 'part/IsarTest.g.dart';


/// 这是一个用来测试 isar 数据库的类
@collection
class IsarTest {

  Id id =Isar.autoIncrement; // 自增ID
  String? name;
  int? age;

  IsarTest({
    this.name,
    this.age
  });
}