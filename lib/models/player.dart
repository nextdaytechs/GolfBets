import 'package:hive/hive.dart';

part 'player.g.dart';

@HiveType(typeId: 0)
class Player extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int handicap; // Changed to int, non-nullable

  Player({required this.name, this.handicap = 0});
}
