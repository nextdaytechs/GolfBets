import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/player.dart';

class PlayerManagementScreen extends StatefulWidget {
  final VoidCallback? onPlayersChanged; // Callback to notify ScoreEntryScreen

  const PlayerManagementScreen({super.key, this.onPlayersChanged});

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
    print('PlayerManagementScreen: Loading players');
    setState(() => isLoading = true);
    try {
      final box = await Hive.openBox<Player>('playerBox');
      players = box.values.toList();
      print('PlayerManagementScreen: Players loaded, count: ${players.length}');
    } catch (e) {
      print('PlayerManagementScreen: Error loading players: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading players')),
      );
    }
    setState(() => isLoading = false);
    print('PlayerManagementScreen: isLoading set to false');
  }

  Future<void> _resetGames() async {
    print('PlayerManagementScreen: Resetting all games');
    try {
      final nassauBox = await Hive.openBox('nassausettingbox');
      final skinsBox = await Hive.openBox('skinssettingbox');
      await nassauBox.clear();
      await skinsBox.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Games Reset'),
          backgroundColor: Colors.redAccent,
          duration: Duration(milliseconds: 100),
        ),
      );
      print('PlayerManagementScreen: Cleared nassausettingbox and skinssettingbox');
    } catch (e) {
      print('PlayerManagementScreen: Error resetting games: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting games: $e'),
          duration: const Duration(milliseconds: 100),
        ),
      );
    }
  }

  void _addPlayer() async {
    try {
      final box = await Hive.openBox<Player>('playerBox');
      final name = _nameController.text.trim();
      final handicap = int.tryParse(_handicapController.text.trim()) ?? 0;
      if (name.isNotEmpty) {
        final player = Player(name: name, handicap: handicap);
        await box.add(player);
        _nameController.clear();
        _handicapController.clear();
        setState(() {
          players = box.values.toList();
        });
        FocusScope.of(context).requestFocus(_nameFocusNode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Player $name added!'),
            backgroundColor: Colors.green[600],
            duration: const Duration(milliseconds: 100),
          ),
        );
        print('PlayerManagementScreen: Added player $name with handicap $handicap');
        // Reset games and notify ScoreEntryScreen
        await _resetGames();
        widget.onPlayersChanged?.call();
        print('PlayerManagementScreen: Notified ScoreEntryScreen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Player data not available'),
          duration: Duration(milliseconds: 100),
        ),
      );
      print('PlayerManagementScreen: Error adding player: $e');
    }
  }

  void _editPlayer(int index) async {
    final player = players[index];
    final editNameController = TextEditingController(text: player.name);
    final editHandicapController = TextEditingController(text: player.handicap.toString());

    print('PlayerManagementScreen: Opening edit dialog for player ${player.name}');
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
            onPressed: () async {
              final newName = editNameController.text.trim();
              final newHandicap = int.tryParse(editHandicapController.text.trim()) ?? 0;
              if (newName.isNotEmpty) {
                try {
                  final box = await Hive.openBox<Player>('playerBox');
                  await box.putAt(index, Player(name: newName, handicap: newHandicap));
                  setState(() {
                    players = box.values.toList();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Player $newName updated!'),
                      backgroundColor: Colors.green[600],
                      duration: const Duration(milliseconds: 100),
                    ),
                  );
                  print('PlayerManagementScreen: Updated player to $newName with handicap $newHandicap');
                  // Reset games and notify ScoreEntryScreen
                  await _resetGames();
                  widget.onPlayersChanged?.call();
                  print('PlayerManagementScreen: Notified ScoreEntryScreen');
                } catch (e) {
                  print('PlayerManagementScreen: Error updating player: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating player: $e'),
                      duration: const Duration(milliseconds: 100),
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

  void _deletePlayer(int index) async {
    try {
      final box = await Hive.openBox<Player>('playerBox');
      final player = box.getAt(index);
      await box.deleteAt(index);
      setState(() {
        players = box.values.toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Player ${player?.name} removed!'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(milliseconds: 100),
        ),
      );
      print('PlayerManagementScreen: Deleted player ${player?.name}');
      // Reset games and notify ScoreEntryScreen
      await _resetGames();
      widget.onPlayersChanged?.call();
      print('PlayerManagementScreen: Notified ScoreEntryScreen');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Player data not available'),
          duration: Duration(milliseconds: 100),
        ),
      );
      print('PlayerManagementScreen: Error deleting player: $e');
    }
  }

  void _done() {
    print('PlayerManagementScreen: Navigating back to ScoreEntryScreen');
    Navigator.pop(context); // Return to existing ScoreEntryScreen instance
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      print('PlayerManagementScreen: Showing loading indicator');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('PlayerManagementScreen: Building UI with ${players.length} players');
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              child: Column(
                children: [
                  Row(
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _done,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Done', style: TextStyle(fontSize: 16)),
                      ),
                      ElevatedButton(
                        onPressed: _addPlayer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Add', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16), // Adjusted for SnackBar
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
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 100),
                        child: ListTile(
                          title: Text(
                            player.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Text(
                            'Handicap: ${player.handicap}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
    print('PlayerManagementScreen: Disposing controllers and focus node');
    _nameController.dispose();
    _handicapController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }
}