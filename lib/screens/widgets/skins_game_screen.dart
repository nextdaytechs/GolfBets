import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../models/score_entry.dart';

class SkinsGameScreen extends StatelessWidget {
  final List<ScoreEntry> scores;
  final List<String> selectedPlayers;
  final bool carryOverEnabled;
  final int basePoints;
  final int birdieBonus;
  final int eagleBonus;
  final int albatrosBonus;

  const SkinsGameScreen({
    super.key,
    required this.scores,
    required this.selectedPlayers,
    required this.carryOverEnabled,
    required this.basePoints,
    required this.birdieBonus,
    required this.eagleBonus,
    required this.albatrosBonus,
  });

  @override
  Widget build(BuildContext context) {
    final filteredScores = scores.where((s) => selectedPlayers.contains(s.playerName)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skins Game Results', style: TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Skins Results', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 16),
              if (selectedPlayers.isEmpty)
                const Center(child: Text("No players selected for Skins.", style: TextStyle(fontSize: 18, color: Colors.grey)))
              else if (filteredScores.isEmpty)
                const Center(child: Text("Enter scores to see Skins results.", style: TextStyle(fontSize: 18, color: Colors.grey)))
              else ...[
                Text("Head-to-Head Points", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green[900])),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _headToHeadMatrix(filteredScores)),
                  ),
                ),
                const SizedBox(height: 32),
                Text("Skins Totals", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green[900])),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(padding: const EdgeInsets.all(16), child: _buildSkinsTotals(filteredScores)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headToHeadMatrix(List<ScoreEntry> scores) {
    final playerNames = selectedPlayers..sort();
    final holes = scores.map((s) => s.holeNumber).toSet().toList()..sort();

    final results = {for (var p in playerNames) p: <String, int>{}};
    final carryStore = _CarryGroupStore();

    for (var hole in holes) {
      final holeScores = scores.where((s) => s.holeNumber == hole).toList();
      final grouped = <int, Set<String>>{};
      for (var s in holeScores) {
        grouped.putIfAbsent(s.relativeScore, () => <String>{}).add(s.playerName);
      }

      final tiedGroups = grouped.values.where((g) => g.length > 1).toList();

      for (var i = 0; i < playerNames.length; i++) {
        for (var j = 0; j < playerNames.length; j++) {
          if (i == j) continue;
          final p1 = playerNames[i];
          final p2 = playerNames[j];

          final s1Entry = holeScores.firstWhereOrNull((s) => s.playerName == p1);
          final s2Entry = holeScores.firstWhereOrNull((s) => s.playerName == p2);
          if (s1Entry == null || s2Entry == null) continue;

          final s1 = s1Entry.relativeScore;
          final s2 = s2Entry.relativeScore;

          if (s1 == s2) continue;

          final isSameTieGroup = tiedGroups.any((group) => group.contains(p1) && group.contains(p2));
          if (isSameTieGroup) continue;

          if (s1 < s2) {
            int carryPoints = 0;
            if (carryOverEnabled) {
              carryPoints = carryStore.claimPoints(p1, p2, basePoints);
            }

            int bonus = 0;
            if (s1 < 0) {
              bonus = s1 == -1 ? birdieBonus : s1 == -2 ? eagleBonus : s1 <= -3 ? albatrosBonus : 0;
            }
            final totalPoints = carryPoints + basePoints + bonus;

            results[p1]!.update(p2, (val) => val + totalPoints, ifAbsent: () => totalPoints);
          }
        }
      }

      if (carryOverEnabled) {
        for (final group in tiedGroups) {
          final players = group.toList();
          for (int i = 0; i < players.length; i++) {
            for (int j = i + 1; j < players.length; j++) {
              final subGroup = {players[i], players[j]};
              carryStore.addOrUpdate(subGroup, hole);
            }
          }
        }
      }
    }

    return DataTable(
      columnSpacing: 24,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 48,
      headingRowHeight: 56,
      headingTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[900]),
      dataTextStyle: const TextStyle(fontSize: 14),
      columns: [const DataColumn(label: Text('Player')), ...playerNames.map((name) => DataColumn(label: Text(name)))],
      rows: playerNames.map((p) => DataRow(cells: [
        DataCell(Text(p, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ...playerNames.map((q) {
          if (p == q) return const DataCell(Text('—'));
          final val = results[p]?[q] ?? 0;
          final color = val > 0 ? Colors.green[600] : val < 0 ? Colors.redAccent : Colors.black;
          return DataCell(Text(val > 0 ? '+$val' : '$val', style: TextStyle(color: color)));
        }),
      ])).toList(),
    );
  }

  Widget _buildSkinsTotals(List<ScoreEntry> scores) {
    final playerNames = selectedPlayers..sort();
    final holes = scores.map((s) => s.holeNumber).toSet().toList()..sort();

    final results = {for (var p in playerNames) p: <String, int>{}};
    final carryStore = _CarryGroupStore();

    for (var hole in holes) {
      final holeScores = scores.where((s) => s.holeNumber == hole).toList();
      final grouped = <int, Set<String>>{};
      for (var s in holeScores) {
        grouped.putIfAbsent(s.relativeScore, () => <String>{}).add(s.playerName);
      }

      final tiedGroups = grouped.values.where((g) => g.length > 1).toList();

      for (var i = 0; i < playerNames.length; i++) {
        for (var j = 0; j < playerNames.length; j++) {
          if (i == j) continue;
          final p1 = playerNames[i];
          final p2 = playerNames[j];

          final s1Entry = holeScores.firstWhereOrNull((s) => s.playerName == p1);
          final s2Entry = holeScores.firstWhereOrNull((s) => s.playerName == p2);
          if (s1Entry == null || s2Entry == null) continue;

          final s1 = s1Entry.relativeScore;
          final s2 = s2Entry.relativeScore;

          if (s1 == s2) continue;

          final isSameTieGroup = tiedGroups.any((group) => group.contains(p1) && group.contains(p2));
          if (isSameTieGroup) continue;

          if (s1 < s2) {
            int carryPoints = 0;
            if (carryOverEnabled) {
              carryPoints = carryStore.claimPoints(p1, p2, basePoints);
            }

            int bonus = 0;
            if (s1 < 0) {
              bonus = s1 == -1 ? birdieBonus : s1 == -2 ? eagleBonus : s1 <= -3 ? albatrosBonus : 0;
            }
            final totalPoints = carryPoints + basePoints + bonus;

            results[p1]!.update(p2, (val) => val + totalPoints, ifAbsent: () => totalPoints);
          }
        }
      }

      if (carryOverEnabled) {
        for (final group in tiedGroups) {
          final players = group.toList();
          for (int i = 0; i < players.length; i++) {
            for (int j = i + 1; j < players.length; j++) {
              final subGroup = {players[i], players[j]};
              carryStore.addOrUpdate(subGroup, hole);
            }
          }
        }
      }
    }

    final netPoints = <String, int>{};
    for (var p in playerNames) {
      netPoints[p] = 0;
      for (var q in playerNames) {
        if (p == q) continue;
        netPoints[p] = netPoints[p]! + (results[p]?[q] ?? 0) - (results[q]?[p] ?? 0);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: playerNames.map((p) {
        final points = netPoints[p]!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text("${points > 0 ? '+' : ''}$points",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: points > 0 ? Colors.green[600] : points < 0 ? Colors.redAccent : Colors.black,
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CarryGroup {
  final Set<String> players;
  int count;
  final int startHole;

  _CarryGroup(this.players, this.count, this.startHole);

  String get name {
    final sorted = players.toList()..sort();
    return 'h$startHole|${sorted.join('|')}';
  }
}

class _CarryGroupStore {
  final Map<String, _CarryGroup> _store = {};

  void addOrUpdate(Set<String> players, int hole) {
    final key = _key(players);
    if (_store.containsKey(key)) {
      _store[key]!.count++;
    } else {
      _store[key] = _CarryGroup(Set.of(players), 1, hole);
    }
  }

  int claimPoints(String p1, String p2, int base) {
    final broken = <String>[];
    int total = 0;
    for (final entry in _store.entries) {
      if (entry.value.players.contains(p1) && entry.value.players.contains(p2)) {
        total += entry.value.count * base;
        broken.add(entry.key);
      }
    }
    for (final k in broken) {
      _store.remove(k);
    }
    return total;
  }

  String _key(Set<String> players) {
    final sorted = players.toList()..sort();
    return sorted.join('|');
  }
}