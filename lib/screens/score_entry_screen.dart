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
  const ScoreEntryScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeHiveBoxes();
  }

  Future<void> _initializeHiveBoxes() async {
    setState(() => isLoading = true);
    try {
      playerBox = Hive.box<Player>('playerBox');
      holeBox = Hive.box<Hole>('holeBox');
      scoreBox = Hive.box<ScoreEntry>('scoreBox');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error initializing data')),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _holeNameController.dispose();
    _parController.dispose();
    _handicapRatingController.dispose();
    super.dispose();
  }

  void _showPlayerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlayerManagementScreen(),
      ),
    );
  }

  void _showSkinsRules() {
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
              Text('- Example: 4 players, Hole 1: Max (-1, birdie), Dean (0), P3 (0), P4 (+1). Max beats Dean, P3, P4, earning 3 × (1 + 2) = 9 points. Hole 2: Max vs. Dean ties, 1 point carries over. Hole 3: Max beats Dean, earns 1 + 1 = 2 points.'),
              SizedBox(height: 8),
              Text('Results:'),
              Text('- Head-to-Head Matrix: A table showing points earned against each opponent (e.g., Max: +3 vs. Dean in green, Dean: -3 vs. Max in red, 0 in black). Each cell reflects total points won or lost in pairwise contests.'),
              Text('- Totals: Net points per player (earned minus lost, e.g., Max: +5, Dean: -2).'),
              Text('- Example: "Max: +5, Dean: -2" means Max earned 5 more points than lost across all opponents.'),
              Text('- Ties possible (e.g., Max and Dean both at +5).'),
              Text('- If fewer holes played, shows current results.'),
              SizedBox(height: 8),
              Text('Note: No handicaps are used, rewarding raw scores.'),
              SizedBox(height: 8),
              Text('Tips: Players with aproximate same Handicaps should play this game.'),
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
              Text('- Select players in the Nassau Game setup.'),
              Text('- Choose bet amounts (e.g., 1 point) for Front 9, Back 9, and Overall.'),
              Text('- Optionally enable Skins to compete for points per hole.'),
              Text('- Set points per skin (e.g., 1 point) if Skins is enabled.'),
              SizedBox(height: 8),
              Text('Scoring (Main Bets):'),
              Text('- Scores are relative to par (e.g., +1 for bogey, -1 for birdie). Sum scores for each segment.'),
              Text('- Handicaps adjust scores: Even (e.g., 2) split evenly (1 stroke each for Front 9, Back 9); odd (e.g., 5) give extra to Front 9 (3 strokes), rest to Back 9 (2).'),
              Text('- Front 9: Lowest adjusted score (sum of relative scores minus Front 9 strokes) wins the bet.'),
              Text('- Back 9: Same for holes 10–18, using Back 9 strokes.'),
              Text('- Overall: Lowest adjusted score for 18 holes, using full handicap.'),
              Text('- Example: Max (handicap 2) scores +1 on Front 9, gets 1 stroke, adjusted: 0. Dean (handicap 5) scores +3, gets 3 strokes, adjusted: 0. Result: Tied.'),
              SizedBox(height: 8),
              Text('Optional Skins (Match Play):'),
              Text('- Each hole is a match. Lowest adjusted score wins the skin, but only if no tie.'),
              Text('- Uses same handicap strokes as main bets (e.g., 5 handicap: 3 strokes on holes 1–3, 2 on 10–11). Subtract 1 stroke per applicable hole.'),
              Text('- Example: Hole 1, Max (+1, 1 stroke, adjusted: 0), Wee (+2, 1 stroke, adjusted: 1). Max wins 1 point.'),
              Text('- Ties award no points. Points per skin set in setup (e.g., 1 point).'),
              SizedBox(height: 8),
              Text('Results:'),
              Text('- Main Bets: "Tied: Max(0), wee(0), Bet: 1": Both have the same adjusted score, no points awarded.'),
              Text('- "Winner: Max(-1), Bet: 1": Max’s lowest adjusted score wins the bet.'),
              Text('- Skins: "Leaders: Max(5), Dean(5), Points per Skin: 1": Each won 5 skins, tied for the lead.'),
              Text('- If fewer holes played, shows current leader (e.g., "Leading: Dean(2)").'),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error disabling games')),
      );
    }
  }

  void _addHole() {
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
                final currentHoles = holeBox.values.toList();
                int nextNumber = 1; // Default if no holes exist
                if (currentHoles.isNotEmpty) {
                  final highestNumber = currentHoles.map((h) => h.number).reduce((a, b) => a > b ? a : b);
                  nextNumber = highestNumber + 1;
                }

                await holeBox.add(Hole(
                  number: nextNumber,
                  name: name,
                  par: par,
                  handicapRating: handicapRating,
                ));
                Navigator.pop(context);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hole "$name" added!'),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                }
              } catch (e) {
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
                }
              } catch (e) {
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
                }
              } catch (e) {
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder(
      valueListenable: holeBox.listenable(),
      builder: (context, Box<Hole> holeBoxListenable, _) {
        if (!Hive.isBoxOpen('holeBox') || !Hive.isBoxOpen('playerBox') || !Hive.isBoxOpen('scoreBox')) {
          return const Scaffold(
            body: Center(child: Text('Error: Data not available', style: TextStyle(color: Colors.redAccent))),
          );
        }

        final List<Player> players = playerBox.values.toList()..sort((a, b) => a.name.compareTo(b.name));
        final List<Hole> holes = holeBoxListenable.values.toList()..sort((a, b) => b.number.compareTo(a.number));
        final List<ScoreEntry> scores = scoreBox.values.toList();

        // Show placeholder if no players or holes
        if (players.isEmpty || holes.isEmpty) {
          return Scaffold(
            appBar: AppBar(
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
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Scorecard'),
                  Tab(text: 'Games'),
                ],
              ),
              actions: [
                if (players.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    onPressed: _showPlayerManagement,
                    tooltip: 'Manage Players',
                  ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    players.isEmpty ? 'No players added.' : 'No holes added. Tap the + button to add a hole.',
                    style: const TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                  if (players.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showPlayerManagement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Go to Manage Players'),
                    ),
                  ],
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _addHole,
              backgroundColor: Colors.green[600],
              child: const Icon(Icons.add),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
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
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Scorecard'),
                Tab(text: 'Games'),
              ],
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
                          if (holes.isEmpty)
                            const Center(
                              child: Text(
                                'No holes available.\nTap the + button to add a hole.',
                                style: TextStyle(fontSize: 18, color: Colors.redAccent),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          floatingActionButton: FloatingActionButton(
            onPressed: _addHole,
            backgroundColor: Colors.green[600],
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}