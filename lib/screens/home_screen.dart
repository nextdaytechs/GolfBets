import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../main.dart';
import '../models/player.dart';
import '../models/hole.dart';
import '../models/score_entry.dart';
import 'score_entry_screen.dart';
import 'player_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Player> players = [];
  List<Hole> holes = [];
  List<ScoreEntry> scores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => isLoading = true);
    try {
      if (Hive.isBoxOpen('playerBox')) {
        players = playerBox.values.toList();
      } else {
        debugPrint("playerBox not open");
      }
      if (Hive.isBoxOpen('holeBox')) {
        holes = holeBox.values.toList();
      } else {
        debugPrint("holeBox not open");
      }
      if (Hive.isBoxOpen('scoreBox')) {
        scores = scoreBox.values.toList();
      } else {
        debugPrint("scoreBox not open");
      }
      debugPrint("Loaded ${players.length} players, ${holes.length} holes, ${scores.length} scores");
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
    setState(() => isLoading = false);
  }

  void _managePlayers() {
    if (Hive.isBoxOpen('playerBox')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PlayerManagementScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Player data not available')),
      );
    }
  }

  void _enterScores() {
    if (Hive.isBoxOpen('scoreBox')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScoreEntryScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Score data not available')),
      );
    }
  }

  void _newGame() {
    setState(() {
      players.clear();
      holes.clear();
      scores.clear();
      if (Hive.isBoxOpen('playerBox')) playerBox.clear();
      if (Hive.isBoxOpen('holeBox')) holeBox.clear();
      if (Hive.isBoxOpen('scoreBox')) scoreBox.clear();
      if (Hive.isBoxOpen('nassauSettingsBox')) nassauSettingsBox.clear();
      if (Hive.isBoxOpen('skinsSettingsBox')) skinsSettingsBox.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New game started!'),
        backgroundColor: Colors.green,
      ),
    );
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
        title: const Text('GolfBets'),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.golf_course, size: 80, color: Colors.green[600]),
              const SizedBox(height: 16),
              Text(
                'Welcome to GolfBets!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _managePlayers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Manage Players', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enterScores,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Enter Scores', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _newGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('New Game', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}







