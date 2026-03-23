import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/goal.dart';
import '../../data/services/goal_service.dart';

/// Screen that displays the history of all goals set by the user.
/// Goals are sorted with most recent first, showing goal text and
/// human-friendly timestamps.
class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  List<Goal> _goals = [];
  bool _isLoading = true;

  // TikTok design tokens
  static const Color _kBg = Color(0xFF000000);
  static const Color _kSurface = Color(0xFF111111);
  static const Color _kSurface2 = Color(0xFF1A1A1A);
  static const Color _kBorder = Color(0xFF2A2A2A);
  static const Color _kRed = Color(0xFFFE2C55);
  static const Color _kWhite = Colors.white;
  static const Color _kWhite60 = Color(0x99FFFFFF);
  static const Color _kWhite30 = Color(0x4DFFFFFF);
  static const Color _kWhite12 = Color(0x1FFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    final goalService = context.read<GoalService>();
    setState(() {
      _goals = goalService.getAllGoals();
      _isLoading = false;
    });
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final goalDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (goalDate == today) {
      return 'Today at ${DateFormat.jm().format(dateTime)}';
    } else if (goalDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday at ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dateTime);
    }
  }

  Future<void> _deleteGoal(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text(
          'Delete Goal',
          style: TextStyle(color: _kWhite),
        ),
        content: const Text(
          'Are you sure you want to delete this goal?',
          style: TextStyle(color: _kWhite60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _kWhite60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: _kRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final goalService = context.read<GoalService>();
      await goalService.deleteGoal(id);
      _loadGoals();
    }
  }

  Future<void> _clearAllGoals() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text(
          'Clear All Goals',
          style: TextStyle(color: _kWhite),
        ),
        content: const Text(
          'This will delete all your goal history. This action cannot be undone.',
          style: TextStyle(color: _kWhite60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _kWhite60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Clear All',
              style: TextStyle(color: _kRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final goalService = context.read<GoalService>();
      await goalService.clearAllGoals();
      _loadGoals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Goals',
          style: TextStyle(
            color: _kWhite,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_goals.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: _kWhite60),
              onPressed: _clearAllGoals,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kRed),
            )
          : _goals.isEmpty
              ? _buildEmptyState()
              : _buildGoalsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.flag_outlined,
            color: _kWhite30,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No goals yet',
            style: TextStyle(
              color: _kWhite,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a goal when you open the app',
            style: TextStyle(
              color: _kWhite60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kWhite12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              goal.text,
              style: const TextStyle(
                color: _kWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatTimestamp(goal.createdAt),
                style: const TextStyle(
                  color: _kWhite30,
                  fontSize: 13,
                ),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: _kWhite30,
                size: 20,
              ),
              onPressed: () => _deleteGoal(goal.id),
            ),
          ),
        );
      },
    );
  }
}
