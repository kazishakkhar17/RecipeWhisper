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

/// Global key for showing SnackBars globally (especially on web)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on supported platforms
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase initialization failed on Linux, continue without it
      print('Firebase initialization skipped on Linux: $e');
    }
  }
  // ✅ Load environment variables (.env)
  await dotenv.load(fileName: '.env');

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(RecipeAdapter());

  // ✅ Open Hive boxes
  await Hive.openBox<Recipe>('recipesBox');
  await Hive.openBox('nutritionBox');

  // ✅ Platform-specific notification setup
  if (!kIsWeb) {
    // Mobile - Awesome Notifications
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

    // Ask user for permission
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  } else {
    // Web notifications
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

/// ✅ Shared Preferences provider (overridden above)
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider not overridden. Make sure it is overridden in main.dart',
  ),
);
