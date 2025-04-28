import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../main.dart';
import '../models/player.dart';
import '../models/hole.dart';
import '../models/score_entry.dart';
import 'score_entry_screen.dart';

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
    print('HomeScreen: Loading data');
    setState(() => isLoading = true);
    try {
      if (Hive.isBoxOpen('playerBox')) {
        players = playerBox.values.toList();
      }
      if (Hive.isBoxOpen('holeBox')) {
        holes = Hive.box<Hole>('holeBox').values.toList();
      }
      if (Hive.isBoxOpen('scoreBox')) {
        scores = scoreBox.values.toList();
      }
      print('HomeScreen: Data loaded successfully');
    } catch (e) {
      print('HomeScreen: Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading data')),
      );
    }
    setState(() => isLoading = false);
    print('HomeScreen: isLoading set to false');
  }

  void _startNewGame() {
    print('HomeScreen: Start New Game button pressed');
    try {
      setState(() {
        players.clear();
        holes.clear();
        scores.clear();
        if (Hive.isBoxOpen('playerBox')) {
          playerBox.clear();
          print('HomeScreen: Cleared playerBox');
        } else {
          print('HomeScreen: playerBox not open');
        }
        if (Hive.isBoxOpen('holeBox')) {
          Hive.box<Hole>('holeBox').clear();
          print('HomeScreen: Cleared holeBox');
        } else {
          print('HomeScreen: holeBox not open');
        }
        if (Hive.isBoxOpen('scoreBox')) {
          scoreBox.clear();
          print('HomeScreen: Cleared scoreBox');
        } else {
          print('HomeScreen: scoreBox not open');
        }
        if (Hive.isBoxOpen('nassausettingbox')) {
          Hive.box('nassausettingbox').clear();
          print('HomeScreen: Cleared nassausettingbox');
        } else {
          print('HomeScreen: nassausettingbox not open');
        }
        if (Hive.isBoxOpen('skinssettingbox')) {
          Hive.box('skinssettingbox').clear();
          print('HomeScreen: Cleared skinssettingbox');
        } else {
          print('HomeScreen: skinssettingbox not open');
        }
      });
      print('HomeScreen: Showing SnackBar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New game started! All games disabled. Please add players.'),
          backgroundColor: Colors.green,
        ),
      );
      print('HomeScreen: Navigating to ScoreEntryScreen');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScoreEntryScreen(resetGames: true)),
      );
    } catch (e) {
      print('HomeScreen: Error in _startNewGame: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting new game: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      print('HomeScreen: Showing loading indicator');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('HomeScreen: Building UI');
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startNewGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Start New Game', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





