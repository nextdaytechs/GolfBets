import 'package:hive/hive.dart';

part 'score_entry.g.dart';

@HiveType(typeId: 2)
class ScoreEntry extends HiveObject {
  @HiveField(0)
  String playerName;

  @HiveField(1)
  int holeNumber;

  @HiveField(2)
  int relativeScore;

  ScoreEntry({
    required this.playerName,
    required this.holeNumber,
    this.relativeScore = 0,
  });
}

