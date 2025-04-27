import 'package:hive/hive.dart';

part 'hole.g.dart';

@HiveType(typeId: 1)
class Hole extends HiveObject {
  @HiveField(0)
  int number;

  @HiveField(1)
  int par;

  @HiveField(2)
  int handicapRating;

  @HiveField(3)
  String name;

  Hole({
    required this.number,
    this.par = 4,
    this.handicapRating = 0,
    this.name = '',
  });
}