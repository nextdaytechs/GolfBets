import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'models/player.dart';
import 'models/hole.dart';
import 'models/score_entry.dart';
import 'models/nassau_settings.dart';
import 'models/skins_settings.dart';
import 'screens/home_screen.dart';

late Box<Player> playerBox;
late Box<Hole> holeBox;
late Box<ScoreEntry> scoreBox;
late Box<NassauSettings> nassauSettingsBox;
late Box<SkinsSettings> skinsSettingsBox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String errorMessage = '';
  final logMessages = <String>[]; // Buffer logs

  void addLog(String message) {
    if (kDebugMode) {
      logMessages.add("${DateTime.now()}: $message");
    }
  }

  try {
    // Request storage permissions for Android
    if (Platform.isAndroid) {
      addLog("Platform: Android, checking permissions");
      var storageStatus = await Permission.storage.status;
      addLog("Storage permission status: $storageStatus");
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
        addLog("Storage permission request result: $storageStatus");
        if (!storageStatus.isGranted) {
          addLog("Storage permission denied");
        }
      }
    } else {
      addLog("Platform: ${Platform.operatingSystem}, skipping Android-specific permissions");
    }

    // Get storage path
    String hivePath;
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      hivePath = appDocumentDir.path;
      addLog("Primary storage path: $hivePath");
    } catch (e) {
      final tempDir = await getTemporaryDirectory();
      hivePath = tempDir.path;
      addLog("Using fallback storage path: $hivePath");
    }

    // Ensure Hive directory exists
    final hiveDir = Directory('$hivePath/flutter_hive');
    try {
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
        addLog("Created Hive directory: $hivePath/flutter_hive");
      } else {
        addLog("Hive directory already exists: $hivePath/flutter_hive");
      }
    } catch (e) {
      errorMessage = "Error creating Hive directory: $e";
      addLog(errorMessage);
      await _writeLogs(logMessages);
      runApp(ErrorApp(error: errorMessage));
      return;
    }

    await Hive.initFlutter('flutter_hive');
    addLog("Hive initialized");

    Hive.registerAdapter(PlayerAdapter());
    addLog("PlayerAdapter registered");
    Hive.registerAdapter(HoleAdapter());
    addLog("HoleAdapter registered");
    Hive.registerAdapter(ScoreEntryAdapter());
    addLog("ScoreEntryAdapter registered");
    Hive.registerAdapter(NassauSettingsAdapter());
    addLog("NassauSettingsAdapter registered");
    Hive.registerAdapter(SkinsSettingsAdapter());
    addLog("SkinsSettingsAdapter registered");

    playerBox = await Hive.openBox<Player>('playerBox');
    addLog("playerBox opened");
    holeBox = await Hive.openBox<Hole>('holeBox');
    addLog("holeBox opened");
    scoreBox = await Hive.openBox<ScoreEntry>('scoreBox');
    addLog("scoreBox opened");
    nassauSettingsBox = await Hive.openBox<NassauSettings>('nassauSettingsBox');
    addLog("nassauSettingsBox opened");
    skinsSettingsBox = await Hive.openBox<SkinsSettings>('skinsSettingsBox');
    addLog("skinsSettingsBox opened");

    addLog("Initialization complete");
    await _writeLogs(logMessages);
  } catch (e, stackTrace) {
    errorMessage = "Error initializing Hive: $e\nStack trace: $stackTrace";
    addLog(errorMessage);
    await _writeLogs(logMessages);
    runApp(ErrorApp(error: errorMessage));
    return;
  }

  runApp(const MyApp());
}

Future<void> _writeLogs(List<String> messages) async {
  if (messages.isEmpty || !kDebugMode) return;
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/golfbets_log.txt');
    await file.writeAsString(messages.join('\n') + '\n', mode: FileMode.append);
  } catch (e) {
    debugPrint("Failed to write logs: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GolfBets',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomeScreen(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error initializing app data: $error\nLog saved to app directory. Please reinstall or contact support.',
              style: TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}