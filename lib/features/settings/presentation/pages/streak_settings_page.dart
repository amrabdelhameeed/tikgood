import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/database/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Design tokens (matches settings_page.dart)
// ─────────────────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF000000);
const _kSurface = Color(0xFF111111);
const _kBorder = Color(0xFF2A2A2A);
const _kRed = Color(0xFFFE2C55);
const _kCyan = Color(0xFF25F4EE);
const _kWhite = Colors.white;
const _kWhite60 = Color(0x99FFFFFF);
const _kWhite30 = Color(0x4DFFFFFF);
const _kWhite12 = Color(0x1FFFFFFF);

class StreakSettingsPage extends StatefulWidget {
  const StreakSettingsPage({super.key});

  @override
  State<StreakSettingsPage> createState() => _StreakSettingsPageState();
}

class _StreakSettingsPageState extends State<StreakSettingsPage>
    with SingleTickerProviderStateMixin {
  bool _reminderEnabled = false;
  late TimeOfDay _reminderTime;
  late int _streak;

  late AnimationController _flameCtrl;
  late Animation<double> _flameScale;

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    _reminderEnabled = storage.getReminderEnabled();
    _streak = storage.getStreakCount();

    final parts = storage.getReminderTime().split(':');
    _reminderTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _flameScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flameCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleReminder(bool value) async {
    final streakSvc = context.read<StreakService>();
    if (value) {
      await streakSvc.scheduleReminder(_reminderTime);
    } else {
      await streakSvc.cancelReminder();
    }
    setState(() => _reminderEnabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kCyan,
            onSurface: _kWhite,
          ),
          dialogBackgroundColor: const Color(0xFF111111),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _reminderTime = picked);
      final storage = context.read<StorageService>();
      final hhmm =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await storage.saveReminderTime(hhmm);

      // Re-schedule with new time if enabled
      if (_reminderEnabled) {
        await context.read<StreakService>().scheduleReminder(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          const SizedBox(height: 32),
          _buildStreakHero(),
          const SizedBox(height: 32),
          _buildReminderSection(),
          const SizedBox(height: 24),
          _buildTipsSection(),
        ],
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'streak_title'.tr(),
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: _kBorder, height: 0.5),
      ),
    );
  }

  // ── Streak Hero ────────────────────────────────────────────────────────────

  Widget _buildStreakHero() {
    return Column(
      children: [
        // Animated flame + count
        AnimatedBuilder(
          animation: _flameScale,
          builder: (_, __) => Transform.scale(
            scale: _flameScale.value,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _kRed.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 64)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$_streak',
          style: const TextStyle(
            color: _kWhite,
            fontSize: 56,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _streak == 1 ? 'streak_day_singular'.tr() : 'streak_day_plural'.tr(),
          style: const TextStyle(
            color: _kWhite60,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        // Motivational sub-label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _kRed.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kRed.withOpacity(0.3), width: 0.8),
          ),
          child: Text(
            _streak >= 7
                ? 'streak_badge_legend'.tr()
                : _streak >= 3
                    ? 'streak_badge_building'.tr()
                    : 'streak_badge_start'.tr(),
            style: const TextStyle(
              color: _kRed,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Reminder Section ───────────────────────────────────────────────────────

  Widget _buildReminderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(Icons.notifications_rounded, color: _kCyan, size: 14),
              const SizedBox(width: 6),
              Text(
                'streak_reminder_section'.tr(),
                style: const TextStyle(
                  color: _kCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'streak_reminder_subtitle'.tr(),
              style: const TextStyle(color: _kWhite30, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          // Card
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 0.8),
            ),
            child: Column(
              children: [
                // Toggle row
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _kCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alarm_rounded,
                            color: _kCyan, size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'streak_daily_reminder'.tr(),
                              style: const TextStyle(
                                color: _kWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _reminderEnabled
                                  ? 'streak_reminder_active'.tr()
                                  : 'streak_reminder_off'.tr(),
                              style: TextStyle(
                                color: _reminderEnabled
                                    ? _kCyan.withOpacity(0.8)
                                    : _kWhite30,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: _toggleReminder,
                        activeColor: _kBg,
                        activeTrackColor: _kCyan,
                        inactiveThumbColor: _kWhite30,
                        inactiveTrackColor: _kWhite12,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
                // Divider
                const Divider(color: _kBorder, height: 1, indent: 16),
                // Time picker row
                InkWell(
                  onTap: _pickTime,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _kRed.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.schedule_rounded,
                              color: _kRed, size: 17),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'streak_reminder_time'.tr(),
                            style: const TextStyle(
                              color: _kWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _reminderTime.format(context),
                          style: const TextStyle(
                            color: _kCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded,
                            color: _kWhite30, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tips Section ──────────────────────────────────────────────────────────

  Widget _buildTipsSection() {
    final tips = [
      ('⏱️', 'streak_tip_1'.tr()),
      ('🎯', 'streak_tip_2'.tr()),
      ('📵', 'streak_tip_3'.tr()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded,
                  color: _kWhite30, size: 14),
              const SizedBox(width: 6),
              Text(
                'streak_tips_section'.tr(),
                style: const TextStyle(
                  color: _kWhite30,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 0.8),
            ),
            child: Column(
              children: [
                for (int i = 0; i < tips.length; i++) ...[
                  if (i > 0)
                    const Divider(color: _kBorder, height: 1, indent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(tips[i].$1,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tips[i].$2,
                            style: const TextStyle(
                              color: _kWhite60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
