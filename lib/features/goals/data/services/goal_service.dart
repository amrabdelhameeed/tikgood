import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/goal.dart';

class GoalService {
  static const String _goalsBoxName = 'goals';
  static const String _currentGoalKey = 'current_goal';

  late Box<Goal> _goalsBox;
  late Box _settingsBox;

  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    _goalsBox = await Hive.openBox<Goal>(_goalsBoxName);
    _settingsBox = await Hive.openBox('goal_settings');
  }

  /// Save a new goal (adds to history, doesn't overwrite)
  Future<Goal> saveGoal(String text) async {
    final goal = Goal(
      id: _uuid.v4(),
      text: text,
      createdAt: DateTime.now(),
    );
    await _goalsBox.put(goal.id, goal);
    // Also set as current goal for the session
    await _settingsBox.put(_currentGoalKey, goal.id);
    return goal;
  }

  /// Get the current session's goal (if any)
  Goal? getCurrentGoal() {
    final currentGoalId = _settingsBox.get(_currentGoalKey) as String?;
    if (currentGoalId == null) return null;
    return _goalsBox.get(currentGoalId);
  }

  /// Clear the current goal (when app goes to background/closes)
  Future<void> clearCurrentGoal() async {
    await _settingsBox.delete(_currentGoalKey);
  }

  /// Get all goals sorted by most recent first
  List<Goal> getAllGoals() {
    final goals = _goalsBox.values.toList();
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  /// Delete a specific goal
  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
    // If this was the current goal, clear it
    final currentGoalId = _settingsBox.get(_currentGoalKey) as String?;
    if (currentGoalId == id) {
      await clearCurrentGoal();
    }
  }

  /// Clear all goal history
  Future<void> clearAllGoals() async {
    await _goalsBox.clear();
    await _settingsBox.delete(_currentGoalKey);
  }

  // --- Settings: Enable Goal Reminder ---
  bool getGoalReminderEnabled() =>
      _settingsBox.get('goal_reminder_enabled', defaultValue: true) as bool;

  Future<void> setGoalReminderEnabled(bool enabled) async =>
      await _settingsBox.put('goal_reminder_enabled', enabled);
}
