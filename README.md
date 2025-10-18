<!--# bli_flutter_recipewhisper

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
-->

# 🍳 Recipe Whisper

> Your intelligent cooking companion powered by AI

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)](https://flutter.dev)

Recipe Whisper is a cross-platform mobile application that transforms your cooking experience with AI-powered recipe generation, smart timers, calorie tracking, and personalized meal management.

---

## ✨ Features

### 🤖 AI Recipe Generation
- **Conversational AI** - Chat with our AI to create custom recipes
- **Instant Recipe Creation** - Just describe what you want to cook
- **Auto-Save** - Generated recipes automatically saved to your collection
- **Powered by Groq API** - Fast and accurate AI responses

### 📖 Recipe Management
- **Full CRUD Operations** - Create, read, update, and delete recipes
- **Smart Search** - Find recipes by name, description, or category
- **Local Storage** - All recipes stored locally with Hive
- **Default Recipes** - Comes with curated starter recipes
- **Categories** - Organize recipes (Breakfast, Lunch, Dinner, Dessert, etc.)

### ⏰ Smart Cooking Timer
- **Step-by-Step Guidance** - Follow recipes with interactive instructions
- **Visual Progress** - Beautiful progress indicators and status messages
- **Pause & Resume** - Flexible timer control
- **Persistent State** - Timer survives app restart
- **Completion Notifications** - Get notified when cooking is done

### 📊 Diet & Calorie Tracking
- **BMR Calculator** - Automatic daily calorie goal calculation
- **Manual Entry** - Log meals with known calorie counts
- **AI Prediction** - Let AI estimate calories from food descriptions
- **Progress Tracking** - Visual daily calorie consumption
- **Activity Levels** - Customize based on your lifestyle

### 🔔 Meal Reminders
- **Schedule Reminders** - Never miss a meal
- **Local Notifications** - Works on mobile devices
- **Toggle Control** - Enable/disable reminders easily
- **Persistent Storage** - Reminders saved across sessions

### 🌐 Multi-Language Support
- **English & Bangla** - Full app translation
- **Easy Toggle** - Switch languages with one tap
- **Dynamic UI** - All text updates instantly

### 🌙 Dark Mode
- **Beautiful Themes** - Carefully crafted light and dark modes
- **Auto-Persist** - Remembers your preference
- **Smooth Transitions** - Elegant theme switching

### 🔐 Authentication
- **Firebase Auth** - Secure email/password authentication
- **Password Reset** - Easy account recovery
- **Profile Management** - Customize your profile

---

## 📱 Screenshots

| Home Screen | AI Chat | Cooking Timer | Diet Tracker |
|-------------|---------|---------------|--------------|
| ![Home](screenshots/home.png) | ![AI](screenshots/ai.png) | ![Timer](screenshots/timer.png) | ![Diet](screenshots/diet.png) |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (3.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.0 or higher)
- [Firebase Account](https://firebase.google.com/)
- [Groq API Key](https://console.groq.com/) (for AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/recipe-whisper.git
   cd recipe-whisper
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for your project
   flutterfire configure
   ```

4. **Set up environment variables**
   
   Create `assets/.env` file:
   ```env
   GROQ_API_KEY=your_groq_api_key_here
   GROQ_MODEL=llama-3.3-70b-versatile
   ```

5. **Add default recipes (optional)**
   
   Create `assets/default_recipes.json` with sample recipes:
   ```json
   [
     {
       "id": "recipe_1",
       "name": "Classic Pancakes",
       "description": "Fluffy breakfast pancakes",
       "category": "Breakfast",
       "cookingTimeMinutes": 20,
       "calories": 350,
       "ingredients": ["1 cup flour", "2 eggs", "1 cup milk"],
       "instructions": ["Mix ingredients", "Cook on griddle", "Serve hot"]
     }
   ]
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

---

## 🏗️ Architecture

Recipe Whisper follows **Clean Architecture** principles with a feature-based structure:

```
lib/
├── core/                 # Shared utilities
│   ├── constants/       # App constants
│   ├── localization/    # Multi-language support
│   ├── router/          # Navigation
│   ├── services/        # Core services
│   ├── theme/           # Theme configuration
│   └── widgets/         # Reusable widgets
│
└── features/            # Feature modules
    ├── ai_suggestions/  # AI recipe generation
    ├── auth/            # Authentication
    ├── recipes/         # Recipe management
    ├── reminders/       # Meal reminders
    └── animations/      # Splash & animations
```

Each feature follows:
- **Data Layer** - Data sources and repositories
- **Domain Layer** - Entities and use cases
- **Presentation Layer** - UI, providers, and widgets

---

## 🛠️ Tech Stack

### Framework & Language
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language

### State Management
- **Riverpod** - Modern reactive state management

### Backend & Storage
- **Firebase Auth** - User authentication
- **Hive** - Fast local NoSQL database
- **Shared Preferences** - Simple key-value storage

### AI & APIs
- **Groq API** - AI-powered recipe generation
- **HTTP** - Network requests

### UI & Animations
- **Rive** - Advanced animations
- **Awesome Notifications** - Local notifications
- **Go Router** - Declarative routing

### Utilities
- **Intl** - Internationalization
- **Flutter Dotenv** - Environment variables

---

## 📦 Key Packages

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.4.0 | State management |
| `firebase_core` | ^2.24.0 | Firebase initialization |
| `firebase_auth` | ^4.15.0 | Authentication |
| `hive_flutter` | ^1.1.0 | Local database |
| `go_router` | ^12.1.3 | Navigation |
| `http` | ^1.1.0 | API calls |
| `rive` | ^0.12.4 | Animations |
| `awesome_notifications` | ^0.8.2 | Notifications |
| `intl` | ^0.18.1 | Date/time formatting |
| `flutter_dotenv` | ^5.1.0 | Environment config |

---

## 🔑 Configuration

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add apps for Android, iOS, and Web
3. Run `flutterfire configure`
4. Enable Email/Password authentication in Firebase Console

### Groq API Setup

1. Sign up at [Groq Console](https://console.groq.com/)
2. Generate an API key
3. Add to `assets/.env` file

### Environment Variables

Required in `assets/.env`:
```env
GROQ_API_KEY=your_key_here
GROQ_MODEL=llama-3.3-70b-versatile
```

---

## 📖 Usage

### Creating Recipes with AI

1. Navigate to the **AI** tab
2. Type your request: "Create a chocolate cake recipe"
3. AI generates a complete recipe with ingredients and instructions
4. Recipe is automatically saved to your collection

### Cooking with Timer

1. Open any recipe
2. Tap "Start Cooking"
3. Follow step-by-step instructions
4. Timer shows progress with visual indicators
5. Get notification when cooking is complete

### Tracking Calories

1. Go to **Profile** tab
2. Tap "View Diet Profile"
3. Fill in your details (age, height, weight, activity level)
4. App calculates your daily calorie goal
5. Log meals manually or use AI prediction

### Setting Reminders

1. Navigate to **Reminders** tab
2. Tap the + button
3. Set time and title
4. Toggle reminder on/off as needed

---

## 🌐 Localization

Currently supports:
- 🇺🇸 English
- 🇧🇩 Bangla (বাংলা)

### Adding New Languages

1. Open `lib/core/constants/app_strings.dart`
2. Add new language map:
   ```dart
   static const Map<String, String> es = {
     'welcome': 'Bienvenido',
     // ... other translations
   };
   ```
3. Update `getStrings()` method
4. Add locale to `lib/core/constants/locales.dart`

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

---

## 📦 Building

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Windows
```bash
flutter build windows --release
```

---

## 🐛 Known Issues & Solutions

| Issue | Solution |
|-------|----------|
| Firebase init fails | Run `flutterfire configure` again |
| Hive errors | Run `flutter pub run build_runner build` |
| Notifications not working | Check permissions in device settings |
| Default recipes not loading | Verify `assets/default_recipes.json` exists |

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable names
- Add comments for complex logic
- Write tests for new features

---

## 🗺️ Roadmap

### Version 1.1
- [ ] Recipe image upload
- [ ] Social sharing
- [ ] Recipe ratings
- [ ] Cloud backup

### Version 1.2
- [ ] Grocery list generation
- [ ] Meal planning calendar
- [ ] Voice commands
- [ ] Recipe import from URLs

### Version 2.0
- [ ] Multi-user profiles
- [ ] Recipe collections
- [ ] Advanced search filters
- [ ] Nutritional analysis charts

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Recipe Whisper Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

See also the list of [contributors](https://github.com/yourusername/recipe-whisper/contributors) who participated in this project.

---

## 🙏 Acknowledgments

- [Flutter Team](https://flutter.dev) - Amazing framework
- [Groq](https://groq.com) - Powerful AI API
- [Firebase](https://firebase.google.com) - Backend services
- [Hive](https://github.com/hivedb/hive) - Fast local storage
- [Riverpod](https://riverpod.dev) - State management
- All open-source contributors

---

## 📞 Support

- 📧 Email: support@recipewhisper.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/recipe-whisper/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/recipe-whisper/discussions)
- 📖 Documentation: [Full Docs](DOCUMENTATION.md)

---

## 📊 Project Stats

![GitHub stars](https://img.shields.io/github/stars/yourusername/recipe-whisper?style=social)
![GitHub forks](https://img.shields.io/github/forks/yourusername/recipe-whisper?style=social)
![GitHub issues](https://img.shields.io/github/issues/yourusername/recipe-whisper)
![GitHub pull requests](https://img.shields.io/github/issues-pr/yourusername/recipe-whisper)

---

<div align="center">

Made with ❤️ by Recipe Whisper Team

⭐ Star us on GitHub — it helps!

[Website](https://recipewhisper.com) • [Twitter](https://twitter.com/recipewhisper) • [Instagram](https://instagram.com/recipewhisper)

</div>