import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'injection_container.dart' as di;

// Aliases to prevent duplicate imports
import 'features/auth/data/datasources/firebase_auth_datasource.dart' as ds;
import 'features/auth/data/repositories/auth_repository_impl.dart'; // no alias needed
import 'core/services/firebase_auth_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('recipesBox');
  await Hive.openBox('nutritionBox');

  final prefs = await SharedPreferences.getInstance();
  await di.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          AuthRepositoryImpl( // just use the class directly, no alias
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
