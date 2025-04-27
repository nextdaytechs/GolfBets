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
    debugPrint("ScoreCardWidget: initState called");
    try {
      _initControllers();
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error in initState: $e\nStack trace: $stackTrace");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error initializing scorecard')),
      );
    }
  }

  void _initControllers() {
    debugPrint("ScoreCardWidget: Initializing controllers for ${widget.players.length} players, ${widget.holes.length} holes");
    controllers.clear();
    try {
      for (var player in widget.players) {
        if (player.name.isEmpty) {
          debugPrint("ScoreCardWidget: Invalid player detected");
          continue;
        }
        controllers[player.name] = {};
        for (var hole in widget.holes) {
          if (hole.number <= 0) {
            debugPrint("ScoreCardWidget: Invalid hole detected, number: ${hole.number}");
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
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error in _initControllers: $e\nStack trace: $stackTrace");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error initializing controllers')),
      );
    }
  }

  @override
  void didUpdateWidget(ScoreCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("ScoreCardWidget: didUpdateWidget called");
    try {
      if (!const DeepCollectionEquality().equals(oldWidget.holes, widget.holes) ||
          !const DeepCollectionEquality().equals(oldWidget.players, widget.players)) {
        _initControllers();
      }
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error in didUpdateWidget: $e\nStack trace: $stackTrace");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating scorecard')),
      );
    }
  }

  void _saveScore(String playerName, int holeNumber, String value) {
    debugPrint("ScoreCardWidget: Saving score for $playerName on hole $holeNumber: $value");
    try {
      if (!Hive.isBoxOpen('scoreBox')) {
        debugPrint("ScoreCardWidget: scoreBox not open, cannot save score");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Score data not available')),
        );
        return;
      }

      final parsed = int.tryParse(value.trim());
      if (parsed == null) {
        debugPrint("ScoreCardWidget: Invalid score value: $value");
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
      debugPrint("ScoreCardWidget: Saved score $parsed for $playerName on hole $holeNumber");
      setState(() {});
      widget.onScoreChanged?.call();
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error saving score: $e\nStack trace: $stackTrace");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving score')),
      );
    }
  }

  Future<void> _showScorePicker(String playerName, int holeNumber) async {
    debugPrint("ScoreCardWidget: Showing score picker for $playerName, hole $holeNumber");
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
          debugPrint("ScoreCardWidget: No controllers found for player $playerName");
          return;
        }
        final controller = playerControllers[holeNumber];
        if (controller != null) {
          controller.text = selectedScore.toString();
          _saveScore(playerName, holeNumber, selectedScore.toString());
        } else {
          debugPrint("ScoreCardWidget: Controller not found for $playerName, hole $holeNumber");
        }
      }
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error in _showScorePicker: $e\nStack trace: $stackTrace");
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
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error in _scoreLabel: $e\nStack trace: $stackTrace");
      return '';
    }
  }

  int _calculateTotal(String playerName) {
    debugPrint("ScoreCardWidget: Calculating total for $playerName");
    int total = 0;
    try {
      final playerControllers = controllers[playerName];
      if (playerControllers == null) {
        debugPrint("ScoreCardWidget: No controllers found for player $playerName in _calculateTotal");
        return total;
      }
      for (var hole in widget.holes) {
        final controller = playerControllers[hole.number];
        final val = int.tryParse(controller?.text.trim() ?? '');
        if (val != null) total += val;
      }
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error in _calculateTotal for $playerName: $e\nStack trace: $stackTrace");
    }
    return total;
  }

  int _calculateTotalScoreForRange(String playerName, int startHole, int endHole) {
    int total = 0;
    final playerControllers = controllers[playerName];
    if (playerControllers == null) {
      debugPrint("ScoreCardWidget: No controllers found for player $playerName in _calculateTotalScoreForRange");
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
    debugPrint("ScoreCardWidget: Building with ${widget.holes.length} holes, ${widget.players.length} players");
    try {
      // Log hole data
      for (var hole in widget.holes) {
        debugPrint("ScoreCardWidget: Hole: number=${hole.number}, name=${hole.name}, par=${hole.par}");
      }

      // Handle empty or invalid data
      if (widget.holes.isEmpty || widget.players.isEmpty) {
        debugPrint("ScoreCardWidget: No holes or players available");
        return const Center(child: Text('No holes or players available', style: TextStyle(color: Colors.redAccent)));
      }

      // Filter out any invalid players
      final validPlayers = widget.players.where((player) => player.name.isNotEmpty).toList();
      if (validPlayers.isEmpty) {
        debugPrint("ScoreCardWidget: No valid players after filtering");
        return const Center(child: Text('No valid players available', style: TextStyle(color: Colors.redAccent)));
      }

      // Filter out any invalid holes
      final validHoles = widget.holes.where((hole) => hole.number > 0).toList();
      if (validHoles.isEmpty) {
        debugPrint("ScoreCardWidget: No valid holes after filtering");
        return const Center(child: Text('No valid holes available', style: TextStyle(color: Colors.redAccent)));
      }

      // Build table rows dynamically for the hole table
      List<TableRow> holeTableRows = [];

      // Add all holes
      for (var entry in validHoles.asMap().entries) {
        final hole = entry.value;
        final globalIndex = entry.key; // Global index for onEditHole
        debugPrint("ScoreCardWidget: Rendering hole ${hole.name} (number: ${hole.number}, par: ${hole.par}) at index: $globalIndex");
        holeTableRows.add(TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    debugPrint("ScoreCardWidget: Tapped hole ${hole.name} at index $globalIndex");
                    try {
                      if (widget.onEditHole != null) {
                        debugPrint("ScoreCardWidget: Calling onEditHole for hole ${hole.number}");
                        widget.onEditHole!(hole, globalIndex);
                      } else {
                        debugPrint("ScoreCardWidget: onEditHole callback is null");
                      }
                    } catch (e, stackTrace) {
                      debugPrint("ScoreCardWidget: Error in onEditHole: $e\nStack trace: $stackTrace");
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error editing/deleting hole')),
                      );
                    }
                  },
                  child: Text(
                    hole.name.isEmpty
                        ? 'Hole ${hole.number}.${hole.par >= 3 && hole.par <= 5 ? hole.par : '?'}'
                        : '${hole.name}.${hole.par >= 3 && hole.par <= 5 ? hole.par : '?'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            ...validPlayers.map((player) {
              final playerControllers = controllers[player.name];
              if (playerControllers == null) {
                debugPrint("ScoreCardWidget: No controllers found for player ${player.name}");
                return const TableCell(child: SizedBox());
              }
              final controller = playerControllers[hole.number];
              if (controller == null) {
                debugPrint("ScoreCardWidget: Controller not found for player ${player.name}, hole ${hole.number}");
                return const TableCell(child: SizedBox());
              }
              return TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: InkWell(
                    onTap: () => _showScorePicker(player.name, hole.number),
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      alignment: Alignment.center,
                      child: Text(
                        controller.text.isEmpty ? '-' : controller.text,
                        style: const TextStyle(fontSize: 16),
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
              defaultColumnWidth: const FixedColumnWidth(60),
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
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          'F.${_calculateTotalParForRange(1, 9)}',
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
                          'B.${_calculateTotalParForRange(10, 18)}',
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
                  defaultColumnWidth: const FixedColumnWidth(60),
                  children: holeTableRows,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error in build: $e\nStack trace: $stackTrace");
      return const Center(child: Text('Error rendering scorecard', style: TextStyle(color: Colors.redAccent)));
    }
  }

  @override
  void dispose() {
    debugPrint("ScoreCardWidget: dispose called");
    try {
      for (var playerControllers in controllers.values) {
        for (var controller in playerControllers.values) {
          controller.dispose();
        }
      }
    } catch (e, stackTrace) {
      debugPrint("ScoreCardWidget: Error in dispose: $e\nStack trace: $stackTrace");
    }
    super.dispose();
  }
}