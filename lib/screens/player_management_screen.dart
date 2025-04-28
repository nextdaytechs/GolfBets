import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../main.dart';
import '../models/player.dart';

class PlayerManagementScreen extends StatefulWidget {
  const PlayerManagementScreen({super.key});

  @override
  State<PlayerManagementScreen> createState() => _PlayerManagementScreenState();
}

class _PlayerManagementScreenState extends State<PlayerManagementScreen> {
  List<Player> players = [];
  bool isLoading = true;
  final _nameController = TextEditingController();
  final _handicapController = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  void _loadPlayers() async {
    setState(() => isLoading = true);
    try {
      if (Hive.isBoxOpen('playerBox')) {
        players = playerBox.values.toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading players')),
      );
    }
    setState(() => isLoading = false);
  }

  void _addPlayer() {
    if (Hive.isBoxOpen('playerBox')) {
      final name = _nameController.text.trim();
      final handicap = int.tryParse(_handicapController.text) ?? 0;
      if (name.isNotEmpty) {
        final player = Player(name: name, handicap: handicap);
        playerBox.add(player);
        _nameController.clear();
        _handicapController.clear();
        setState(() {
          players = playerBox.values.toList();
        });
        FocusScope.of(context).requestFocus(_nameFocusNode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Player $name added!'),
            backgroundColor: Colors.green[600],
          ),
        );
        // Clear game settings to disable Nassau and Skins games
        if (Hive.isBoxOpen('nassauSettingsBox') && Hive.isBoxOpen('skinsSettingsBox')) {
          nassauSettingsBox.clear();
          skinsSettingsBox.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nassau and Skins games disabled due to player changes'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Player data not available')),
      );
    }
  }

  void _editPlayer(int index) {
    final player = players[index];
    final editNameController = TextEditingController(text: player.name);
    final editHandicapController = TextEditingController(text: player.handicap.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editNameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: editHandicapController,
              decoration: const InputDecoration(
                labelText: 'Handicap',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              final newName = editNameController.text.trim();
              final newHandicap = int.tryParse(editHandicapController.text) ?? 0;
              if (newName.isNotEmpty) {
                playerBox.putAt(index, Player(name: newName, handicap: newHandicap));
                setState(() {
                  players = playerBox.values.toList();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Player $newName updated!'),
                    backgroundColor: Colors.green[600],
                  ),
                );
                // Clear game settings to disable Nassau and Skins games
                if (Hive.isBoxOpen('nassauSettingsBox') && Hive.isBoxOpen('skinsSettingsBox')) {
                  nassauSettingsBox.clear();
                  skinsSettingsBox.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nassau and Skins games disabled due to player changes'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _deletePlayer(int index) {
    if (Hive.isBoxOpen('playerBox')) {
      final player = playerBox.getAt(index);
      playerBox.deleteAt(index);
      setState(() {
        players = playerBox.values.toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Player ${player?.name} removed!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Clear game settings to disable Nassau and Skins games
      if (Hive.isBoxOpen('nassauSettingsBox') && Hive.isBoxOpen('skinsSettingsBox')) {
        nassauSettingsBox.clear();
        skinsSettingsBox.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nassau and Skins games disabled due to player changes'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Player data not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Players'),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Player Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _handicapController,
                      decoration: const InputDecoration(
                        labelText: 'Handicap',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return Dismissible(
                    key: Key(player.name),
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deletePlayer(index),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        title: Text(player.name),
                        subtitle: Text('Handicap: ${player.handicap}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editPlayer(index),
                              tooltip: 'Edit Player',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deletePlayer(index),
                              tooltip: 'Delete Player',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handicapController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }
}