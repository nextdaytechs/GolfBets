import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/player.dart';
import '../../models/score_entry.dart';
import '../../models/skins_settings.dart';
import 'skins_game_screen.dart';
//import '../../main.dart';

class SkinsGameManager extends StatefulWidget {
  final List<ScoreEntry> scores;
  final List<Player> players;

  const SkinsGameManager({super.key, required this.scores, required this.players});

  @override
  State<SkinsGameManager> createState() => SkinsGameManagerState();
}

class SkinsGameManagerState extends State<SkinsGameManager> with AutomaticKeepAliveClientMixin {
  bool isEnabled = false;
  SkinsSettings? settings;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    print('SkinsGameManager: Loading saved settings');
    final stopwatch = Stopwatch()..start();
    try {
      final skinsBox = await Hive.openBox('skinssettingbox');
      if (skinsBox.containsKey('skinsSettings')) {
        final savedSettings = skinsBox.get('skinsSettings');
        if (savedSettings != null) {
          setState(() {
            settings = savedSettings;
            isEnabled = true;
            print('SkinsGameManager: Settings loaded, isEnabled = true in ${stopwatch.elapsedMilliseconds}ms');
          });
        } else {
          setState(() {
            isEnabled = false;
            settings = null;
            print('SkinsGameManager: No valid settings, isEnabled = false in ${stopwatch.elapsedMilliseconds}ms');
          });
        }
      } else {
        setState(() {
          isEnabled = false;
          settings = null;
          print('SkinsGameManager: No settings key, isEnabled = false in ${stopwatch.elapsedMilliseconds}ms');
        });
      }
    } catch (e) {
      print('SkinsGameManager: Error loading settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading Skins settings: $e'),
          duration: const Duration(milliseconds: 100),
        ),
      );
    }
  }

  Future<void> _saveSettings(SkinsSettings newSettings) async {
    print('SkinsGameManager: Saving new settings');
    final stopwatch = Stopwatch()..start();
    try {
      final skinsBox = await Hive.openBox('skinssettingbox');
      await skinsBox.put('skinsSettings', newSettings);
      setState(() {
        settings = newSettings;
        isEnabled = true;
        print('SkinsGameManager: Settings saved, isEnabled = true in ${stopwatch.elapsedMilliseconds}ms');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Skins Game Enabled!'),
          backgroundColor: Colors.green[600],
          duration: const Duration(milliseconds: 100),
        ),
      );
    } catch (e) {
      print('SkinsGameManager: Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving Skins settings: $e'),
          duration: const Duration(milliseconds: 100),
        ),
      );
    }
  }

  void _openSetup({bool usePrevious = false}) async {
    print('SkinsGameManager: Opening setup dialog, usePrevious = $usePrevious');
    if (usePrevious && settings != null) {
      setState(() {
        isEnabled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Skins Game Enabled with Previous Settings!'),
          backgroundColor: Colors.green[600],
          duration: const Duration(milliseconds: 100),
        ),
      );
      print('SkinsGameManager: Enabled with previous settings');
      return;
    }

    final result = await showDialog<SkinsSettings>(
      context: context,
      builder: (context) {
        final List<String> selected = settings?.selectedPlayers != null
            ? List<String>.from(settings!.selectedPlayers)
            : <String>[];
        bool carryOver = settings?.carryOver ?? true;
        int base = settings?.basePoints ?? 1;
        int birdie = settings?.birdieBonus ?? 2;
        int eagle = settings?.eagleBonus ?? 3;
        int albatros = settings?.albatrosBonus ?? 4;

        final baseController = TextEditingController(text: base.toString());
        final birdieController = TextEditingController(text: birdie.toString());
        final eagleController = TextEditingController(text: eagle.toString());
        final albatrosController = TextEditingController(text: albatros.toString());

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text("Skins Game Setup"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        const Text("Select Players:"),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: widget.players.map((p) => FilterChip(
                        label: Text(p.name),
                        selected: selected.contains(p.name),
                        selectedColor: Colors.green[100],
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              selected.add(p.name);
                            } else {
                              selected.remove(p.name);
                            }
                          });
                        },
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Enable Carry Over"),
                      value: carryOver,
                      activeColor: Colors.green[600],
                      onChanged: (val) => setState(() => carryOver = val),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Base Skin Points",
                        prefixIcon: Icon(Icons.star, color: Colors.amber),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: baseController,
                      onChanged: (val) => base = int.tryParse(val) ?? base,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Birdie Bonus",
                        prefixIcon: Icon(Icons.star, color: Colors.amber),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: birdieController,
                      onChanged: (val) => birdie = int.tryParse(val) ?? birdie,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Eagle Bonus",
                        prefixIcon: Icon(Icons.star, color: Colors.amber),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: eagleController,
                      onChanged: (val) => eagle = int.tryParse(val) ?? eagle,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Albatros Bonus",
                        prefixIcon: Icon(Icons.star, color: Colors.amber),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: albatrosController,
                      onChanged: (val) => albatros = int.tryParse(val) ?? albatros,
                    ),
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
                    Navigator.pop(context, SkinsSettings(
                      selectedPlayers: selected,
                      carryOver: carryOver,
                      basePoints: base,
                      birdieBonus: birdie,
                      eagleBonus: eagle,
                      albatrosBonus: albatros,
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
    print('SkinsGameManager: Disabling game');
    final stopwatch = Stopwatch()..start();
    try {
      final skinsBox = await Hive.openBox('skinssettingbox');
      await skinsBox.delete('skinsSettings'); // Clear settings from box
      setState(() {
        isEnabled = false;
        settings = null;
        print('SkinsGameManager: Disabled, isEnabled = false, settings = null in ${stopwatch.elapsedMilliseconds}ms');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Skins Game Disabled'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(milliseconds: 100),
        ),
      );
    } catch (e) {
      print('SkinsGameManager: Error disabling game: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disabling Skins game: $e'),
          duration: const Duration(milliseconds: 100),
        ),
      );
    }
  }

  Future<void> reset() async {
    print('SkinsGameManager: Resetting game');
    final stopwatch = Stopwatch()..start();
    try {
      final skinsBox = await Hive.openBox('skinssettingbox');
      await skinsBox.delete('skinsSettings'); // Clear settings from box
      setState(() {
        isEnabled = false;
        settings = null;
        print('SkinsGameManager: Reset, isEnabled = false, settings = null in ${stopwatch.elapsedMilliseconds}ms');
      });
    } catch (e) {
      print('SkinsGameManager: Error resetting game: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting Skins game: $e'),
          duration: const Duration(milliseconds: 100),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    print('SkinsGameManager: Building with ${widget.players.length} players');
    // Clear settings if players are empty or don't match selectedPlayers
    if (settings != null && (widget.players.isEmpty || !settings!.selectedPlayers.any((p) => widget.players.any((player) => player.name == p)))) {
      print('SkinsGameManager: Clearing settings due to empty or mismatched players');
      settings = null;
      isEnabled = false;
    }
    return ExpansionTile(
      title: const Text("Whittier Skins", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      leading: Icon(Icons.gamepad, color: Colors.green[800]),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SwitchListTile(
            title: const Text("Enable Skins Game"),
            value: isEnabled,
            activeColor: Colors.green[600],
            onChanged: (val) {
              print('SkinsGameManager: Switch toggled to $val');
              if (val) {
                if (settings != null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: const Text("Skins Game Setup"),
                      content: const Text("Would you like to use the previous settings or set up a new game?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => isEnabled = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Skins Game Enabled with Previous Settings!'),
                                backgroundColor: Colors.green[600],
                                duration: const Duration(milliseconds: 100),
                              ),
                            );
                            print('SkinsGameManager: Enabled with previous settings via dialog');
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
                Text("Carry Over: ${settings!.carryOver ? 'Enabled' : 'Disabled'}"),
                Text("Base Points: ${settings!.basePoints}"),
                Text("Birdie Bonus: ${settings!.birdieBonus}"),
                Text("Eagle Bonus: ${settings!.eagleBonus}"),
                Text("Albatros Bonus: ${settings!.albatrosBonus}"),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      print('SkinsGameManager: Navigating to SkinsGameScreen');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SkinsGameScreen(
                            scores: widget.scores,
                            selectedPlayers: settings!.selectedPlayers.toList(),
                            carryOverEnabled: settings!.carryOver,
                            basePoints: settings!.basePoints,
                            birdieBonus: settings!.birdieBonus,
                            eagleBonus: settings!.eagleBonus,
                            albatrosBonus: settings!.albatrosBonus,
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