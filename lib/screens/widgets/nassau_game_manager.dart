import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/player.dart';
import '../../models/score_entry.dart';
import '../../models/nassau_settings.dart';
import 'nassau_game_screen.dart';
//import '../../main.dart';

class NassauGameManager extends StatefulWidget {
  final List<ScoreEntry> scores;
  final List<Player> players;

  const NassauGameManager({super.key, required this.scores, required this.players});

  @override
  State<NassauGameManager> createState() => NassauGameManagerState();
}

class NassauGameManagerState extends State<NassauGameManager> with AutomaticKeepAliveClientMixin {
  bool isEnabled = false;
  NassauSettings? settings;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    print('NassauGameManager: Loading saved settings');
    final stopwatch = Stopwatch()..start();
    try {
      final nassauBox = await Hive.openBox('nassausettingbox');
      if (nassauBox.containsKey('nassauSettings')) {
        final savedSettings = nassauBox.get('nassauSettings');
        if (savedSettings != null) {
          setState(() {
            settings = savedSettings;
            isEnabled = true;
            print('NassauGameManager: Settings loaded, isEnabled = true in ${stopwatch.elapsedMilliseconds}ms');
          });
        } else {
          setState(() {
            isEnabled = false;
            settings = null;
            print('NassauGameManager: No valid settings, isEnabled = false in ${stopwatch.elapsedMilliseconds}ms');
          });
        }
      } else {
        setState(() {
          isEnabled = false;
          settings = null;
          print('NassauGameManager: No settings key, isEnabled = false in ${stopwatch.elapsedMilliseconds}ms');
        });
      }
    } catch (e) {
      print('NassauGameManager: Error loading settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading Nassau settings: $e'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  Future<void> _saveSettings(NassauSettings newSettings) async {
    print('NassauGameManager: Saving new settings');
    final stopwatch = Stopwatch()..start();
    try {
      final nassauBox = await Hive.openBox('nassausettingbox');
      await nassauBox.put('nassauSettings', newSettings);
      setState(() {
        settings = newSettings;
        isEnabled = true;
        print('NassauGameManager: Settings saved, isEnabled = true in ${stopwatch.elapsedMilliseconds}ms');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nassau Game Enabled!'),
          backgroundColor: Colors.green[600],
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      print('NassauGameManager: Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving Nassau settings: $e'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  void _openSetup({bool usePrevious = false}) async {
    print('NassauGameManager: Opening setup dialog, usePrevious = $usePrevious');
    if (usePrevious && settings != null) {
      setState(() => isEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nassau Game Enabled with Previous Settings!'),
          backgroundColor: Colors.green[600],
          duration: const Duration(milliseconds: 1500),
        ),
      );
      print('NassauGameManager: Enabled with previous settings');
      return;
    }

    final result = await showDialog<NassauSettings>(
      context: context,
      builder: (context) {
        final selected = settings?.selectedPlayers != null
            ? List<String>.from(settings!.selectedPlayers)
            : <String>[];
        int front9 = settings?.front9Bet ?? 1;
        int back9 = settings?.back9Bet ?? 1;
        int overall = settings?.overallBet ?? 1;
        int skinsPoints = settings?.skinsPoints ?? 1;
        bool enableSkins = settings?.enableSkins ?? false;
        final handicaps = {for (var p in widget.players) p.name: p.handicap}; // Use latest Player.handicap

        final front9Controller = TextEditingController(text: front9.toString());
        final back9Controller = TextEditingController(text: back9.toString());
        final overallController = TextEditingController(text: overall.toString());
        final skinsPointsController = TextEditingController(text: skinsPoints.toString());

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Nassau Game Setup"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.people, color: Colors.green[800]),
                      const SizedBox(width: 8),
                      const Text("Select Players:"),
                    ]),
                    Wrap(
                      spacing: 8,
                      children: widget.players.map((p) => FilterChip(
                        label: Text(p.name),
                        selected: selected.contains(p.name),
                        selectedColor: Colors.green[100],
                        onSelected: (val) {
                          setState(() {
                            if (val) selected.add(p.name);
                            else selected.remove(p.name);
                          });
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Front 9 Bet",
                        prefixIcon: Icon(Icons.attach_money, color: Colors.amber),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: front9Controller,
                      onChanged: (val) => front9 = int.tryParse(val) ?? front9,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Back 9 Bet",
                        prefixIcon: Icon(Icons.attach_money, color: Colors.amber),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: back9Controller,
                      onChanged: (val) => back9 = int.tryParse(val) ?? back9,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Overall Bet",
                        prefixIcon: Icon(Icons.attach_money, color: Colors.amber),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: overallController,
                      onChanged: (val) => overall = int.tryParse(val) ?? overall,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Enable Skins"),
                      value: enableSkins,
                      activeColor: Colors.green[600],
                      onChanged: (val) {
                        setState(() {
                          enableSkins = val;
                        });
                      },
                    ),
                    if (enableSkins) ...[
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Skins Points per Hole",
                          prefixIcon: Icon(Icons.star, color: Colors.amber),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: skinsPointsController,
                        onChanged: (val) => skinsPoints = int.tryParse(val) ?? skinsPoints,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, NassauSettings(
                      selectedPlayers: selected,
                      front9Bet: front9,
                      back9Bet: back9,
                      overallBet: overall,
                      handicaps: handicaps,
                      skinsPoints: skinsPoints,
                      enableSkins: enableSkins,
                    ));
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _saveSettings(result);
    }
  }

  Future<void> disable() async {
    print('NassauGameManager: Disabling game');
    final stopwatch = Stopwatch()..start();
    try {
      final nassauBox = await Hive.openBox('nassausettingbox');
      await nassauBox.delete('nassauSettings'); // Clear settings from box
      setState(() {
        isEnabled = false;
        settings = null;
        print('NassauGameManager: Disabled, isEnabled = false, settings = null in ${stopwatch.elapsedMilliseconds}ms');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nassau Game Disabled'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      print('NassauGameManager: Error disabling game: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disabling Nassau game: $e'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  Future<void> reset() async {
    print('NassauGameManager: Resetting game');
    final stopwatch = Stopwatch()..start();
    try {
      final nassauBox = await Hive.openBox('nassausettingbox');
      await nassauBox.delete('nassauSettings'); // Clear settings from box
      setState(() {
        isEnabled = false;
        settings = null;
        print('NassauGameManager: Reset, isEnabled = false, settings = null in ${stopwatch.elapsedMilliseconds}ms');
      });
    } catch (e) {
      print('NassauGameManager: Error resetting game: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting Nassau game: $e'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    print('NassauGameManager: Building with ${widget.players.length} players');
    // Clear settings if players are empty or don't match selectedPlayers
    if (settings != null && (widget.players.isEmpty || !settings!.selectedPlayers.any((p) => widget.players.any((player) => player.name == p)))) {
      print('NassauGameManager: Clearing settings due to empty or mismatched players');
      settings = null;
      isEnabled = false;
    }
    // Update handicaps dynamically based on widget.players
    if (settings != null) {
      settings!.handicaps = {for (var p in widget.players) p.name: p.handicap};
    }
    return ExpansionTile(
      title: const Text("Nassau Game", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      leading: Icon(Icons.gamepad, color: Colors.green[800]),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SwitchListTile(
            title: const Text("Enable Nassau Game"),
            value: isEnabled,
            activeColor: Colors.green[600],
            onChanged: (val) {
              print('NassauGameManager: Switch toggled to $val');
              if (val) {
                if (settings != null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: const Text("Nassau Game Setup"),
                      content: const Text("Would you like to use the previous settings or set up a new game?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => isEnabled = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Nassau Game Enabled with Previous Settings!'),
                                backgroundColor: Colors.green[600],
                                duration: const Duration(milliseconds: 1500),
                              ),
                            );
                            print('NassauGameManager: Enabled with previous settings via dialog');
                          },
                          child: const Text("Use Previous"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _openSetup();
                          },
                          child: const Text("New Setup"),
                        ),
                      ],
                    ),
                  );
                } else {
                  _openSetup();
                }
              } else {
                disable();
              }
            },
          ),
        ),
        if (isEnabled && settings != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected Players: ${settings!.selectedPlayers.join(', ')}"),
                Text("Handicaps: ${settings!.handicaps.entries.map((e) => '${e.key}: ${e.value}').join(', ')}"),
                Text("Front 9 Bet: ${settings!.front9Bet}"),
                Text("Back 9 Bet: ${settings!.back9Bet}"),
                Text("Overall Bet: ${settings!.overallBet}"),
                if (settings!.enableSkins) ...[
                  Text("Skins Enabled: Yes"),
                  Text("Skins Points per Hole: ${settings!.skinsPoints}"),
                ] else
                  const Text("Skins Enabled: No"),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      print('NassauGameManager: Navigating to NassauGameScreen');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NassauGameScreen(
                            scores: widget.scores,
                            selectedPlayers: settings!.selectedPlayers,
                            front9Bet: settings!.front9Bet,
                            back9Bet: settings!.back9Bet,
                            overallBet: settings!.overallBet,
                            handicaps: settings!.handicaps,
                            skinsPoints: settings!.skinsPoints,
                            enableSkins: settings!.enableSkins,
                          ),
                        ),
                      );
                    },
                    child: const Text("View Details"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}