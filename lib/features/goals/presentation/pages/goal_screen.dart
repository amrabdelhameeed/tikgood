import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart'; // Added
import '../../data/models/goal.dart';
import '../../data/services/goal_service.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  List<Goal> _goals = [];
  Goal? _currentGoal;
  bool _isLoading = true;

  // TikTok design tokens
  static const Color _kBg = Color(0xFF000000);
  static const Color _kSurface = Color(0xFF111111);
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
      final allGoals = goalService.getAllGoals();
      _currentGoal = goalService.getCurrentGoal();

      if (_currentGoal == null && allGoals.isNotEmpty) {
        _currentGoal = allGoals.first;
      }

      _goals = allGoals.where((g) => g.id != _currentGoal?.id).toList();
      _isLoading = false;
    });
  }

  /// Formats timestamp with localized relative labels
  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final goalDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString =
        DateFormat.jm(context.locale.toString()).format(dateTime);

    if (goalDate == today) {
      return 'goals_today_at'.tr(args: [timeString]);
    } else if (goalDate == today.subtract(const Duration(days: 1))) {
      return 'goals_yesterday_at'.tr(args: [timeString]);
    } else {
      return DateFormat.yMMMd(context.locale.toString())
          .add_jm()
          .format(dateTime);
    }
  }

  Future<void> _deleteGoal(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kSurface,
        title: Text('goals_delete_title'.tr(),
            style: const TextStyle(color: _kWhite)),
        content: Text('goals_delete_confirm'.tr(),
            style: const TextStyle(color: _kWhite60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text('cancel'.tr(), style: const TextStyle(color: _kWhite60)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr(), style: const TextStyle(color: _kRed)),
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
        title: Text('goals_clear_title'.tr(),
            style: const TextStyle(color: _kWhite)),
        content: Text('goals_clear_confirm'.tr(),
            style: const TextStyle(color: _kWhite60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text('cancel'.tr(), style: const TextStyle(color: _kWhite60)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('clear_all'.tr(), style: const TextStyle(color: _kRed)),
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
        title: Text(
          'goals_screen_title'.tr(),
          style: const TextStyle(
              color: _kWhite, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_goals.isNotEmpty || _currentGoal != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: _kWhite60),
              onPressed: _clearAllGoals,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kRed))
          : (_goals.isEmpty && _currentGoal == null)
              ? _buildEmptyState()
              : _buildGoalsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, color: _kWhite30, size: 64),
          const SizedBox(height: 16),
          Text('goals_empty_title'.tr(),
              style: const TextStyle(
                  color: _kWhite, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('goals_empty_subtitle'.tr(),
              style: const TextStyle(color: _kWhite60, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCurrentGoal() {
    if (_currentGoal == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: _kRed, size: 18),
              const SizedBox(width: 8),
              Text(
                'goals_active_label'.tr().toUpperCase(),
                style: const TextStyle(
                    color: _kRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_currentGoal!.text,
              style: const TextStyle(
                  color: _kWhite, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'goals_set_at'
                    .tr(args: [_formatTimestamp(_currentGoal!.createdAt)]),
                style: const TextStyle(color: _kWhite30, fontSize: 12),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: _kWhite30, size: 20),
                onPressed: () => _deleteGoal(_currentGoal!.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCurrentGoal(),
        if (_goals.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'goals_history_label'.tr().toUpperCase(),
              style: const TextStyle(
                  color: _kWhite30,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1),
            ),
          ),
          ..._goals.map((goal) => _buildGoalItem(goal)),
        ],
      ],
    );
  }

  Widget _buildGoalItem(Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kWhite12),
      ),
      child: ListTile(
        title: Text(goal.text,
            style: const TextStyle(
                color: _kWhite, fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(_formatTimestamp(goal.createdAt),
            style: const TextStyle(color: _kWhite30, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: _kWhite30, size: 20),
          onPressed: () => _deleteGoal(goal.id),
        ),
      ),
    );
  }
}
