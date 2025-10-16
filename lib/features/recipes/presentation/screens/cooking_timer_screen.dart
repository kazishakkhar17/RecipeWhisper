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
          const SizedBox(height: 12),

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
                      fontSize: 16,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            if (totalSteps > 0) _buildNavigationControls(totalSteps),
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
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  timerColor.withOpacity(0.95),
                  timerColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: timerColor.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: isRunning ? 5 : 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFinished 
                                ? Icons.check_circle 
                                : (isRunning ? Icons.timer : Icons.timer_off),
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFinished 
                              ? context.tr('done')
                              : (isRunning ? 'remaining' : context.tr('pause')),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
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
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '🎉 ${context.tr('finish')} 🎉',
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your dish is ready to serve!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.restaurant, size: 28),
                label: Text(
                  context.tr('done'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
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
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalSteps,
        itemBuilder: (context, index) {
          final isActive = index == _currentStep;
          final isPast = index < _currentStep;
          final isFuture = index > _currentStep;

          return GestureDetector(
            onTap: () => _goToStep(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: isActive ? 70 : 50,
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
                borderRadius: BorderRadius.circular(15),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
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
                    size: isActive ? 28 : 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isActive ? 16 : 14,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.tr('step')} ${index + 1} of $totalSteps',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 4,
                            width: 60,
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
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFFFF6B6B).withOpacity(0.15)
                            : const Color(0xFFFF6B6B).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        instruction.isNotEmpty ? instruction : 'No instruction provided',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (index + 1) / totalSteps,
                          minHeight: 8,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B6B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${((index + 1) / totalSteps * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
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

  Widget _buildNavigationControls(int totalSteps) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentStep > 0
                  ? () => _goToStep(_currentStep - 1)
                  : null,
              icon: const Icon(Icons.arrow_back),
              label: Text(context.tr('previous')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentStep < totalSteps - 1
                  ? () => _goToStep(_currentStep + 1)
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(context.tr('next')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls(dynamic timerState, dynamic timerNotifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                size: 28,
              ),
              label: Text(
                timerState.isRunning
                    ? context.tr('pause')
                    : context.tr('resume'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: timerState.isRunning
                    ? const Color(0xFFFFA726)
                    : const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
              icon: const Icon(Icons.stop),
              label: Text(context.tr('stop')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}