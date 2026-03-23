import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/goal_service.dart';
import '../../data/services/goal_notification_service.dart';

/// TikTok-inspired goal input screen that appears on app startup.
/// Prompts the user to define a goal for the current session.
class GoalMiddlewareScreen extends StatefulWidget {
  final VoidCallback onGoalSet;
  final VoidCallback onSkip;

  const GoalMiddlewareScreen({
    super.key,
    required this.onGoalSet,
    required this.onSkip,
  });

  @override
  State<GoalMiddlewareScreen> createState() => _GoalMiddlewareScreenState();
}

class _GoalMiddlewareScreenState extends State<GoalMiddlewareScreen> {
  final TextEditingController _goalController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  // TikTok design tokens
  static const Color _kBg = Color(0xFF000000);
  static const Color _kRed = Color(0xFFFE2C55);
  static const Color _kWhite = Colors.white;
  static const Color _kWhite60 = Color(0x99FFFFFF);
  static const Color _kWhite30 = Color(0x4DFFFFFF);
  static const Color _kWhite12 = Color(0x1FFFFFFF);
  static const Color _kSurface = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _goalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitGoal() async {
    final goalText = _goalController.text.trim();
    if (goalText.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final goalService = context.read<GoalService>();
      await goalService.saveGoal(goalText);

      final goalNotificationService = context.read<GoalNotificationService>();
      await goalNotificationService.showGoalNotification(goalText);

      widget.onGoalSet();
    } catch (e) {
      debugPrint('Error saving goal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save goal. Please try again.'),
            backgroundColor: _kRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skipGoal() {
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                const Text(
                  '🎯',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'What\'s your goal?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set an intention for this session',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kWhite60,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),

                // Goal input field
                Container(
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kWhite12),
                  ),
                  child: TextField(
                    controller: _goalController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: _kWhite,
                      fontSize: 18,
                    ),
                    maxLines: 3,
                    maxLength: 200,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'What\'s your goal right now?',
                      hintStyle: TextStyle(
                        color: _kWhite30,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      counterStyle: TextStyle(color: _kWhite30),
                    ),
                    onSubmitted: (_) => _submitGoal(),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: _kWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: _kRed.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _kWhite,
                          ),
                        )
                      : const Text(
                          'Set Goal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Skip button
                TextButton(
                  onPressed: _isLoading ? null : _skipGoal,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: _kWhite60,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
