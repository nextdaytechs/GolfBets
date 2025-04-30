import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import '../../../models/player.dart';
import '../../../models/hole.dart';
import '../../../models/score_entry.dart';

class ScoreCardWidget extends StatefulWidget {
  final List<Player> players;
  final List<Hole> holes;
  final List<ScoreEntry> scores;
  final VoidCallback? onScoreChanged;
  final void Function(Hole, int)? onEditHole;

  const ScoreCardWidget({
    super.key,
    required this.players,
    required this.holes,
    required this.scores,
    this.onScoreChanged,
    this.onEditHole,
  });

  @override
  State<ScoreCardWidget> createState() => _ScoreCardWidgetState();
}

class _ScoreCardWidgetState extends State<ScoreCardWidget> {
  final Map<String, Map<int, TextEditingController>> controllers = {};

  @override
  void initState() {
    super.initState();
    try {
      _initControllers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error initializing scorecard')),
      );
    }
  }

  void _initControllers() {
    controllers.clear();
    try {
      for (var player in widget.players) {
        if (player.name.isEmpty) {
          continue;
        }
        controllers[player.name] = {};
        for (var hole in widget.holes) {
          if (hole.number <= 0) {
            continue;
          }
          final entry = widget.scores.firstWhereOrNull(
            (s) => s.playerName == player.name && s.holeNumber == hole.number,
          );
          controllers[player.name]![hole.number] = TextEditingController(
            text: entry?.relativeScore.toString() ?? '',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error initializing controllers')),
      );
    }
  }

  @override
  void didUpdateWidget(ScoreCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    try {
      if (!const DeepCollectionEquality().equals(oldWidget.holes, widget.holes) ||
          !const DeepCollectionEquality().equals(oldWidget.players, widget.players)) {
        _initControllers();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating scorecard')),
      );
    }
  }

  void _saveScore(String playerName, int holeNumber, String value) {
    try {
      if (!Hive.isBoxOpen('scoreBox')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Score data not available')),
        );
        return;
      }

      final parsed = int.tryParse(value.trim());
      if (parsed == null) {
        return;
      }

      final scoreBox = Hive.box<ScoreEntry>('scoreBox');
      final existing = scoreBox.values.firstWhereOrNull(
        (s) => s.playerName == playerName && s.holeNumber == holeNumber,
      );

      if (existing != null) {
        existing.relativeScore = parsed;
        existing.save();
      } else {
        scoreBox.add(ScoreEntry(
          playerName: playerName,
          holeNumber: holeNumber,
          relativeScore: parsed,
        ));
      }
      setState(() {});
      widget.onScoreChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving score')),
      );
    }
  }

  Future<void> _showScorePicker(String playerName, int holeNumber) async {
    try {
      int? selectedScore;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select Score for $playerName - Hole $holeNumber'),
            content: SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [-3, -2, -1, 0, 1, 2, 3, 4].map((score) {
                    return ListTile(
                      leading: Text(score.toString()),
                      title: Text(_scoreLabel(score)),
                      onTap: () {
                        selectedScore = score;
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      if (selectedScore != null) {
        final playerControllers = controllers[playerName];
        if (playerControllers == null) {
          return;
        }
        final controller = playerControllers[holeNumber];
        if (controller != null) {
          controller.text = selectedScore.toString();
          _saveScore(playerName, holeNumber, selectedScore.toString());
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error showing score picker')),
      );
    }
  }

  String _scoreLabel(int score) {
    try {
      switch (score) {
        case -3:
          return 'Albatross';
        case -2:
          return 'Eagle';
        case -1:
          return 'Birdie';
        case 0:
          return 'Par';
        case 1:
          return 'Bogey';
        case 2:
          return 'Double Bogey';
        case 3:
          return 'Triple Bogey';
        case 4:
          return 'Quadruple Bogey';
        default:
          return '';
      }
    } catch (e) {
      return '';
    }
  }

  int _calculateTotal(String playerName) {
    int total = 0;
    try {
      final playerControllers = controllers[playerName];
      if (playerControllers == null) {
        return total;
      }
      for (var hole in widget.holes) {
        final controller = playerControllers[hole.number];
        final val = int.tryParse(controller?.text.trim() ?? '');
        if (val != null) total += val;
      }
    } catch (e) {
      return total;
    }
    return total;
  }

  int _calculateTotalScoreForRange(String playerName, int startHole, int endHole) {
    int total = 0;
    final playerControllers = controllers[playerName];
    if (playerControllers == null) {
      return total;
    }
    for (var hole in widget.holes) {
      if (hole.number >= startHole && hole.number <= endHole) {
        final controller = playerControllers[hole.number];
        final val = int.tryParse(controller?.text.trim() ?? '');
        if (val != null) total += val;
      }
    }
    return total;
  }

  int _calculateTotalParForRange(int startHole, int endHole) {
    return widget.holes
        .where((hole) => hole.number >= startHole && hole.number <= endHole)
        .fold(0, (sum, hole) => sum + hole.par);
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Handle empty or invalid data
      if (widget.holes.isEmpty || widget.players.isEmpty) {
        return const Center(child: Text('No holes or players available', style: TextStyle(color: Colors.redAccent)));
      }

      // Filter out any invalid players
      final validPlayers = widget.players.where((player) => player.name.isNotEmpty).toList();
      if (validPlayers.isEmpty) {
        return const Center(child: Text('No valid players available', style: TextStyle(color: Colors.redAccent)));
      }

      // Filter out any invalid holes
      final validHoles = widget.holes.where((hole) => hole.number > 0).toList();
      if (validHoles.isEmpty) {
        return const Center(child: Text('No valid holes available', style: TextStyle(color: Colors.redAccent)));
      }

      // Build table rows dynamically for the hole table
      List<TableRow> holeTableRows = [];

      // Add all holes
      for (var entry in validHoles.asMap().entries) {
        final hole = entry.value;
        final globalIndex = entry.key; // Global index for onEditHole
        holeTableRows.add(TableRow(
          decoration: BoxDecoration(color: Colors.green[50]), // Light green background
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    try {
                      if (widget.onEditHole != null) {
                        widget.onEditHole!(hole, globalIndex);
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error editing/deleting hole')),
                      );
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hole.name.isEmpty ? 'Hole ${hole.number}' : hole.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hole.par >= 3 && hole.par <= 5 ? '${hole.par}' : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ...validPlayers.map((player) {
              final playerControllers = controllers[player.name];
              if (playerControllers == null) {
                return const TableCell(child: SizedBox());
              }
              final controller = playerControllers[hole.number];
              if (controller == null) {
                return const TableCell(child: SizedBox());
              }
              return TableCell(
                child: InkWell(
                  onTap: () => _showScorePicker(player.name, hole.number),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.white, // White background fills entire cell
                    ),
                    padding: const EdgeInsets.all(8.0), // Uniform padding all around
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.text.isEmpty ? '-' : controller.text,
                            style: const TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4.0), // Spacer to match two-line height
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ));
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed Header Table (P, H, T, Front 9 Summary, Back 9 Summary)
            Table(
              border: TableBorder.all(color: Colors.grey),
              defaultColumnWidth: const FixedColumnWidth(65), // Expanded fixed width
              children: [
                // P Row (Player Names)
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('P', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    ...validPlayers.map((player) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              player.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )),
                  ],
                ),
                // H Row (Handicap)
                TableRow(
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('H', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    ...validPlayers.map((player) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(player.handicap.toString()),
                          ),
                        )),
                  ],
                ),
                // T Row (Total Score)
                TableRow(
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'AT(${widget.holes.where((hole) => hole.number > 0).length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ...validPlayers.map((player) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _calculateTotal(player.name) > 0
                                  ? '+${_calculateTotal(player.name)}'
                                  : _calculateTotal(player.name).toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                  ],
                ),
                // Front 9 Summary Row (Holes 1-9)
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'F9(${_calculateTotalParForRange(1, 9)})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ...validPlayers.map((player) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _calculateTotalScoreForRange(player.name, 1, 9).toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                  ],
                ),
                // Back 9 Summary Row (Holes 10-18)
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'B9(${_calculateTotalParForRange(10, 18)})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ...validPlayers.map((player) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _calculateTotalScoreForRange(player.name, 10, 18).toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
            // Scrollable Hole Table with Fixed Height
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Table(
                  border: TableBorder.all(color: Colors.grey),
                  defaultColumnWidth: const FixedColumnWidth(65), // Expanded fixed width
                  children: holeTableRows,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const Center(child: Text('Error rendering scorecard', style: TextStyle(color: Colors.redAccent)));
    }
  }

  @override
  void dispose() {
    try {
      for (var playerControllers in controllers.values) {
        for (var controller in playerControllers.values) {
          controller.dispose();
        }
      }
    } catch (e) {}
    super.dispose();
  }
}