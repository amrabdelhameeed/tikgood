import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart'; // Ensure this is imported
import 'package:tikgood/core/widgets/tiktok_loading_widget.dart';
import '../../data/models/goal.dart';
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
  List<Goal> _recentGoals = [];

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

    final goalService = context.read<GoalService>();
    final allGoals = goalService.getAllGoals();

    final uniqueTexts = <String>{};
    for (final g in allGoals) {
      if (uniqueTexts.length >= 7) break;
      if (uniqueTexts.add(g.text)) {
        _recentGoals.add(g);
      }
    }

    if (_recentGoals.isNotEmpty) {
      _goalController.text = _recentGoals.first.text;
    }

    // Auto-focus the text field after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
        if (_goalController.text.isNotEmpty) {
          _goalController.selection = TextSelection.fromPosition(
              TextPosition(offset: _goalController.text.length));
        }
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
          SnackBar(
            content: Text('Failed to save goal. Please try again.'.tr()),
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
                Text(
                  '🎯'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'What\'s your goal?'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _kWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set an intention for this session'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                    decoration: InputDecoration(
                      hintText: 'What\'s your goal right now?'.tr(),
                      hintStyle: const TextStyle(
                        color: _kWhite30,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: const TextStyle(color: _kWhite30),
                    ),
                    onSubmitted: (_) => _submitGoal(),
                  ),
                ),
                const SizedBox(height: 24),

                // Recent goals dropdown
                if (_recentGoals.isNotEmpty) ...[
                  Text(
                    'Or select from history'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kWhite60,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kWhite12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: _kSurface,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: _kWhite),
                        hint: Text(
                          'Recent goals'.tr(),
                          style:
                              const TextStyle(color: _kWhite60, fontSize: 16),
                        ),
                        value: null,
                        items: _recentGoals.map((Goal goal) {
                          return DropdownMenuItem<String>(
                            value: goal.text,
                            child: Text(
                              goal.text, // Database content usually doesn't get .tr()
                              style: const TextStyle(
                                color: _kWhite,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newText) {
                          if (newText != null) {
                            _goalController.text = newText;
                            _goalController.selection =
                                TextSelection.fromPosition(TextPosition(
                                    offset: _goalController.text.length));
                          }
                        },
                      ),
                    ),
                  ),
                ],
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
                          key: ValueKey('loading'),
                          child: TikTokLoadingAnimation(),
                        )
                      : Text(
                          'Set Goal'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Skip button
                TextButton(
                  onPressed: _isLoading ? null : _skipGoal,
                  child: Text(
                    'Skip for now'.tr(),
                    style: const TextStyle(
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
