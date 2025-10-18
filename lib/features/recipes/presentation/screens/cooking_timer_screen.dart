import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bli_flutter_recipewhisper/core/localization/app_localizations.dart';
import '../providers/cooking_timer_provider.dart';
import 'dart:math' show sin, pi;

class CookingTimerScreen extends ConsumerStatefulWidget {
  const CookingTimerScreen({super.key});

  @override
  ConsumerState<CookingTimerScreen> createState() => _CookingTimerScreenState();
}

class _CookingTimerScreenState extends ConsumerState<CookingTimerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentStep = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Color _getTimerColor(double progress) {
    if (progress < 0.1) return const Color(0xFF8B0000);
    if (progress < 0.2) return const Color(0xFFDC143C);
    if (progress < 0.35) return const Color(0xFFFF6B6B);
    if (progress < 0.5) return const Color(0xFFFF8E53);
    if (progress < 0.65) return const Color(0xFFFFB84D);
    if (progress < 0.75) return const Color(0xFFFFD700);
    if (progress < 0.85) return const Color(0xFFADFF2F);
    if (progress < 0.95) return const Color(0xFF4CAF50);
    return const Color(0xFF2E7D32);
  }

  String _getStatusMessage(double progress) {
    if (progress < 0.1) return context.tr('stage_just_started');
    if (progress < 0.25) return context.tr('stage_heating_up');
    if (progress < 0.5) return context.tr('stage_cooking_nicely');
    if (progress < 0.75) return context.tr('stage_getting_close');
    if (progress < 0.9) return context.tr('stage_almost_done');
    if (progress < 1.0) return context.tr('stage_ready_soon');
    return context.tr('done');
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(cookingTimerProvider);
    final timerNotifier = ref.read(cookingTimerProvider.notifier);
    final recipe = timerState.recipe;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('cooking')),
        ),
        body: Center(
          child: Text(
            context.tr('no_recipe'),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      );
    }

    final totalSteps = recipe.instructions.length;
    final remainingSeconds = timerState.remainingSeconds;
    final totalSeconds = recipe.cookingTimeMinutes * 60;
    final elapsedSeconds = totalSeconds - remainingSeconds;
    final progress = totalSeconds > 0 ? elapsedSeconds / totalSeconds : 0.0;
    
    final timerColor = _getTimerColor(progress);
    final statusMessage = _getStatusMessage(progress);
    final isFinished = remainingSeconds <= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(recipe.name),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTimerSection(remainingSeconds, progress, timerState.isRunning, timerColor, statusMessage, isFinished, isDark),
          const SizedBox(height: 8),

          if (isFinished)
            _buildCompletionCard(isDark)
          else ...[
            if (totalSteps > 0) _buildStepIndicator(totalSteps, isDark),
            const SizedBox(height: 8),

            if (totalSteps > 0)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  itemCount: totalSteps,
                  itemBuilder: (context, index) {
                    return _buildStepCard(
                      recipe.instructions[index],
                      index,
                      totalSteps,
                      isDark,
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    context.tr('no_instructions_available'),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],

          if (!isFinished) _buildTimerControls(timerState, timerNotifier),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTimerSection(int remainingSeconds, double progress, bool isRunning, Color timerColor, String statusMessage, bool isFinished, bool isDark) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseScale = isRunning ? 1.0 + (_pulseController.value * 0.03) : 1.0;

        return Transform.scale(
          scale: pulseScale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  timerColor.withOpacity(0.95),
                  timerColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: timerColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: isRunning ? 4 : 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusMessage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFinished 
                                ? Icons.check_circle 
                                : (isRunning ? Icons.timer : Icons.timer_off),
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [Colors.white, Colors.white70],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds);
                          },
                          child: Text(
                            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isFinished 
                              ? context.tr('done')
                              : (isRunning ? context.tr('cooking') : context.tr('pause')),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionCard(bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '🎉 ${context.tr('finish')} 🎉',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('dish_ready'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.restaurant, size: 24),
                label: Text(
                  context.tr('done'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int totalSteps, bool isDark) {
    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalSteps,
        itemBuilder: (context, index) {
          final isActive = index == _currentStep;
          final isPast = index < _currentStep;

          return GestureDetector(
            onTap: () => _goToStep(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: isActive ? 64 : 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPast
                      ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                      : isActive
                          ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                          : isDark 
                              ? [Colors.grey.shade700, Colors.grey.shade800]
                              : [Colors.grey.shade300, Colors.grey.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPast
                        ? Icons.check_circle
                        : isActive
                            ? Icons.restaurant
                            : Icons.circle_outlined,
                    color: Colors.white,
                    size: isActive ? 24 : 20,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isActive ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepCard(String instruction, int index, int totalSteps, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.tr('step')} ${index + 1} ${context.tr('of')} $totalSteps',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 3,
                            width: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFFFF6B6B).withOpacity(0.15)
                          : const Color(0xFFFF6B6B).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        instruction.isNotEmpty ? instruction : context.tr('no_instruction'),
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (index + 1) / totalSteps,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${((index + 1) / totalSteps * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerControls(dynamic timerState, dynamic timerNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                if (timerState.isRunning) {
                  timerNotifier.pauseTimer();
                } else {
                  timerNotifier.resumeTimer();
                }
              },
              icon: Icon(
                timerState.isRunning ? Icons.pause : Icons.play_arrow,
                size: 24,
              ),
              label: Text(
                timerState.isRunning
                    ? context.tr('pause')
                    : context.tr('resume'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: timerState.isRunning
                    ? const Color(0xFFFFA726)
                    : const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(context.tr('stop')),
                    content: Text(context.tr('stop_cooking_confirmation')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.tr('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          timerNotifier.stopTimer();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          context.tr('stop'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.stop, size: 20),
              label: Text(context.tr('stop')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}