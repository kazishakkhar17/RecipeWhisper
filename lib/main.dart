import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/reminders/presentation/utils/notification_helper.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'injection_container.dart' as di;

// Aliases to prevent duplicate imports
import 'features/auth/data/datasources/firebase_auth_datasource.dart' as ds;
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'core/services/firebase_auth_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

// Import Recipe entity for Hive adapter
import 'features/recipes/domain/entities/recipe.dart';

// Import Awesome Notifications only for mobile
import 'package:awesome_notifications/awesome_notifications.dart';

/// ✅ Global key for web SnackBars
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  
  // Register Recipe adapter
  Hive.registerAdapter(RecipeAdapter());
  
  // Open boxes
  await Hive.openBox<Recipe>('recipesBox');
  await Hive.openBox('nutritionBox');

  // Initialize notifications based on platform
  if (!kIsWeb) {
    // Mobile - use Awesome Notifications
    await AwesomeNotifications().initialize(
      null, // icon for notifications
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

    // Request permission on mobile if not allowed
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  } else {
    // Web - request permission on startup
    await NotificationHelper.requestPermission();
  }

  final prefs = await SharedPreferences.getInstance();
  await di.init();

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

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider not overridden. Override it in main.dart',
  ),
);
