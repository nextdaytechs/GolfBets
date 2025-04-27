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
    final filteredScores = scores.where((s) => selectedPlayers.contains(s.playerName)).toList();
    final front9Scores = filteredScores.where((s) => s.holeNumber <= 9).toList();
    final back9Scores = filteredScores.where((s) => s.holeNumber > 9 && s.holeNumber <= 18).toList();
    final front9HolesPlayed = front9Scores.map((s) => s.holeNumber).toSet().length; // Unique holes
    final back9HolesPlayed = back9Scores.map((s) => s.holeNumber).toSet().length;
    final totalHolesPlayed = filteredScores.map((s) => s.holeNumber).toSet().length;

    Map<String, int> front9Totals = {};
    Map<String, int> back9Totals = {};
    Map<String, int> overallTotals = {};
    Map<String, int> skinsTotals = {};

    // Calculate handicap distribution
    Map<String, int> front9Strokes = {};
    Map<String, int> back9Strokes = {};
    for (var player in selectedPlayers) {
      int totalHandicap = handicaps[player] ?? 0;
      int front9Allocation = totalHandicap.isOdd
          ? (totalHandicap * 0.6).ceil() // Odd: Front 9 gets more (e.g., 60%)
          : (totalHandicap / 2).round(); // Even: Split evenly (50%)
      int back9Allocation = totalHandicap - front9Allocation;
      front9Strokes[player] = front9Allocation;
      back9Strokes[player] = back9Allocation;
      skinsTotals[player] = 0;
    }

    // Calculate total scores for each segment
    for (var player in selectedPlayers) {
      // Front 9 Total
      int front9Score = front9Scores
          .where((s) => s.playerName == player)
          .fold(0, (sum, s) => sum + s.relativeScore);
      front9Totals[player] = front9Score - front9Strokes[player]!;

      // Back 9 Total
      int back9Score = back9Scores
          .where((s) => s.playerName == player)
          .fold(0, (sum, s) => sum + s.relativeScore);
      back9Totals[player] = back9Score - back9Strokes[player]!;

      // Overall Total
      int overallScore = filteredScores
          .where((s) => s.playerName == player)
          .fold(0, (sum, s) => sum + s.relativeScore);
      overallTotals[player] = overallScore - (handicaps[player] ?? 0);
    }

    // Skins Calculation (per-hole, with handicap adjustments) if enabled
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
        }
      }
    }

    // Dynamic Output
    String front9Result = _getResult(front9Totals, front9HolesPlayed, 9, "Front 9 Holes", front9Bet);
    String back9Result = _getResult(back9Totals, back9HolesPlayed, 9, "Back 9 Holes", back9Bet);
    String overallResult = _getResult(overallTotals, totalHolesPlayed, 18, "18 Holes", overallBet);
    String skinsResult = enableSkins ? _getSkinsResult(skinsTotals, totalHolesPlayed) : "Skins: Disabled";

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nassau Results',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 16),
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
              Text(skinsResult),
            ],
          ),
        ),
      ),
    );
  }

  String _getResult(Map<String, int> totals, int holesPlayed, int totalHoles, String segmentName, int bet) {
    if (holesPlayed == 0) return "$segmentName: No scores yet, Bet: $bet";
    var minScore = totals.values.isEmpty ? 0 : totals.values.reduce((a, b) => a < b ? a : b);
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
    if (holesPlayed == 0) return "Skins: No scores yet, Points per Skin: $skinsPoints";
    var maxSkins = totals.values.isEmpty ? 0 : totals.values.reduce((a, b) => a > b ? a : b);
    var leaders = totals.entries.where((e) => e.value == maxSkins).map((e) => e.key).toList();

    var leaderText = leaders.map((p) => "$p (${totals[p]})").join(", ");
    return "Skins Leaders: $leaderText, Points per Skin: $skinsPoints";
  }
}