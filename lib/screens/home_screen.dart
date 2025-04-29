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
  bool isInitializing = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    print('HomeScreen: Initializing');
    final stopwatch = Stopwatch()..start();
    // Brief delay to allow Flutter view setup
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) {
      setState(() => isInitializing = false);
      print('HomeScreen: Initialization complete in ${stopwatch.elapsedMilliseconds}ms');
    }
    _loadData();
  }

  Future<void> _loadData() async {
    print('HomeScreen: Loading data');
    final stopwatch = Stopwatch()..start();
    setState(() => isLoading = true);
    try {
      final playerBox = await Hive.openBox<Player>('playerBox');
      _players = playerBox.values.toList();
      print('HomeScreen: Player data loaded successfully in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('HomeScreen: Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading data'), duration: Duration(milliseconds: 800)),
      );
    }
    // Defer setState to spread main-thread work
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() => isLoading = false);
      print('HomeScreen: isLoading set to false in ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  Future<void> _startNewGame() async {
    print('HomeScreen: Start New Game button pressed');
    final stopwatch = Stopwatch()..start();
    try {
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
      // Defer state update
      await Future.microtask(() {});
      if (mounted) {
        setState(() {
          _players.clear();
        });
        print('HomeScreen: Showing SnackBar');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting new game: $e'), duration: const Duration(milliseconds: 800)),
      );
    }
  }

  Future<void> _viewScoreCard() async {
    print('HomeScreen: Score Card button pressed');
    final stopwatch = Stopwatch()..start();
    try {
      print('HomeScreen: Navigating to ScoreEntryScreen');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScoreEntryScreen(resetGames: false)),
      );
      print('HomeScreen: Score Card navigation completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('HomeScreen: Error in _viewScoreCard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing score card: $e'), duration: const Duration(milliseconds: 800)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen: Building UI, isInitializing: $isInitializing, isLoading: $isLoading');
    if (isInitializing) {
      return const SizedBox.expand(
        child: ColoredBox(color: Color(0xFFF5FFFA)),
      );
    }
    if (isLoading) {
      return const SizedBox.expand(
        child: ColoredBox(
          color: Color(0xFFF5FFFA),
          child: Center(
            child: Icon(Icons.hourglass_empty, size: 40, color: Color(0xFF388E3C)),
          ),
        ),
      );
    }

    return const HomeScreenScaffold();
  }
}

class HomeScreenScaffold extends StatelessWidget {
  const HomeScreenScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    print('HomeScreenScaffold: Building');
    return Scaffold(
      appBar: AppBar(
        title: const Text('GolfBets', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    print('HomeScreenContent: Building');
    return Container(
      color: const Color(0xFFF5FFFA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.golf_course, size: 80, color: Color(0xFF2E7D32)),
            SizedBox(height: 16),
            Text(
              'Welcome to GolfBets!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            SizedBox(height: 32),
            StartNewGameButton(),
            SizedBox(height: 16),
            ScoreCardButton(),
          ],
        ),
      ),
    );
  }
}

class StartNewGameButton extends StatelessWidget {
  const StartNewGameButton({super.key});

  @override
  Widget build(BuildContext context) {
    print('StartNewGameButton: Building');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () => context.findAncestorStateOfType<_HomeScreenState>()?._startNewGame(),
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
  const ScoreCardButton({super.key});

  @override
  Widget build(BuildContext context) {
    print('ScoreCardButton: Building');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: GestureDetector(
          onTap: () => context.findAncestorStateOfType<_HomeScreenState>()?._viewScoreCard(),
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



