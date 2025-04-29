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
      if (totalHandicap.isOdd) {
        int base = totalHandicap ~/ 2;
        front9Allocation = base + (totalHandicap % 2); // Base + remainder
        back9Allocation = base;
      } else {
        front9Allocation = totalHandicap ~/ 2; // Even split
        back9Allocation = totalHandicap ~/ 2;
      }
      front9Strokes[player] = front9Allocation;
      back9Strokes[player] = back9Allocation;
      skinsTotals[player] = 0;
      print('NassauGameScreen: $player - Handicap: $totalHandicap, Front 9 strokes: $front9Allocation, Back 9 strokes: $back9Allocation');
    }

    // Calculate total scores for each segment
    for (var player in selectedPlayers) {
      // Front 9 Total
      int front9Score = front9Scores
          .where((s) => s.playerName == player)
          .fold(0, (sum, s) => sum + s.relativeScore);
      front9RawScores[player] = front9Score;
      front9Totals[player] = front9Score - front9Strokes[player]!;
      print('NassauGameScreen: $player - Front 9 raw: $front9Score, adjusted: ${front9Totals[player]}');

      // Back 9 Total
      int back9Score = back9Scores
          .where((s) => s.playerName == player)
          .fold(0, (sum, s) => sum + s.relativeScore);
      back9RawScores[player] = back9Score;
      back9Totals[player] = back9Score - back9Strokes[player]!;
      print('NassauGameScreen: $player - Back 9 raw: $back9Score, adjusted: ${back9Totals[player]}');

      // Overall Total
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

        // Adjust scores for handicaps on a per-hole basis for Skins
        var adjustedScores = holeScores.map((s) {
          int strokes = hole <= 9 ? front9Strokes[s.playerName]! : back9Strokes[s.playerName]!;
          int maxHole = hole <= 9 ? strokes : 9 + strokes;
          int adjustedScore = s.relativeScore - (strokes > 0 && hole <= maxHole ? 1 : 0);
          return MapEntry(s.playerName, adjustedScore);
        }).toList();

        // Find the lowest adjusted score for the hole
        var minScore = adjustedScores.map((e) => e.value).reduce((a, b) => a < b ? a : b);
        var winners = adjustedScores.where((e) => e.value == minScore).map((e) => e.key).toList();

        // Skins: Award points for outright hole win
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

    // Dynamic Output
    String front9Result = _getResult(front9Totals, front9HolesPlayed, 9, "Front 9 Holes", front9Bet);
    String back9Result = _getResult(back9Totals, back9HolesPlayed, 9, "Back 9 Holes", back9Bet);
    String overallResult = _getResult(overallTotals, totalHolesPlayed, 18, "18 Holes", overallBet);
    print('NassauGameScreen: Results - Front 9: $front9Result, Back 9: $back9Result, Overall: $overallResult');

    // Handicap Distribution Display
    List<Widget> handicapWidgets = selectedPlayers.map((player) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '$player: Front 9: ${front9Strokes[player]}, Back 9: ${back9Strokes[player]}, Overall: ${handicaps[player] ?? 0}',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );
    }).toList();

    // Score Card Results Display
    List<Widget> scoreCardWidgets = selectedPlayers.map((player) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '$player: Front 9: ${front9RawScores[player]! >= 0 ? '+' : ''}${front9RawScores[player]} (Adjusted: ${front9Totals[player]! >= 0 ? '+' : ''}${front9Totals[player]}), '
          'Back 9: ${back9RawScores[player]! >= 0 ? '+' : ''}${back9RawScores[player]} (Adjusted: ${back9Totals[player]! >= 0 ? '+' : ''}${back9Totals[player]}), '
          'Overall: ${overallRawScores[player]! >= 0 ? '+' : ''}${overallRawScores[player]} (Adjusted: ${overallTotals[player]! >= 0 ? '+' : ''}${overallTotals[player]})',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );
    }).toList();

    // Skins Results Display
    String skinsResult = enableSkins ? _getSkinsResult(skinsTotals, totalHolesPlayed) : "Skins: Disabled";
    List<Widget> skinsWidgets = enableSkins
        ? selectedPlayers.map((player) {
            final front9Holes = front9SkinsHoles[player]!.isEmpty ? 'None' : front9SkinsHoles[player]!.join(', ');
            final back9Holes = back9SkinsHoles[player]!.isEmpty ? 'None' : back9SkinsHoles[player]!.join(', ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$player: Front 9: Holes $front9Holes, Back 9: Holes $back9Holes, Total: ${skinsTotals[player] ?? 0}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            );
          }).toList()
        : [Text(skinsResult, style: const TextStyle(fontSize: 16, color: Colors.black87))];

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
                const Text(
                  'Handicap Distribution',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                ...handicapWidgets,
                const SizedBox(height: 16),
                const Text(
                  'Score Card Results',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                ...scoreCardWidgets,
                const SizedBox(height: 16),
                const Text(
                  'Winners',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(front9Result),
                const SizedBox(height: 8),
                Text(back9Result),
                const SizedBox(height: 8),
                Text(overallResult),
                const SizedBox(height: 16),
                const Text(
                  'Skins Results',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                ...skinsWidgets,
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

  String _getSkinsResult(Map<String, int> totals, int holesPlayed) {
    if (holesPlayed == 0 || totals.isEmpty) return "Skins: No scores yet, Points per Skin: $skinsPoints";
    var maxSkins = totals.values.reduce((a, b) => a > b ? a : b);
    var leaders = totals.entries.where((e) => e.value == maxSkins).map((e) => e.key).toList();

    var leaderText = leaders.map((p) => "$p (${totals[p]})").join(", ");
    return "Skins Leaders: $leaderText, Points per Skin: $skinsPoints";
  }
}