import 'package:hive/hive.dart';

part 'goal.g.dart';

@HiveType(typeId: 100)
class Goal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.text,
    required this.createdAt,
  });
}
