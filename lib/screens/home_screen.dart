import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import '../models/player.dart';
import '../models/hole.dart';
import 'score_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Player> _players = [];
  bool isLoading = true;
  late Box<Player> playerBox;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    print('HomeScreen: Initializing');
    final stopwatch = Stopwatch()..start();
    setState(() => isLoading = true);
    try {
      // Assume Hive is initialized in main.dart; check if box is open
      playerBox = Hive.box<Player>('playerBox');
      _players = playerBox.values.toList();
      print('HomeScreen: Player data loaded in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('HomeScreen: Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), duration: const Duration(milliseconds: 800)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        print('HomeScreen: Initialization complete in ${stopwatch.elapsedMilliseconds}ms');
      }
    }
  }

  Future<void> _startNewGame() async {
    print('HomeScreen: Start New Game button pressed, showing confirmation dialog');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Start New Game', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to start a new game? All existing players, holes, scores, and game data will be erased.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('HomeScreen: New Game canceled');
      return;
    }

    print('HomeScreen: New Game confirmed');
    final stopwatch = Stopwatch()..start();
    try {
      // Clear boxes only if open
      if (Hive.isBoxOpen('playerBox')) {
        await playerBox.clear();
        print('HomeScreen: Cleared playerBox');
      }
      if (Hive.isBoxOpen('holeBox')) {
        await Hive.box<Hole>('holeBox').clear();
        print('HomeScreen: Cleared holeBox');
      }
      if (Hive.isBoxOpen('scoreBox')) {
        await scoreBox.clear();
        print('HomeScreen: Cleared scoreBox');
      }
      if (Hive.isBoxOpen('nassausettingbox')) {
        await Hive.box('nassausettingbox').clear();
        print('HomeScreen: Cleared nassausettingbox');
      }
      if (Hive.isBoxOpen('skinssettingbox')) {
        await Hive.box('skinssettingbox').clear();
        print('HomeScreen: Cleared skinssettingbox');
      }
      if (mounted) {
        setState(() => _players.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New game started! All games disabled. Please add players.'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 800),
          ),
        );
        print('HomeScreen: Navigating to ScoreEntryScreen');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScoreEntryScreen(resetGames: true)),
        );
        print('HomeScreen: Start New Game completed in ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      print('HomeScreen: Error in _startNewGame: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting new game: $e'), duration: const Duration(milliseconds: 800)),
        );
      }
    }
  }

  Future<void> _viewScoreCard() async {
    print('HomeScreen: Score Card button pressed');
    final stopwatch = Stopwatch()..start();
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScoreEntryScreen(resetGames: false)),
      );
      print('HomeScreen: Score Card navigation completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('HomeScreen: Error in _viewScoreCard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error viewing score card: $e'), duration: const Duration(milliseconds: 800)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen: Building UI, isLoading: $isLoading');
    return Scaffold(
      appBar: AppBar(
        title: const Text('GolfBets', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: isLoading
          ? const Center(
              child: Icon(Icons.hourglass_empty, size: 40, color: Color(0xFF388E3C)),
            )
          : HomeScreenContent(
              onStartNewGame: _startNewGame,
              onViewScoreCard: _viewScoreCard,
            ),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  final VoidCallback onStartNewGame;
  final VoidCallback onViewScoreCard;

  const HomeScreenContent({
    super.key,
    required this.onStartNewGame,
    required this.onViewScoreCard,
  });

  @override
  Widget build(BuildContext context) {
    print('HomeScreenContent: Building');
    return Container(
      color: const Color(0xFFF5FFFA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.golf_course, size: 80, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            const Text(
              'Welcome to GolfBets!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 32),
            StartNewGameButton(onPressed: onStartNewGame),
            const SizedBox(height: 16),
            ScoreCardButton(onPressed: onViewScoreCard),
          ],
        ),
      ),
    );
  }
}

class StartNewGameButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StartNewGameButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    print('StartNewGameButton: Building');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Start New Game',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScoreCardButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ScoreCardButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    print('ScoreCardButton: Building');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Score Card',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



