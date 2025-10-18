import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'features/reminders/presentation/utils/notification_helper.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'injection_container.dart' as di;

import 'features/auth/data/datasources/firebase_auth_datasource.dart' as ds;
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'core/services/firebase_auth_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

import 'features/recipes/domain/entities/recipe.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

// IMPORT THE ADAPTERS FROM diet_widget.dart
import 'features/auth/presentation/widgets/diet_widget.dart' show GenderAdapter, ActivityLevelAdapter, CalorieEntryAdapter;

/// Global key for showing SnackBars globally (especially on web)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shared Preferences provider (to be overridden in main)
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider not overridden. Make sure it is overridden in main.dart',
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables safely from assets
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint("⚠️ .env file not found — continuing without it");
  }

  // ✅ Initialize Firebase once
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("⚠️ Firebase init failed: $e");
  }

  // ✅ Initialize Hive
  await Hive.initFlutter();
  
  // 🆕 REGISTER ADAPTERS - ADD THESE THREE LINES
  Hive.registerAdapter(GenderAdapter());
  Hive.registerAdapter(ActivityLevelAdapter());
  Hive.registerAdapter(CalorieEntryAdapter());
  
  Hive.registerAdapter(RecipeAdapter());
  await Hive.openBox<Recipe>('recipesBox');
  await Hive.openBox('nutritionBox');

  // ✅ Platform-specific notification setup
  if (!kIsWeb) {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'reminder_channel',
          channelName: 'Reminders',
          channelDescription: 'Reminder notifications',
          importance: NotificationImportance.High,
          defaultColor: Colors.red,
          ledColor: Colors.white,
          playSound: true,
          enableVibration: true,
        ),
      ],
    );

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  } else {
    await NotificationHelper.requestPermission();
  }

  // ✅ Shared Preferences
  final prefs = await SharedPreferences.getInstance();

  // ✅ Dependency injection
  await di.init();

  // ✅ Run the app with Riverpod overrides
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          AuthRepositoryImpl(
            ds.FirebaseAuthDataSource(FirebaseAuthService()),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}