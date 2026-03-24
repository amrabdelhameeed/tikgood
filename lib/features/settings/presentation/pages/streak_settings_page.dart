import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/database/storage_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _flameScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _flameCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _flameCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleReminder(bool value) async {
    final streakSvc = context.read<StreakService>();
    final storage = context.read<StorageService>();

    setState(() => _reminderEnabled = value);
    await storage.saveReminderEnabled(value);

    if (value) {
      await streakSvc.scheduleReminder(_reminderTime);
    } else {
      await streakSvc.cancelReminder();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kCyan,
            surface: _kSurface,
            onSurface: _kWhite,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _kCyan),
          ),
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
          const SizedBox(height: 40),
          _buildReminderSection(),
          const SizedBox(height: 32),
          _buildTipsSection(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'streak_title'.tr(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: _kBorder, height: 0.5),
      ),
    );
  }

  Widget _buildStreakHero() {
    return Column(
      children: [
        ScaleTransition(
          scale: _flameScale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_kRed.withOpacity(0.2), Colors.transparent],
              ),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 72)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$_streak',
          style: const TextStyle(
            color: _kWhite,
            fontSize: 64,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        Text(
          _streak == 1 ? 'streak_day_singular'.tr() : 'streak_day_plural'.tr(),
          style: const TextStyle(
              color: _kWhite60, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildBadge(),
      ],
    );
  }

  Widget _buildBadge() {
    String label = 'streak_badge_start'.tr();
    if (_streak >= 7)
      label = 'streak_badge_legend'.tr();
    else if (_streak >= 3) label = 'streak_badge_building'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _kRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kRed.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
            color: _kRed,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.notifications_active_outlined,
              'streak_reminder_section'.tr(), _kCyan),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _buildToggleRow(),
                const Divider(color: _kBorder, height: 1, indent: 56),
                _buildTimePickerRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(Icons.alarm_rounded, _kCyan),
      title: Text('streak_daily_reminder'.tr(),
          style: const TextStyle(
              color: _kWhite, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(
        _reminderEnabled
            ? 'streak_reminder_active'.tr()
            : 'streak_reminder_off'.tr(),
        style: TextStyle(
            color: _reminderEnabled ? _kCyan : _kWhite30, fontSize: 13),
      ),
      trailing: Switch.adaptive(
        value: _reminderEnabled,
        onChanged: _toggleReminder,
        activeColor: _kCyan,
        activeTrackColor: _kCyan.withOpacity(0.3),
      ),
    );
  }

  Widget _buildTimePickerRow() {
    return ListTile(
      onTap: _pickTime,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBox(Icons.schedule_rounded, _kRed),
      title: Text('streak_reminder_time'.tr(),
          style: const TextStyle(
              color: _kWhite, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_reminderTime.format(context),
              style: const TextStyle(
                  color: _kCyan, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: _kWhite30, size: 20),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = [
      ('⏱️', 'streak_tip_1'.tr()),
      ('🎯', 'streak_tip_2'.tr()),
      ('📵', 'streak_tip_3'.tr()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.lightbulb_outline_rounded,
              'streak_tips_section'.tr(), _kWhite30),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: List.generate(
                  tips.length,
                  (i) => Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(tips[i].$1,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Text(tips[i].$2,
                                        style: const TextStyle(
                                            color: _kWhite60,
                                            fontSize: 14,
                                            height: 1.4))),
                              ],
                            ),
                          ),
                          if (i < tips.length - 1)
                            const Divider(
                                color: _kBorder, height: 1, indent: 56),
                        ],
                      )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1),
      );
}
