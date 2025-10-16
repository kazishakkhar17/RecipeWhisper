// diet_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../ai_suggestions/data/services/ai_services.dart';





enum Gender { male, female }
enum ActivityLevel { sedentary, light, moderate, veryActive, extraActive }

class CalorieEntry {
  final String id;
  final String name;
  final double calories;
  final DateTime timestamp;
  final bool isAiPredicted;

  CalorieEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.timestamp,
    this.isAiPredicted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'timestamp': timestamp.toIso8601String(),
      'isAiPredicted': isAiPredicted,
    };
  }

  factory CalorieEntry.fromMap(Map<dynamic, dynamic> map) {
    return CalorieEntry(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      timestamp: DateTime.parse(map['timestamp']),
      isAiPredicted: map['isAiPredicted'] ?? false,
    );
  }
}

// Preview Widget - Shown in profile screen
class DietWidget extends StatefulWidget {
  const DietWidget({super.key});

  @override
  State<DietWidget> createState() => _DietWidgetState();
}

class _DietWidgetState extends State<DietWidget> {
  late Box _dietBox;
  late Box _calorieBox;
  bool _isInitialized = false;
  double _dailyCalories = 0;
  List<CalorieEntry> _todayEntries = [];

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    _dietBox = await Hive.openBox('user_diet_box');
    _calorieBox = await Hive.openBox('calorie_tracking_box');

    _dailyCalories = _dietBox.get('dailyCalories', defaultValue: 2000.0);
    _checkAndResetDaily();
    _loadTodayEntries();
    
    setState(() => _isInitialized = true);
  }

  void _checkAndResetDaily() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = _calorieBox.get('lastActiveDate', defaultValue: '');
    
    if (lastDate != today) {
      // New day detected - keep old data but start fresh tracking
      _calorieBox.put('lastActiveDate', today);
    }
  }

  void _loadTodayEntries() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final entries = _calorieBox.get(today, defaultValue: []);
    
    _todayEntries = (entries as List)
        .map((e) => CalorieEntry.fromMap(e as Map))
        .toList();
  }

  double get _totalCaloriesToday {
    return _todayEntries.fold(0.0, (sum, entry) => sum + entry.calories);
  }

  double get _remainingCalories {
    return _dailyCalories - _totalCaloriesToday;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final remaining = _remainingCalories;
    final isOverLimit = remaining < 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DietFullScreen(),
          ),
        ).then((_) {
          // Refresh data when coming back
          _loadTodayEntries();
          setState(() {});
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOverLimit
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consumed Today',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${_totalCaloriesToday.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverLimit ? 'Over Limit' : 'Remaining',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '${remaining.abs().toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Diet Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Full Screen Diet & Calorie Tracker
class DietFullScreen extends StatefulWidget {
  const DietFullScreen({super.key});

  @override
  State<DietFullScreen> createState() => _DietFullScreenState();
}

class _DietFullScreenState extends State<DietFullScreen> {
  // Diet Profile Controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _feetController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Calorie Tracker Controllers
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late GroqService _aiService;


  Gender? _gender;
  ActivityLevel? _activityLevel;
  double _dailyCalories = 0;

  late Box _dietBox;
  late Box _calorieBox;
  bool _isInitialized = false;
  bool _useDirectCalories = true;
  bool _isLoadingAI = false;
  bool _showProfileForm = false;

  List<CalorieEntry> _todayEntries = [];

@override
void initState() {
  super.initState();
  _aiService = GroqService(); // initialize here
  _initializeHive();
}


  Future<void> _initializeHive() async {
    _dietBox = await Hive.openBox('user_diet_box');
    _calorieBox = await Hive.openBox('calorie_tracking_box');

    // Load diet profile data
    _ageController.text = _dietBox.get('age', defaultValue: '').toString();
    _weightController.text = _dietBox.get('weight', defaultValue: '').toString();
_feetController.text = _dietBox.get('heightFeet', defaultValue: '0');
_inchesController.text = _dietBox.get('heightInches', defaultValue: '0');

    _gender = _dietBox.get('gender', defaultValue: Gender.male);
    _activityLevel = _dietBox.get('activityLevel', defaultValue: ActivityLevel.sedentary);

    _calculateCalories();
    _loadTodayEntries();
    
    setState(() => _isInitialized = true);
  }

  void _loadTodayEntries() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final entries = _calorieBox.get(today, defaultValue: []);
    
    _todayEntries = (entries as List)
        .map((e) => CalorieEntry.fromMap(e as Map))
        .toList();
  }

  Future<void> _saveTodayEntries() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final entriesMap = _todayEntries.map((e) => e.toMap()).toList();
    await _calorieBox.put(today, entriesMap);
  }

  double _activityMultiplier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.veryActive:
        return 1.725;
      case ActivityLevel.extraActive:
        return 1.9;
      default:
        return 1.2;
    }
  }

  double _heightToCm() {
    final feet = int.tryParse(_feetController.text) ?? 0;
    final inches = int.tryParse(_inchesController.text) ?? 0;
    return (feet * 30.48) + (inches * 2.54);
  }

  void _calculateCalories() {
    final int age = int.tryParse(_ageController.text) ?? 0;
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double height = _heightToCm();
    final double multiplier = _activityMultiplier(_activityLevel ?? ActivityLevel.sedentary);

    if (_gender == Gender.male) {
      _dailyCalories = ((10 * weight + 6.25 * height - 5 * age + 5) * multiplier);
    } else if (_gender == Gender.female) {
      _dailyCalories = ((10 * weight + 6.25 * height - 5 * age - 161) * multiplier);
    } else {
      _dailyCalories = 0;
    }

    _dietBox.put('dailyCalories', _dailyCalories);
  }

  void _saveDietData() {
    _dietBox.put('age', _ageController.text);
    _dietBox.put('heightFeet', _feetController.text);
    _dietBox.put('heightInches', _inchesController.text);
    _dietBox.put('weight', _weightController.text);
    _dietBox.put('gender', _gender);
    _dietBox.put('activityLevel', _activityLevel);

    _calculateCalories();
    setState(() {});
  }

  String _formatHeight() {
    final feet = _feetController.text;
    final inches = _inchesController.text;
    if (feet.isEmpty && inches.isEmpty) return '--';
    return '${feet.isEmpty ? "0" : feet} ft ${inches.isEmpty ? "0" : inches} in';
  }

  double get _totalCaloriesToday {
    return _todayEntries.fold(0.0, (sum, entry) => sum + entry.calories);
  }

  double get _remainingCalories {
    return _dailyCalories - _totalCaloriesToday;
  }

  double get _progressPercentage {
    if (_dailyCalories == 0) return 0;
    return (_totalCaloriesToday / _dailyCalories).clamp(0.0, 1.0);
  }

  Future<void> _addDirectCalorieEntry() async {
    if (_foodNameController.text.isEmpty || _caloriesController.text.isEmpty) {
      _showSnackBar('Please enter food name and calories');
      return;
    }

    final calories = double.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) {
      _showSnackBar('Please enter a valid calorie value');
      return;
    }

    final entry = CalorieEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _foodNameController.text,
      calories: calories,
      timestamp: DateTime.now(),
      isAiPredicted: false,
    );

    setState(() {
      _todayEntries.add(entry);
    });
    
    await _saveTodayEntries();
    
    _foodNameController.clear();
    _caloriesController.clear();
    
    _showSnackBar('Added ${calories.toStringAsFixed(0)} kcal');
  }

Future<void> _addAIPredictedEntry() async {
  if (_foodNameController.text.isEmpty || _amountController.text.isEmpty) {
    _showSnackBar('Please enter food name and amount');
    return;
  }

  setState(() => _isLoadingAI = true);

  try {
    // Build prompt for AI
    final prompt =
        "Estimate calories for ${_amountController.text} of ${_foodNameController.text}. Return only a number.";

    // Call your existing GroqService
    final aiResponse = await _aiService.sendMessage(message: prompt);

    // Extract number from AI response
    final predictedCalories = double.tryParse(
          RegExp(r'[\d.]+').firstMatch(aiResponse)?.group(0) ?? '',
        ) ??
        150.0; // fallback

    final entry = CalorieEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${_foodNameController.text} (${_amountController.text})',
      calories: predictedCalories,
      timestamp: DateTime.now(),
      isAiPredicted: true,
    );

    setState(() {
      _todayEntries.add(entry);
      _isLoadingAI = false;
    });

    await _saveTodayEntries();

    _foodNameController.clear();
    _amountController.clear();

    _showSnackBar('AI predicted ${predictedCalories.toStringAsFixed(0)} kcal');
  } catch (e) {
    setState(() => _isLoadingAI = false);
    _showSnackBar('❌ Error predicting calories: $e');
  }
}


  double _mockAIPrediction(String foodName, String amount) {
    final baseCalories = {
      'rice': 130.0,
      'chicken': 165.0,
      'egg': 78.0,
      'bread': 265.0,
      'apple': 52.0,
      'banana': 89.0,
      'pasta': 131.0,
      'pizza': 266.0,
      'burger': 295.0,
      'salad': 33.0,
    };

    final food = foodName.toLowerCase();
    final multiplier = double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 100;
    
    for (var key in baseCalories.keys) {
      if (food.contains(key)) {
        return (baseCalories[key]! * multiplier) / 100;
      }
    }
    
    return 150.0;
  }

  void _deleteEntry(String id) {
    setState(() {
      _todayEntries.removeWhere((entry) => entry.id == id);
    });
    _saveTodayEntries();
    _showSnackBar('Entry deleted');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diet & Calorie Tracker')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet & Calorie Tracker'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card
            _buildProgressCard(),
            const SizedBox(height: 16),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    color: Colors.blue,
                    icon: Icons.height,
                    title: 'Height',
                    value: _formatHeight(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    color: Colors.orange,
                    icon: Icons.local_fire_department,
                    title: 'Daily Goal',
                    value: _dailyCalories > 0
                        ? '${_dailyCalories.toStringAsFixed(0)}'
                        : '--',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Edit Profile Button
            if (!_showProfileForm)
              OutlinedButton.icon(
                onPressed: () => setState(() => _showProfileForm = true),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Diet Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B6B),
                  side: const BorderSide(color: Color(0xFFFF6B6B)),
                ),
              ),

            // Profile Form (Collapsible)
            if (_showProfileForm) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Diet Profile',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    TextButton(
      onPressed: () => setState(() => _showProfileForm = false),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
    ),
  ],
),

                      const SizedBox(height: 12),
                      TextField(
                        controller: _ageController,
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
      FilteringTextInputFormatter.digitsOnly, // only integers allowed
    ],
                        onChanged: (_) => _saveDietData(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
  child: TextField(
    controller: _feetController,
    decoration: const InputDecoration(labelText: 'Feet'),
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly, // only integers allowed
    ],
    onChanged: (_) => _saveDietData(),
  ),
),
const SizedBox(width: 12),
Expanded(
  child: TextField(
    controller: _inchesController,
    decoration: const InputDecoration(labelText: 'Inches'),
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly, // only integers allowed
    ],
    onChanged: (_) => _saveDietData(),
  ),
),

                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        keyboardType: TextInputType.number,
                            inputFormatters: [
      FilteringTextInputFormatter.digitsOnly, // only integers allowed
    ],
                        onChanged: (_) => _saveDietData(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Gender:'),
                          Radio<Gender>(
                            value: Gender.male,
                            groupValue: _gender,
                            onChanged: (val) {
                              setState(() => _gender = val);
                              _saveDietData();
                            },
                          ),
                          const Text('Male'),
                          Radio<Gender>(
                            value: Gender.female,
                            groupValue: _gender,
                            onChanged: (val) {
                              setState(() => _gender = val);
                              _saveDietData();
                            },
                          ),
                          const Text('Female'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Activity Level:'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ActivityLevel.values.map((level) {
                              final label = level.name
                                  .replaceAllMapped(
                                      RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
                                  .trim();
                              return ChoiceChip(
                                label: Text(label),
                                selected: _activityLevel == level,
                                onSelected: (selected) {
                                  setState(() => _activityLevel = level);
                                  _saveDietData();
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Calorie Tracker Section
            const Text(
              'Track Today\'s Meals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Input Method Toggle
            _buildInputMethodToggle(),
            const SizedBox(height: 12),

            // Input Form
            _buildInputForm(),
            const SizedBox(height: 20),

            // Today's Entries
            _buildTodayEntries(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final remaining = _remainingCalories;
    final isOverLimit = remaining < 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOverLimit
                ? [Colors.red.shade400, Colors.red.shade600]
                : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consumed',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '${_totalCaloriesToday.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOverLimit ? 'Over' : 'Remaining',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '${remaining.abs().toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progressPercentage,
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation(
                  isOverLimit ? Colors.red.shade900 : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard({
    required Color color,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputMethodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useDirectCalories = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _useDirectCalories
                      ? const Color(0xFFFF6B6B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calculate,
                      color: _useDirectCalories ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Know Calories',
                      style: TextStyle(
                        color: _useDirectCalories ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useDirectCalories = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_useDirectCalories
                      ? const Color(0xFFFF6B6B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: !_useDirectCalories ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Predict',
                      style: TextStyle(
                        color: !_useDirectCalories ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _foodNameController,
              decoration: InputDecoration(
                labelText: 'Food Name',
                prefixIcon: const Icon(Icons.restaurant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_useDirectCalories)
              TextField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Calories (kcal)',
                  prefixIcon: const Icon(Icons.local_fire_department),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (e.g., 100g, 1 cup)',
                  prefixIcon: const Icon(Icons.scale),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingAI
                    ? null
                    : (_useDirectCalories
                        ? _addDirectCalorieEntry
                        : _addAIPredictedEntry),
                icon: _isLoadingAI
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isLoadingAI ? 'Predicting...' : 'Add Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayEntries() {
    if (_todayEntries.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No meals logged today',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Meals (${_todayEntries.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _todayEntries.length,
          itemBuilder: (context, index) {
            final entry = _todayEntries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: entry.isAiPredicted
                      ? Colors.purple.shade100
                      : Colors.blue.shade100,
                  child: Icon(
                    entry.isAiPredicted ? Icons.auto_awesome : Icons.edit,
                    color: entry.isAiPredicted
                        ? Colors.purple.shade700
                        : Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                title: Text(
                  entry.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  DateFormat('h:mm a').format(entry.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _showDeleteDialog(entry.id, entry.name),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDeleteDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Remove "$name" from today\'s log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    _foodNameController.dispose();
    _caloriesController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}