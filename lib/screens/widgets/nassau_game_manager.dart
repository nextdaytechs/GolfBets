import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../models/score_entry.dart';
import '../../models/nassau_settings.dart';
import 'nassau_game_screen.dart';
import '../../main.dart';

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

  void _loadSavedSettings() {
    if (nassauSettingsBox.containsKey('nassauSettings')) {
      final savedSettings = nassauSettingsBox.get('nassauSettings');
      if (savedSettings != null) {
        setState(() {
          settings = savedSettings;
          isEnabled = true;
        });
      }
    }
  }

  void _saveSettings(NassauSettings newSettings) {
    nassauSettingsBox.put('nassauSettings', newSettings);
    setState(() {
      settings = newSettings;
      isEnabled = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Nassau Game Enabled!'), backgroundColor: Colors.green[600]),
    );
  }

  void _openSetup({bool usePrevious = false}) async {
    if (usePrevious && settings != null) {
      setState(() => isEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Nassau Game Enabled with Previous Settings!'), backgroundColor: Colors.green[600]),
      );
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
        final handicaps = {for (var p in widget.players) p.name: p.handicap}; // Use Player.handicap

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
                    Row(children: [Icon(Icons.people, color: Colors.green[800]), const SizedBox(width: 8), const Text("Select Players:")]),
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
                      decoration: const InputDecoration(labelText: "Front 9 Bet", prefixIcon: Icon(Icons.attach_money, color: Colors.amber), border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      controller: front9Controller,
                      onChanged: (val) => front9 = int.tryParse(val) ?? front9,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: "Back 9 Bet", prefixIcon: Icon(Icons.attach_money, color: Colors.amber), border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      controller: back9Controller,
                      onChanged: (val) => back9 = int.tryParse(val) ?? back9,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: "Overall Bet", prefixIcon: Icon(Icons.attach_money, color: Colors.amber), border: OutlineInputBorder()),
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
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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

    if (result != null) _saveSettings(result);
  }

  void disable() {
    setState(() => isEnabled = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Nassau Game Disabled'), backgroundColor: Colors.redAccent));
  }

  void reset() {
    setState(() {
      isEnabled = false;
      settings = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                              SnackBar(content: const Text('Nassau Game Enabled with Previous Settings!'), backgroundColor: Colors.green[600]),
                            );
                          },
                          child: const Text("Use Previous"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () {
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