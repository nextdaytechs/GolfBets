import 'package:flutter/material.dart';
import '../../models/score_entry.dart';

class NassauGameScreen extends StatelessWidget {
  final List<ScoreEntry> scores;
  final List<String> selectedPlayers;
  final int front9Bet;
  final int back9Bet;
  final int overallBet;
  final Map<String, int> handicaps;
  final int skinsPoints;
  final bool enableSkins;

  const NassauGameScreen({
    super.key,
    required this.scores,
    required this.selectedPlayers,
    required this.front9Bet,
    required this.back9Bet,
    required this.overallBet,
    required this.handicaps,
    required this.skinsPoints,
    required this.enableSkins,
  });

  @override
  Widget build(BuildContext context) {
    print('NassauGameScreen: Building with ${selectedPlayers.length} players, ${scores.length} scores');
    final filteredScores = scores.where((s) => selectedPlayers.contains(s.playerName)).toList();
    print('NassauGameScreen: Filtered scores: ${filteredScores.length}');
    final front9Scores = filteredScores.where((s) => s.holeNumber <= 9).toList();
    final back9Scores = filteredScores.where((s) => s.holeNumber > 9 && s.holeNumber <= 18).toList();
    final front9HolesPlayed = front9Scores.map((s) => s.holeNumber).toSet().length;
    final back9HolesPlayed = back9Scores.map((s) => s.holeNumber).toSet().length;
    final totalHolesPlayed = filteredScores.map((s) => s.holeNumber).toSet().length;
    print('NassauGameScreen: Front 9 holes played: $front9HolesPlayed, Back 9: $back9HolesPlayed, Total: $totalHolesPlayed');

    Map<String, int> front9Totals = {};
    Map<String, int> back9Totals = {};
    Map<String, int> overallTotals = {};
    Map<String, int> front9RawScores = {};
    Map<String, int> back9RawScores = {};
    Map<String, int> overallRawScores = {};
    Map<String, int> skinsTotals = {};
    Map<String, List<int>> front9SkinsHoles = {};
    Map<String, List<int>> back9SkinsHoles = {};

    // Initialize maps for Skins holes
    for (var player in selectedPlayers) {
      front9SkinsHoles[player] = [];
      back9SkinsHoles[player] = [];
    }

    // Calculate handicap distribution
    Map<String, int> front9Strokes = {};
    Map<String, int> back9Strokes = {};
    for (var player in selectedPlayers) {
      int totalHandicap = handicaps[player] ?? 0;
      int front9Allocation;
      int back9Allocation;
      if (totalHandicap >= 0) {
        // Positive or zero handicaps
        if (totalHandicap.isOdd) {
          int base = totalHandicap ~/ 2;
          front9Allocation = base + (totalHandicap % 2);
          back9Allocation = base;
        } else {
          front9Allocation = totalHandicap ~/ 2;
          back9Allocation = totalHandicap ~/ 2;
        }
      } else {
        // Negative handicaps
        int absHandicap = totalHandicap.abs();
        if (absHandicap.isOdd) {
          int base = absHandicap ~/ 2;
          front9Allocation = -(base + (absHandicap % 2));
          back9Allocation = -base;
        } else {
          front9Allocation = -(absHandicap ~/ 2);
          back9Allocation = -(absHandicap ~/ 2);
        }
      }
      front9Strokes[player] = front9Allocation;
      back9Strokes[player] = back9Allocation;
      skinsTotals[player] = 0;
      print('NassauGameScreen: $player - Handicap: $totalHandicap, Front 9 strokes: $front9Allocation, Back 9 strokes: $back9Allocation');
    }

    // Calculate total scores for each segment
    for (var player in selectedPlayers) {
      int front9Score = front9Scores
          .where((s) => s.playerName == player)
          .fold(0, (sum, s) => sum + s.relativeScore);
      front9RawScores[player] = front9Score;
      front9Totals[player] = front9Score - front9Strokes[player]!;
      print('NassauGameScreen: $player - Front 9 raw: $front9Score, adjusted: ${front9Totals[player]}');

      int back9Score = back9Scores
          .where((s) => s.playerName == player)
          .fold(0, (sum, s) => sum + s.relativeScore);
      back9RawScores[player] = back9Score;
      back9Totals[player] = back9Score - back9Strokes[player]!;
      print('NassauGameScreen: $player - Back 9 raw: $back9Score, adjusted: ${back9Totals[player]}');

      int overallScore = filteredScores
          .where((s) => s.playerName == player)
          .fold(0, (sum, s) => sum + s.relativeScore);
      overallRawScores[player] = overallScore;
      overallTotals[player] = overallScore - (handicaps[player] ?? 0);
      print('NassauGameScreen: $player - Overall raw: $overallScore, adjusted: ${overallTotals[player]}');
    }

    // Skins Calculation (per-hole, with handicap adjustments)
    if (enableSkins) {
      for (var hole = 1; hole <= 18; hole++) {
        var holeScores = filteredScores.where((s) => s.holeNumber == hole).toList();
        if (holeScores.isEmpty) continue;

        var adjustedScores = holeScores.map((s) {
          int strokes = hole <= 9 ? front9Strokes[s.playerName]! : back9Strokes[s.playerName]!;
          int maxHole = hole <= 9 ? strokes : 9 + strokes;
          int adjustedScore = s.relativeScore - (strokes > 0 && hole <= maxHole ? 1 : 0);
          return MapEntry(s.playerName, adjustedScore);
        }).toList();

        var minScore = adjustedScores.map((e) => e.value).reduce((a, b) => a < b ? a : b);
        var winners = adjustedScores.where((e) => e.value == minScore).map((e) => e.key).toList();

        if (winners.length == 1) {
          skinsTotals[winners[0]] = (skinsTotals[winners[0]] ?? 0) + skinsPoints;
          if (hole <= 9) {
            front9SkinsHoles[winners[0]]!.add(hole);
          } else {
            back9SkinsHoles[winners[0]]!.add(hole);
          }
          print('NassauGameScreen: Hole $hole - Winner: ${winners[0]}, Skins points: ${skinsTotals[winners[0]]}, Segment: ${hole <= 9 ? 'Front 9' : 'Back 9'}');
        }
      }
    }

    // Dynamic Output for Winners (used for table)
    String front9Result = _getResult(front9Totals, front9HolesPlayed, 9, "Front 9 Holes", front9Bet);
    String back9Result = _getResult(back9Totals, back9HolesPlayed, 9, "Back 9 Holes", back9Bet);
    String overallResult = _getResult(overallTotals, totalHolesPlayed, 18, "18 Holes", overallBet);
    print('NassauGameScreen: Results - Front 9: $front9Result, Back 9: $back9Result, Overall: $overallResult');

    // Helper function to determine player status for Winners section
    String _getPlayerStatus(String player, Map<String, int> totals, int holesPlayed, int totalHoles) {
      if (holesPlayed == 0 || totals.isEmpty) return "No scores";
      var minScore = totals.values.reduce((a, b) => a < b ? a : b);
      var leaders = totals.entries.where((e) => e.value == minScore).map((e) => e.key).toList();
      if (holesPlayed < totalHoles) {
        if (totals[player] == minScore) return "Leading";
        return "Trailing";
      } else {
        if (leaders.length == 1 && leaders.contains(player)) return "Winner";
        if (leaders.contains(player)) return "Tied";
        return "Lost";
      }
    }

    // Table-based Results Display
    Widget buildSectionTable(String heading, String subheading1, List<Widget> row1, List<Widget> row2, List<Widget> row3, {String subheading2 = 'F9', int rows = 3}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: rows == 3 ? 120 : 80, // 120 for 3 rows, 80 for 2 rows (~40 pixels each)
            alignment: Alignment.center,
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  heading,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ),
          ),
          Expanded(
            child: Table(
              border: TableBorder.all(color: Colors.grey),
              columnWidths: const {
                0: FixedColumnWidth(50), // Subheadings column
              },
              defaultColumnWidth: const IntrinsicColumnWidth(), // Player columns dynamic
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(color: Colors.green[100]),
                      child: SizedBox(
                        width: 50,
                        child: Text(subheading1, style: const TextStyle(color: Colors.black87), textAlign: TextAlign.center),
                      ),
                    ),
                    ...row1,
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 50,
                        child: Text(subheading2, style: const TextStyle(color: Colors.black87), textAlign: TextAlign.center),
                      ),
                    ),
                    ...row2,
                  ],
                ),
                if (rows == 3)
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 50,
                          child: Text('B9', style: TextStyle(color: Colors.black87), textAlign: TextAlign.center),
                        ),
                      ),
                      ...row3,
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nassau Game Results', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.green[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nassau Results',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 16),
                // Header Row
                Row(
                  children: [
                    const SizedBox(width: 30), // Vertical headings column
                    Expanded(
                      child: Table(
                        border: TableBorder.all(color: Colors.grey),
                        columnWidths: const {
                          0: FixedColumnWidth(50), // Subheadings column
                        },
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            children: [
                              const SizedBox(width: 50),
                              ...selectedPlayers.map((player) => Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      player,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Handicap Distribution Section
                buildSectionTable(
                  'Handicaps',
                  '18',
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${handicaps[player] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${front9Strokes[player]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${back9Strokes[player]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                ),
                // Scores Section
                buildSectionTable(
                  'Scores',
                  '18',
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${overallRawScores[player]! >= 0 ? '+' : ''}${overallRawScores[player]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${front9RawScores[player]! >= 0 ? '+' : ''}${front9RawScores[player]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${back9RawScores[player]! >= 0 ? '+' : ''}${back9RawScores[player]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                ),
                // Adjusted Scores Section
                buildSectionTable(
                  'Adj. Scores',
                  '18',
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${overallTotals[player]! >= 0 ? '+' : ''}${overallTotals[player]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${front9Totals[player]! >= 0 ? '+' : ''}${front9Totals[player]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${back9Totals[player]! >= 0 ? '+' : ''}${back9Totals[player]}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                ),
                // Winners Section
                buildSectionTable(
                  'Winners',
                  '18',
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _getPlayerStatus(player, overallTotals, totalHolesPlayed, 18),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _getPlayerStatus(player, front9Totals, front9HolesPlayed, 9),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _getPlayerStatus(player, back9Totals, back9HolesPlayed, 9),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                ),
                // Skins Section
                buildSectionTable(
                  'Skins',
                  'F9',
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          enableSkins
                              ? '${front9SkinsHoles[player]!.length} (${front9SkinsHoles[player]!.isEmpty ? 'None' : front9SkinsHoles[player]!.join(', ')})'
                              : 'Disabled',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((player) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          enableSkins
                              ? '${back9SkinsHoles[player]!.length} (${back9SkinsHoles[player]!.isEmpty ? 'None' : back9SkinsHoles[player]!.join(', ')})'
                              : 'Disabled',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      )).toList(),
                  selectedPlayers.map((_) => const SizedBox()).toList(),
                  subheading2: 'B9',
                  rows: 2,
                ),
                if (enableSkins)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Points per Skin: $skinsPoints',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getResult(Map<String, int> totals, int holesPlayed, int totalHoles, String segmentName, int bet) {
    if (holesPlayed == 0 || totals.isEmpty) return "$segmentName: No scores yet, Bet: $bet";
    var minScore = totals.values.reduce((a, b) => a < b ? a : b);
    var leaders = totals.entries.where((e) => e.value == minScore).map((e) => e.key).toList();

    if (holesPlayed < totalHoles) {
      var leaderText = leaders.map((p) => "$p (${totals[p]})").join(", ");
      return "Leading $segmentName: $leaderText, Bet: $bet";
    } else {
      if (leaders.length == 1) {
        return "$segmentName Winner: ${leaders[0]} (${totals[leaders[0]]}), Bet: $bet";
      } else {
        var tieText = leaders.map((p) => "$p (${totals[p]})").join(", ");
        return "$segmentName Tied: $tieText, Bet: $bet";
      }
    }
  }
}