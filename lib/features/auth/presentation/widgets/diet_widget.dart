// diet_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';

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
          _loadTodayEntries();
          setState(() {});
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOverLimit
                  ? [Colors.red.shade400, Colors.red.shade600]
                  : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('consumed_today'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${_totalCaloriesToday.toStringAsFixed(0)} ${context.tr('kcal')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverLimit ? context.tr('over_limit') : context.tr('remaining'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${remaining.abs().toStringAsFixed(0)} ${context.tr('kcal')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('view_diet_profile'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
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
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _feetController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
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
    _aiService = GroqService();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    _dietBox = await Hive.openBox('user_diet_box');
    _calorieBox = await Hive.openBox('calorie_tracking_box');

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
    return '${feet.isEmpty ? "0" : feet} ${context.tr('ft')} ${inches.isEmpty ? "0" : inches} ${context.tr('in')}';
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
      _showSnackBar(context.tr('enter_food_and_calories'));
      return;
    }

    final calories = double.tryParse(_caloriesController.text);
    if (calories == null || calories <= 0) {
      _showSnackBar(context.tr('enter_valid_calories'));
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
    
    _showSnackBar('${context.tr('added')} ${calories.toStringAsFixed(0)} ${context.tr('kcal')}');
  }

  Future<void> _addAIPredictedEntry() async {
    if (_foodNameController.text.isEmpty || _amountController.text.isEmpty) {
      _showSnackBar(context.tr('enter_food_and_amount'));
      return;
    }

    setState(() => _isLoadingAI = true);

    try {
      final prompt =
          "Estimate calories for ${_amountController.text} of ${_foodNameController.text}. Return only a number.";

      final aiResponse = await _aiService.sendMessage(message: prompt);

      final predictedCalories = double.tryParse(
            RegExp(r'[\d.]+').firstMatch(aiResponse)?.group(0) ?? '',
          ) ??
          150.0;

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

      _showSnackBar('${context.tr('ai_predicted')} ${predictedCalories.toStringAsFixed(0)} ${context.tr('kcal')}');
    } catch (e) {
      setState(() => _isLoadingAI = false);
      _showSnackBar('❌ ${context.tr('error_predicting')}: $e');
    }
  }

  void _deleteEntry(String id) {
    setState(() {
      _todayEntries.removeWhere((entry) => entry.id == id);
    });
    _saveTodayEntries();
    _showSnackBar(context.tr('entry_deleted'));
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
        appBar: AppBar(title: Text(context.tr('diet_calorie_tracker'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('diet_calorie_tracker')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildQuickStatCard(
                    color: Colors.blue,
                    icon: Icons.height,
                    title: context.tr('height'),
                    value: _formatHeight(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatCard(
                    color: Colors.orange,
                    icon: Icons.local_fire_department,
                    title: context.tr('daily_goal'),
                    value: _dailyCalories > 0
                        ? '${_dailyCalories.toStringAsFixed(0)}'
                        : '--',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!_showProfileForm)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showProfileForm = true),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(context.tr('edit_diet_profile')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (_showProfileForm) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('diet_profile'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _showProfileForm = false),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(context.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ageController,
                        decoration: InputDecoration(labelText: context.tr('age')),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => _saveDietData(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _feetController,
                              decoration: InputDecoration(labelText: context.tr('feet')),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (_) => _saveDietData(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _inchesController,
                              decoration: InputDecoration(labelText: context.tr('inches')),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (_) => _saveDietData(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        decoration: InputDecoration(labelText: context.tr('weight_kg')),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => _saveDietData(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(context.tr('gender')),
                          Radio<Gender>(
                            value: Gender.male,
                            groupValue: _gender,
                            onChanged: (val) {
                              setState(() => _gender = val);
                              _saveDietData();
                            },
                          ),
                          Text(context.tr('male')),
                          Radio<Gender>(
                            value: Gender.female,
                            groupValue: _gender,
                            onChanged: (val) {
                              setState(() => _gender = val);
                              _saveDietData();
                            },
                          ),
                          Text(context.tr('female')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('activity_level')),
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
                                label: Text(label, style: const TextStyle(fontSize: 12)),
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
              const SizedBox(height: 12),
            ],

            Text(
              context.tr('track_todays_meals'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildInputMethodToggle(),
            const SizedBox(height: 12),

            _buildInputForm(),
            const SizedBox(height: 16),

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isOverLimit
                ? [Colors.red.shade400, Colors.red.shade600]
                : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('consumed'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${_totalCaloriesToday.toStringAsFixed(0)} ${context.tr('kcal')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            isOverLimit ? context.tr('over') : context.tr('remaining'),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '${remaining.abs().toStringAsFixed(0)} ${context.tr('kcal')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),

            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progressPercentage,
                minHeight: 10,
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
        padding: const EdgeInsets.all(12),
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
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useDirectCalories = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _useDirectCalories
                      ? const Color(0xFFFF6B6B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calculate,
                      color: _useDirectCalories ? Colors.white : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('know_calories'),
                      style: TextStyle(
                        color: _useDirectCalories ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_useDirectCalories
                      ? const Color(0xFFFF6B6B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: !_useDirectCalories ? Colors.white : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('ai_predict'),
                      style: TextStyle(
                        color: !_useDirectCalories ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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
                labelText: context.tr('food_name'),
                prefixIcon: const Icon(Icons.restaurant, size: 20),
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
                  labelText: context.tr('calories_kcal'),
                  prefixIcon: const Icon(Icons.local_fire_department, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: context.tr('amount_eg'),
                  prefixIcon: const Icon(Icons.scale, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            const SizedBox(height: 12),
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
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add, size: 20),
                label: Text(_isLoadingAI ? context.tr('predicting') : context.tr('add_entry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.restaurant_menu, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  context.tr('no_meals_logged'),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
          '${context.tr('todays_meals')} (${_todayEntries.length})',
          style: const TextStyle(
            fontSize: 16,
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: entry.isAiPredicted
                      ? Colors.purple.shade100
                      : Colors.blue.shade100,
                  child: Icon(
                    entry.isAiPredicted ? Icons.auto_awesome : Icons.edit,
                    color: entry.isAiPredicted
                        ? Colors.purple.shade700
                        : Colors.blue.shade700,
                    size: 18,
                  ),
                ),
                title: Text(
                  entry.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  DateFormat('h:mm a').format(entry.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.calories.toStringAsFixed(0)} ${context.tr('kcal')}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
        title: Text(context.tr('delete_entry')),
        content: Text('${context.tr('remove_entry')} "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(id);
            },
            child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
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