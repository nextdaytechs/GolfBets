import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/player.dart';
import '../models/hole.dart';
import '../models/score_entry.dart';
import 'widgets/score_card_widget.dart';
import 'widgets/skins_game_manager.dart';
import 'widgets/nassau_game_manager.dart';
import 'player_management_screen.dart';

class ScoreEntryScreen extends StatefulWidget {
  final bool resetGames; // Flag to force game reset on new game start

  const ScoreEntryScreen({super.key, this.resetGames = false});

  @override
  State<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends State<ScoreEntryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nassauKey = GlobalKey<NassauGameManagerState>();
  final _skinsKey = GlobalKey<SkinsGameManagerState>();
  final _holeNameController = TextEditingController();
  final _parController = TextEditingController();
  final _handicapRatingController = TextEditingController();
  late Box<Player> playerBox;
  late Box<Hole> holeBox;
  late Box<ScoreEntry> scoreBox;
  bool isLoading = true;
  bool _isDisablingGames = false; // Guard to prevent recursive disable calls

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeHiveBoxes();
  }

  Future<void> _initializeHiveBoxes() async {
    print('ScoreEntryScreen: Initializing Hive boxes');
    setState(() => isLoading = true);
    try {
      playerBox = await Hive.openBox<Player>('playerBox');
      holeBox = await Hive.openBox<Hole>('holeBox');
      scoreBox = await Hive.openBox<ScoreEntry>('scoreBox');
      print('ScoreEntryScreen: Hive boxes opened successfully');
      if (widget.resetGames && !_isDisablingGames) {
        // Defer game disabling to avoid main thread overload
        Future.microtask(() {
          print('ScoreEntryScreen: Resetting games due to resetGames flag');
          _disableAllGames();
        });
      }
    } catch (e) {
      print('ScoreEntryScreen: Error initializing Hive boxes: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        print('ScoreEntryScreen: Initialization complete, isLoading set to false');
      }
    }
  }

  @override
  void dispose() {
    print('ScoreEntryScreen: Disposing controllers and tab controller');
    _tabController.dispose();
    _holeNameController.dispose();
    _parController.dispose();
    _handicapRatingController.dispose();
    super.dispose();
  }

  void _showPlayerManagement() async {
    print('ScoreEntryScreen: Navigating to PlayerManagementScreen');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerManagementScreen(
          onPlayersChanged: _disableAllGames, // Callback to disable games
        ),
      ),
    );
    print('ScoreEntryScreen: Returned from PlayerManagementScreen, disabling games');
    _disableAllGames(); // Ensure games are disabled after returning
  }

  void _newGame() {
    print('ScoreEntryScreen: Starting new game');
    try {
      // Batch state updates to reduce rebuilds
      if (Hive.isBoxOpen('playerBox')) {
        playerBox.clear();
        print('ScoreEntryScreen: Cleared playerBox');
      }
      if (Hive.isBoxOpen('holeBox')) {
        holeBox.clear();
        print('ScoreEntryScreen: Cleared holeBox');
      }
      if (Hive.isBoxOpen('scoreBox')) {
        scoreBox.clear();
        print('ScoreEntryScreen: Cleared scoreBox');
      }
      if (Hive.isBoxOpen('nassausettingbox')) {
        Hive.box('nassausettingbox').clear();
        print('ScoreEntryScreen: Cleared nassausettingbox');
      }
      if (Hive.isBoxOpen('skinssettingbox')) {
        Hive.box('skinssettingbox').clear();
        print('ScoreEntryScreen: Cleared skinssettingbox');
      }
      _disableAllGames(); // Explicitly disable game managers
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New game started! All games disabled. Please add players.'),
          backgroundColor: Colors.green,
        ),
      );
      print('ScoreEntryScreen: Showing new game SnackBar');
      // Single setState to minimize rebuilds
      setState(() {});
    } catch (e) {
      print('ScoreEntryScreen: Error in newGame: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting new game: $e')),
      );
    }
  }

  void _showSkinsRules() {
    print('ScoreEntryScreen: Showing Skins game rules');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Whittier Skins Game Rules', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Objective: Compete in a match play format where every player challenges every other player to win individual holes, earning points for each victory.'),
              SizedBox(height: 8),
              Text('Setup:'),
              Text('- Select players in the Whittier Skins Game setup.'),
              Text('- Set points per skin (e.g., 1 point), birdie bonus (e.g., 2 points), eagle bonus (e.g., 4 points), and albatros bonus (e.g., 5 points).'),
              Text('- Enable or disable Carry Over to accumulate points for tied holes.'),
              SizedBox(height: 8),
              Text('Scoring:'),
              Text('- Score relative to par (e.g., +1 for bogey, -1 for birdie, -2 for eagle, ≤-3 for albatros).'),
              Text('- Each player competes against every other player per hole. Lowest score beats each higher-scoring opponent, earning points, unless tied.'),
              Text('- Points: Base points (e.g., 1) plus bonuses for birdie (-1 score, e.g., 2 points), eagle (-2, e.g., 4 points), or albatros (≤-3, e.g., 5 points) per opponent beaten.'),
              Text('- Carry Over: If enabled, tied pairs (e.g., P1 vs. P2) accumulate base points (e.g., 1 point per tie), awarded when one beats the other outright.'),
              Text('- Example: 4 players, Hole 1: Tyy (-1, birdie), Wee (0), P3 (0), P4 (+1). Tyy beats Wee, P3, P4, earning 3 × (1 + 2) = 9 points. Hole 2: Tyy vs. Wee ties, 1 point carries over. Hole 3: Tyy beats Wee, earns 1 + 1 = 2 points.'),
              SizedBox(height: 8),
              Text('Results:'),
              Text('- Head-to-Head Matrix: A table showing points earned against each opponent (e.g., Tyy: +3 vs. Wee in green, Wee: -3 vs. Tyy in red, 0 in black). Each cell reflects total points won or lost in pairwise contests.'),
              Text('- Totals: Net points per player (earned minus lost, e.g., Tyy: +5, Wee: -2).'),
              Text('- Example: "Tyy: +5, Wee: -2" means Tyy earned 5 more points than lost across all opponents.'),
              Text('- Ties possible (e.g., Tyy and Wee both at +5).'),
              Text('- If fewer holes played, shows current results.'),
              SizedBox(height: 8),
              Text('Note: No handicaps are used, rewarding raw scores.'),
              SizedBox(height: 8),
              Text('Tips: Aim for birdies or better to earn bonuses, avoid ties to claim Carry Over points, and play aggressively on par 5s for albatros chances.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showNassauRules() {
    print('ScoreEntryScreen: Showing Nassau game rules');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Nassau Game Rules', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Objective: Compete in a stroke play format across three bets—Front 9, Back 9, and Overall—based on the lowest handicap-adjusted scores, with an optional Skins side bet for winning individual holes in match play.'),
              SizedBox(height: 8),
              Text('Setup:'),
              Text('- Select players and set handicaps (e.g., 5) in the Nassau Game setup.'),
              Text('- Choose bet amounts (e.g., 1 point) for Front 9, Back 9, and Overall.'),
              Text('- Optionally enable Skins to compete for points per hole (distinct from the standalone Skins game).'),
              Text('- Set points per skin (e.g., 1 point) if Skins is enabled.'),
              SizedBox(height: 8),
              Text('Scoring (Main Bets):'),
              Text('- Scores are relative to par (e.g., +1 for bogey, -1 for birdie). Sum scores for each segment.'),
              Text('- Handicaps adjust scores: Even (e.g., 2) split evenly (1 stroke each for Front 9, Back 9); odd (e.g., 5) give extra to Front 9 (3 strokes), rest to Back 9 (2).'),
              Text('- Front 9: Lowest adjusted score (sum of relative scores minus Front 9 strokes) wins the bet.'),
              Text('- Back 9: Same for holes 10–18, using Back 9 strokes.'),
              Text('- Overall: Lowest adjusted score for 18 holes, using full handicap.'),
              Text('- Example: Tyy (handicap 2) scores +1 on Front 9, gets 1 stroke, adjusted: 0. Wee (handicap 5) scores +3, gets 3 strokes, adjusted: 0. Result: Tied.'),
              SizedBox(height: 8),
              Text('Optional Skins (Match Play):'),
              Text('- Each hole is a match. Lowest adjusted score wins the skin, but only if no tie.'),
              Text('- Uses same handicap strokes as main bets (e.g., 5 handicap: 3 strokes on holes 1–3, 2 on 10–11). Subtract 1 stroke per applicable hole.'),
              Text('- Example: Hole 1, Tyy (+1, 1 stroke, adjusted: 0), Wee (+2, 1 stroke, adjusted: 1). Tyy wins 1 point.'),
              Text('- Ties award no points. Points per skin set in setup (e.g., 1 point).'),
              SizedBox(height: 8),
              Text('Results:'),
              Text('- Main Bets: "Tied: tyy(0), wee(0), Bet: 1": Both have the same adjusted score, no points awarded.'),
              Text('- "Winner: tyy(-1), Bet: 1": Tyy’s lowest adjusted score wins the bet.'),
              Text('- Skins: "Leaders: tyy(5), wee(5), Points per Skin: 1": Each won 5 skins, tied for the lead.'),
              Text('- If fewer holes played, shows current leader (e.g., "Leading: wee(2)").'),
              SizedBox(height: 8),
              Text('Tips: Set accurate handicaps, aim for low scores in each segment, and enable Skins to compete for holes in match play.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _disableAllGames() {
    if (_isDisablingGames) {
      print('ScoreEntryScreen: Skipping disableAllGames to prevent recursion');
      return;
    }
    print('ScoreEntryScreen: Disabling all games');
    _isDisablingGames = true;
    try {
      _skinsKey.currentState?.disable();
      _nassauKey.currentState?.disable();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All games disabled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Force rebuild to ensure UI updates
      if (mounted) {
        setState(() {});
        print('ScoreEntryScreen: UI rebuilt after disabling games');
      }
    } catch (e) {
      print('ScoreEntryScreen: Error disabling games: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error disabling games')),
      );
    } finally {
      _isDisablingGames = false;
      print('ScoreEntryScreen: DisableAllGames completed');
    }
  }

  void _addHole() {
    print('ScoreEntryScreen: Opening Add Hole dialog');
    _holeNameController.clear();
    _parController.text = '4';
    _handicapRatingController.text = '0';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Hole'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _holeNameController,
                decoration: const InputDecoration(
                  labelText: 'Hole Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _parController,
                decoration: const InputDecoration(
                  labelText: 'Par',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _handicapRatingController,
                decoration: const InputDecoration(
                  labelText: 'Handicap Rating',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () async {
              final name = _holeNameController.text.trim();
              final par = int.tryParse(_parController.text.trim()) ?? 4;
              final handicapRating = int.tryParse(_handicapRatingController.text.trim()) ?? 0;

              if (name.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a hole name')),
                );
                return;
              }

              try {
                if (!Hive.isBoxOpen('holeBox')) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Hole data not available')),
                  );
                  return;
                }

                // Auto-generate hole number (highest number + 1 to appear at the top)
                final currentHoles = Hive.box<Hole>('holeBox').values.toList();
                int nextNumber = 1; // Default if no holes exist
                if (currentHoles.isNotEmpty) {
                  final highestNumber = currentHoles
                      .map((h) => h.number)
                      .reduce((a, b) => a > b ? a : b);
                  nextNumber = highestNumber + 1;
                }

                await Hive.box<Hole>('holeBox').add(Hole(
                  number: nextNumber,
                  name: name,
                  par: par,
                  handicapRating: handicapRating,
                ));
                Navigator.pop(context);
                if (mounted) {
                  // Switch to Scorecard tab and refresh UI
                  _tabController.animateTo(0);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hole "$name" added!'),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                  print('ScoreEntryScreen: Hole "$name" added, switched to Scorecard tab');
                }
              } catch (e) {
                print('ScoreEntryScreen: Error adding hole: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding hole: $e')),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _editHole(Hole hole, int index) {
    print('ScoreEntryScreen: Opening Edit Hole dialog for hole ${hole.name}');
    _holeNameController.text = hole.name;
    _parController.text = hole.par.toString();
    _handicapRatingController.text = hole.handicapRating.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit Hole'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _holeNameController,
                decoration: const InputDecoration(
                  labelText: 'Hole Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _parController,
                decoration: const InputDecoration(
                  labelText: 'Par',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _handicapRatingController,
                decoration: const InputDecoration(
                  labelText: 'Handicap Rating',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (!Hive.isBoxOpen('holeBox') || !Hive.isBoxOpen('scoreBox')) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Data not available')),
                  );
                  return;
                }

                // Find the correct index in holeBox by matching the hole object
                final allHoles = holeBox.values.toList();
                final actualIndex = allHoles.indexWhere((h) => h.number == hole.number && h.name == hole.name);
                if (actualIndex == -1) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Hole not found')),
                  );
                  return;
                }

                // Delete the hole
                await holeBox.deleteAt(actualIndex);
                // Delete associated scores
                final scoreBox = Hive.box<ScoreEntry>('scoreBox');
                final scoresToDelete = scoreBox.values
                    .where((score) => score.holeNumber == hole.number)
                    .toList();
                for (var score in scoresToDelete) {
                  await score.delete();
                }

                Navigator.pop(context);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hole "${hole.name}" deleted!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  print('ScoreEntryScreen: Hole "${hole.name}" deleted');
                }
              } catch (e) {
                print('ScoreEntryScreen: Error deleting hole: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting hole: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () async {
              final name = _holeNameController.text.trim();
              final par = int.tryParse(_parController.text.trim()) ?? 4;
              final handicapRating = int.tryParse(_handicapRatingController.text.trim()) ?? 0;

              if (name.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a hole name')),
                );
                return;
              }

              try {
                if (!Hive.isBoxOpen('holeBox')) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Hole data not available')),
                  );
                  return;
                }

                // Find the correct index in holeBox
                final allHoles = holeBox.values.toList();
                final actualIndex = allHoles.indexWhere((h) => h.number == hole.number && h.name == hole.name);
                if (actualIndex == -1) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Hole not found')),
                  );
                  return;
                }

                // Update the hole
                await holeBox.putAt(
                  actualIndex,
                  Hole(
                    number: hole.number,
                    name: name,
                    par: par,
                    handicapRating: handicapRating,
                  ),
                );
                Navigator.pop(context);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hole "$name" updated!'),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                  print('ScoreEntryScreen: Hole "$name" updated');
                }
              } catch (e) {
                print('ScoreEntryScreen: Error editing hole: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error editing hole: $e')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      print('ScoreEntryScreen: Showing loading indicator due to isLoading = true');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('ScoreEntryScreen: Building UI');
    return ValueListenableBuilder(
      valueListenable: playerBox.listenable(),
      builder: (context, Box<Player> playerBoxListenable, _) {
        return ValueListenableBuilder(
          valueListenable: holeBox.listenable(),
          builder: (context, Box<Hole> holeBoxListenable, _) {
            if (!Hive.isBoxOpen('holeBox') || !Hive.isBoxOpen('playerBox') || !Hive.isBoxOpen('scoreBox')) {
              print('ScoreEntryScreen: Error: Hive boxes not open');
              return const Scaffold(
                body: Center(child: Text('Error: Data not available', style: TextStyle(color: Colors.redAccent))),
              );
            }

            final List<Player> players = playerBox.values.toList()..sort((a, b) => a.name.compareTo(b.name));
            final List<Hole> holes = holeBoxListenable.values.toList()..sort((a, b) => b.number.compareTo(a.number));
            final List<ScoreEntry> scores = scoreBox.values.toList();

            print('ScoreEntryScreen: Rendering with ${players.length} players and ${holes.length} holes');
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Enter Scores', style: TextStyle(color: Colors.white)),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48.0 + 60.0), // TabBar height + button row height
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        tabs: const [
                          Tab(text: 'Scorecard'),
                          Tab(text: 'Games'),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _showPlayerManagement,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Colors.white, width: 1),
                                ),
                                fixedSize: const Size(60, 60),
                                padding: EdgeInsets.zero,
                                elevation: 4,
                                shadowColor: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Add', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  Text('Players', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _addHole,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Colors.white, width: 1),
                                ),
                                fixedSize: const Size(60, 60),
                                padding: EdgeInsets.zero,
                                elevation: 4,
                                shadowColor: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Add', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  Text('Hole', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _newGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: Colors.white, width: 1),
                                ),
                                fixedSize: const Size(60, 60),
                                padding: EdgeInsets.zero,
                                elevation: 4,
                                shadowColor: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('New', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  Text('Game', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              if (players.isEmpty)
                                const Center(
                                  child: Text(
                                    'No players added.\nTap the Add Players button to add players.',
                                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else if (players.isNotEmpty && holes.isEmpty)
                                Center(
                                  child: Text(
                                    'Players Added: ${players.map((p) => p.name).join(', ')}\nPlease add holes to start scoring.',
                                    style: const TextStyle(fontSize: 18, color: Colors.green),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else
                                ScoreCardWidget(
                                  players: players,
                                  holes: holes,
                                  scores: scores,
                                  onScoreChanged: () {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  },
                                  onEditHole: _editHole,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available Games',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              TextButton(
                                onPressed: _disableAllGames,
                                child: const Text("Reset All Games", style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SkinsGameManager(key: _skinsKey, scores: scores, players: players),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.green),
                                onPressed: _showSkinsRules,
                                tooltip: 'Whittier Skins Game Rules',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: NassauGameManager(key: _nassauKey, scores: scores, players: players),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.green),
                                onPressed: _showNassauRules,
                                tooltip: 'Nassau Game Rules',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}