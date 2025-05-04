import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/player.dart';
import '../models/hole.dart';
import '../models/score_entry.dart';
import 'widgets/score_card_widget.dart';
import 'widgets/skins_game_manager.dart';
import 'widgets/nassau_game_manager.dart';
import 'player_management_screen.dart';
import '../main.dart';

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
  bool isLoading = true;
  bool _isDisablingGames = false; // Guard to prevent recursive disable calls
  final _snackBarQueue = <String>[]; // Queue for SnackBar messages
  bool _isShowingSnackBar = false; // Flag to track active SnackBar
  List<Player> _players = []; // Cached players
  List<Hole> _holes = []; // Cached holes
  List<ScoreEntry> _scores = []; // Cached scores

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      print('ScoreEntryScreen: Tab changed to index ${_tabController.index}');
    });
    // Defer initialization to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeHiveBoxes());
  }

  Future<void> _initializeHiveBoxes() async {
    print('ScoreEntryScreen: Initializing Hive boxes');
    final stopwatch = Stopwatch()..start();
    setState(() => isLoading = true);
    try {
      // Use pre-opened boxes from main.dart
      final playerBox = Hive.box<Player>('playerBox');
      final holeBox = Hive.box<Hole>('holeBox');
      final scoreBox = Hive.box<ScoreEntry>('scoreBox');
      // Preload data after first frame
      _players = playerBox.values.toList()..sort((a, b) => a.name.compareTo(b.name));
      _holes = holeBox.values.toList()..sort((a, b) => b.number.compareTo(a.number));
      _scores = scoreBox.values.toList();
      print('ScoreEntryScreen: Data preloaded in ${stopwatch.elapsedMilliseconds}ms');
      if (widget.resetGames && !_isDisablingGames) {
        // Only disable games if resetGames is explicitly set
        Future.microtask(() {
          print('ScoreEntryScreen: Resetting games due to resetGames flag');
          _disableAllGames();
        });
      }
    } catch (e) {
      print('ScoreEntryScreen: Error initializing Hive boxes: $e');
      if (!mounted) return;
      _queueSnackBar('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        print('ScoreEntryScreen: Initialization complete in ${stopwatch.elapsedMilliseconds}ms');
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
          onPlayersChanged: () {
            // Update cached players
            _players = playerBox.values.toList()..sort((a, b) => a.name.compareTo(b.name));
          },
        ),
      ),
    );
    print('ScoreEntryScreen: Returned from PlayerManagementScreen, disabling games');
    _disableAllGames();
  }

  void _newGame() {
    print('ScoreEntryScreen: New Game button pressed, showing confirmation dialog');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Start New Game', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to start a new game? All existing players, holes, scores, and game data will be erased.'),
        actions: [
          TextButton(
            onPressed: () {
              print('ScoreEntryScreen: New Game canceled');
              Navigator.pop(context);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              print('ScoreEntryScreen: New Game confirmed');
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _startNewGame() {
    print('ScoreEntryScreen: Starting new game');
    final stopwatch = Stopwatch()..start();
    try {
      // Batch state updates to reduce rebuilds
      if (Hive.isBoxOpen('playerBox')) {
        playerBox.clear();
        _players.clear();
        print('ScoreEntryScreen: Cleared playerBox');
      }
      if (Hive.isBoxOpen('holeBox')) {
        holeBox.clear();
        _holes.clear();
        print('ScoreEntryScreen: Cleared holeBox');
      }
      if (Hive.isBoxOpen('scoreBox')) {
        scoreBox.clear();
        _scores.clear();
        print('ScoreEntryScreen: Cleared scoreBox');
      }
      if (Hive.isBoxOpen('nassausettingbox')) {
        nassauSettingsBox.clear();
        print('ScoreEntryScreen: Cleared nassausettingbox');
      }
      if (Hive.isBoxOpen('skinssettingbox')) {
        skinsSettingsBox.clear();
        print('ScoreEntryScreen: Cleared skinssettingbox');
      }
      _disableAllGames(); // Explicitly disable game managers
      _queueSnackBar('New game started!', backgroundColor: Colors.green, duration: const Duration(milliseconds: 800));
      // Single setState to minimize rebuilds
      setState(() {});
      print('ScoreEntryScreen: New game completed in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('ScoreEntryScreen: Error in newGame: $e');
      _queueSnackBar('Error starting new game: $e', duration: const Duration(milliseconds: 800));
    }
  }

  void _showSkinsRules() {
    print('ScoreEntryScreen: Showing Skins game rules');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Whittier Skins Game Rules', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
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
              Text('- Example: 4 players, Hole 1: Dean (-1, birdie), Mark (0), P3 (0), P4 (+1). Dean beats Mark, P3, P4, earning 3 × (1 + 2) = 9 points. Hole 2: Dean vs. Mark ties, 1 point carries over. Hole 3: Dean beats Mark, earns 1 + 1 = 2 points.'),
              SizedBox(height: 8),
              Text('Results:'),
              Text('- Head-to-Head Matrix: A table showing points earned against each opponent (e.g., Dean: +3 vs. Mark in green, Mark: -3 vs. Dean in red, 0 in black). Each cell reflects total points won or lost in pairwise contests.'),
              Text('- Totals: Net points per player (earned minus lost, e.g., Dean: +5, Mark: -2).'),
              Text('- Example: "Dean: +5, Mark: -2" means Dean earned 5 more points than lost across all opponents.'),
              Text('- Ties possible (e.g., Dean and Mark both at +5).'),
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
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Objective: Compete in a stroke play format across three bets—Front 9, Back 9, and Overall—based on the lowest handicap-adjusted scores, with an optional Skins side bet for winning individual holes in match play.'),
              SizedBox(height: 8),
              Text('Setup:'),
              Text('- Select players in the Nassau Game setup.'),
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
              Text('- Example: Dean (handicap 2) scores +1 on Front 9, gets 1 stroke, adjusted: 0. Mark (handicap 5) scores +3, gets 3 strokes, adjusted: 0. Result: Tied.'),
              SizedBox(height: 8),
              Text('Optional Skins (Match Play):'),
              Text('- Each hole is a match. Lowest adjusted score wins the skin, but only if no tie.'),
              Text('- Uses same handicap strokes as main bets (e.g., 5 handicap: 3 strokes on holes 1–3, 2 on 10–11). Subtract 1 stroke per applicable hole.'),
              Text('- Example: Hole 1, Dean (+1, 1 stroke, adjusted: 0), Mark (+2, 1 stroke, adjusted: 1). Dean wins 1 point.'),
              Text('- Ties award no points. Points per skin set in setup (e.g., 1 point).'),
              SizedBox(height: 8),
              Text('Results:'),
              Text('- Main Bets: "Tied: Dean(0), Mark(0), Bet: 1": Both have the same adjusted score, no points awarded.'),
              Text('- "Winner: Dean(-1), Bet: 1": Dean’s lowest adjusted score wins the bet.'),
              Text('- Skins: "Leaders: Dean(5), Mark(5), Points per Skin: 1": Each won 5 skins, tied for the lead.'),
              Text('- If fewer holes played, shows current leader (e.g., "Leading: Mark(2)").'),
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

  void _queueSnackBar(String message, {Color? backgroundColor, Duration? duration}) {
    _snackBarQueue.add(message);
    _showNextSnackBar(backgroundColor: backgroundColor, duration: duration);
  }

  void _showNextSnackBar({Color? backgroundColor, Duration? duration}) {
    if (_isShowingSnackBar || _snackBarQueue.isEmpty || !mounted) return;
    _isShowingSnackBar = true;
    final message = _snackBarQueue.removeAt(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Theme.of(context).snackBarTheme.backgroundColor,
        duration: duration ?? const Duration(milliseconds: 800),
      ),
    ).closed.then((_) {
      _isShowingSnackBar = false;
      _showNextSnackBar(backgroundColor: backgroundColor, duration: duration);
    });
  }

  void _disableAllGames() {
    if (_isDisablingGames) {
      print('ScoreEntryScreen: Skipping disableAllGames to prevent recursion');
      return;
    }
    print('ScoreEntryScreen: Disabling all games');
    final stopwatch = Stopwatch()..start();
    _isDisablingGames = true;
    try {
      _skinsKey.currentState?.disable();
      _nassauKey.currentState?.disable();
      if (!mounted) return;
      _queueSnackBar('', backgroundColor: Colors.redAccent, duration: const Duration(milliseconds: 800));
      // Defer rebuild to avoid jank
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
          print('ScoreEntryScreen: UI rebuilt after disabling games in ${stopwatch.elapsedMilliseconds}ms');
        }
      });
    } catch (e) {
      print('ScoreEntryScreen: Error disabling games: $e');
      if (!mounted) return;
      _queueSnackBar('Error disabling games', duration: const Duration(milliseconds: 800));
    } finally {
      _isDisablingGames = false;
      print('ScoreEntryScreen: DisableAllGames completed in ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  void _addHole() {
    print('ScoreEntryScreen: Opening Add Hole dialog, current tab index: ${_tabController.index}');
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
              SizedBox(height: 8),
              TextField(
                controller: _parController,
                decoration: const InputDecoration(
                  labelText: 'Par',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
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
              print('ScoreEntryScreen: Add Hole dialog: Add button pressed');
              final name = _holeNameController.text.trim();
              final par = int.tryParse(_parController.text.trim()) ?? 4;
              final handicapRating = int.tryParse(_handicapRatingController.text.trim()) ?? 0;

              if (name.isEmpty) {
                if (!mounted) return;
                _queueSnackBar('Please enter a hole name', duration: const Duration(milliseconds: 800));
                return;
              }

              try {
                if (!Hive.isBoxOpen('holeBox')) {
                  if (!mounted) return;
                  _queueSnackBar('Error: Hole data not available', duration: const Duration(milliseconds: 800));
                  return;
                }

                // Auto-generate hole number (highest number + 1 to appear at the top)
                final currentHoles = _holes;
                int nextNumber = 1; // Default if no holes exist
                if (currentHoles.isNotEmpty) {
                  final highestNumber = currentHoles
                      .map((h) => h.number)
                      .reduce((a, b) => a > b ? a : b);
                  nextNumber = highestNumber + 1;
                }

                final newHole = Hole(
                  number: nextNumber,
                  name: name,
                  par: par,
                  handicapRating: handicapRating,
                );
                await holeBox.add(newHole);
                Navigator.pop(context); // Close dialog
                if (mounted) {
                  // Update cached holes and tab index in one setState
                  setState(() {
                    _holes = [..._holes, newHole]..sort((a, b) => b.number.compareTo(a.number));
                    if (_tabController.index != 0) {
                      print('ScoreEntryScreen: Setting tab index to 0 from index: ${_tabController.index}');
                      _tabController.index = 0;
                    }
                  });
                  _queueSnackBar('Hole "$name" added!', backgroundColor: Colors.green[600], duration: const Duration(milliseconds: 800));
                  print('ScoreEntryScreen: Hole "$name" added, final tab index: ${_tabController.index}');
                }
              } catch (e) {
                print('ScoreEntryScreen: Error adding hole: $e');
                if (!mounted) return;
                _queueSnackBar('Error adding hole: $e', duration: const Duration(milliseconds: 800));
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
              SizedBox(height: 8),
              TextField(
                controller: _parController,
                decoration: const InputDecoration(
                  labelText: 'Par',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
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
                  _queueSnackBar('Error: Data not available', duration: const Duration(milliseconds: 800));
                  return;
                }

                // Find the correct index in holeBox by matching the hole object
                final allHoles = _holes;
                final actualIndex = allHoles.indexWhere((h) => h.number == hole.number && h.name == hole.name);
                if (actualIndex == -1) {
                  if (!mounted) return;
                  _queueSnackBar('Error: Hole not found', duration: const Duration(milliseconds: 800));
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

                Navigator.pop(context); // Close dialog
                if (mounted) {
                  setState(() {
                    _holes.removeAt(actualIndex);
                    _scores = scoreBox.values.toList();
                  });
                  _queueSnackBar('Hole "${hole.name}" deleted!', backgroundColor: Colors.redAccent, duration: const Duration(milliseconds: 800));
                  print('ScoreEntryScreen: Hole "${hole.name}" deleted');
                }
              } catch (e) {
                print('ScoreEntryScreen: Error deleting hole: $e');
                if (!mounted) return;
                _queueSnackBar('Error deleting hole: $e', duration: const Duration(milliseconds: 800));
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
                _queueSnackBar('Please enter a hole name', duration: const Duration(milliseconds: 800));
                return;
              }

              try {
                if (!Hive.isBoxOpen('holeBox')) {
                  if (!mounted) return;
                  _queueSnackBar('Error: Hole data not available', duration: const Duration(milliseconds: 800));
                  return;
                }

                // Find the correct index in holeBox
                final allHoles = _holes;
                final actualIndex = allHoles.indexWhere((h) => h.number == hole.number && h.name == hole.name);
                if (actualIndex == -1) {
                  if (!mounted) return;
                  _queueSnackBar('Error: Hole not found', duration: const Duration(milliseconds: 800));
                  return;
                }

                // Update the hole
                final updatedHole = Hole(
                  number: hole.number,
                  name: name,
                  par: par,
                  handicapRating: handicapRating,
                );
                await holeBox.putAt(actualIndex, updatedHole);
                Navigator.pop(context); // Close dialog
                if (mounted) {
                  setState(() {
                    _holes[actualIndex] = updatedHole;
                  });
                  _queueSnackBar('Hole "$name" updated!', backgroundColor: Colors.green[600], duration: const Duration(milliseconds: 800));
                  print('ScoreEntryScreen: Hole "$name" updated');
                }
              } catch (e) {
                print('ScoreEntryScreen: Error editing hole: $e');
                if (!mounted) return;
                _queueSnackBar('Error editing hole: $e', duration: const Duration(milliseconds: 800));
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Enter Scores', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4CAF50),
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
                    _buildTabButton(
                      onPressed: _showPlayerManagement,
                      label1: 'Add',
                      label2: 'Players',
                    ),
                    _buildTabButton(
                      onPressed: _addHole,
                      label1: 'Add',
                      label2: 'Hole',
                    ),
                    _buildTabButton(
                      onPressed: _newGame,
                      label1: 'New',
                      label2: 'Game',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF5FFFA),
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
                      if (_players.isEmpty)
                        const Center(
                          child: Text(
                            'No players added.\nTap the Add Players button to add players.',
                            style: TextStyle(fontSize: 18, color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (_players.isNotEmpty && _holes.isEmpty)
                        Center(
                          child: Text(
                            'Players Added: ${_players.map((p) => p.name).join(', ')}\nPlease add holes to start scoring.',
                            style: const TextStyle(fontSize: 18, color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        ScoreCardWidget(
                          players: _players,
                          holes: _holes,
                          scores: _scores,
                          onScoreChanged: () {
                            if (mounted) {
                              setState(() {
                                _scores = scoreBox.values.toList();
                              });
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
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SkinsGameManager(key: _skinsKey, scores: _scores, players: _players),
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
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: NassauGameManager(key: _nassauKey, scores: _scores, players: _players),
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
  }

  Widget _buildTabButton({required VoidCallback onPressed, required String label1, required String label2}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white, width: 1),
        ),
        fixedSize: const Size(60, 60),
        padding: EdgeInsets.zero,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label1, style: const TextStyle(fontSize: 12)),
          Text(label2, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}