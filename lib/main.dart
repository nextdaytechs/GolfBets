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

  try {
    // Request storage permissions for Android
    if (Platform.isAndroid) {
      await _writeLog("Platform: Android, checking permissions");
      // Request storage permissions
      var storageStatus = await Permission.storage.status;
      await _writeLog("Storage permission status: $storageStatus");
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
        await _writeLog("Storage permission request result: $storageStatus");
        if (!storageStatus.isGranted) {
          await _writeLog("Storage permission denied");
        }
      }
    } else {
      await _writeLog("Platform: ${Platform.operatingSystem}, skipping Android-specific permissions");
    }

    // Get storage path
    String hivePath;
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      hivePath = appDocumentDir.path;
      await _writeLog("Primary storage path: $hivePath");
    } catch (e) {
      final tempDir = await getTemporaryDirectory();
      hivePath = tempDir.path;
      await _writeLog("Using fallback storage path: $hivePath");
    }

    // Ensure Hive directory exists and is writable
    final hiveDir = Directory('$hivePath/flutter_hive');
    try {
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
        await _writeLog("Created Hive directory: $hivePath/flutter_hive");
      } else {
        await _writeLog("Hive directory already exists: $hivePath/flutter_hive");
      }
    } catch (e) {
      errorMessage = "Error creating Hive directory: $e";
      await _writeLog(errorMessage);
      runApp(ErrorApp(error: errorMessage));
      return;
    }

    await Hive.initFlutter('flutter_hive');
    await _writeLog("Hive initialized");

    Hive.registerAdapter(PlayerAdapter());
    await _writeLog("PlayerAdapter registered");
    Hive.registerAdapter(HoleAdapter());
    await _writeLog("HoleAdapter registered");
    Hive.registerAdapter(ScoreEntryAdapter());
    await _writeLog("ScoreEntryAdapter registered");
    Hive.registerAdapter(NassauSettingsAdapter());
    await _writeLog("NassauSettingsAdapter registered");
    Hive.registerAdapter(SkinsSettingsAdapter());
    await _writeLog("SkinsSettingsAdapter registered");

    playerBox = await Hive.openBox<Player>('playerBox');
    await _writeLog("playerBox opened");
    holeBox = await Hive.openBox<Hole>('holeBox');
    await _writeLog("holeBox opened");
    scoreBox = await Hive.openBox<ScoreEntry>('scoreBox');
    await _writeLog("scoreBox opened");
    nassauSettingsBox = await Hive.openBox<NassauSettings>('nassauSettingsBox');
    await _writeLog("nassauSettingsBox opened");
    skinsSettingsBox = await Hive.openBox<SkinsSettings>('skinsSettingsBox');
    await _writeLog("skinsSettingsBox opened");
  } catch (e, stackTrace) {
    errorMessage = "Error initializing Hive: $e\nStack trace: $stackTrace";
    await _writeLog(errorMessage);
    runApp(ErrorApp(error: errorMessage));
    return;
  }

  await _writeLog("Initialization complete");
  runApp(const MyApp());
}

Future<void> _writeLog(String message) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/golfbets_log.txt');
    await file.writeAsString("${DateTime.now()}: $message\n", mode: FileMode.append);
  } catch (e) {
    debugPrint("Failed to write log: $e");
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