import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tikgood/core/widgets/tiktok_loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tikgood/core/utils/accessibility_intercept_service.dart';
import '../../../../core/database/storage_service.dart';
import '../../../notes/data/datasources/notion_service.dart';
import '../../../goals/data/services/goal_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TikTok Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF000000);
const _kSurface = Color(0xFF111111);
const _kSurface2 = Color(0xFF1A1A1A);
const _kBorder = Color(0xFF2A2A2A);
const _kRed = Color(0xFFFE2C55);
const _kCyan = Color(0xFF25F4EE);
const _kWhite = Colors.white;
const _kWhite60 = Color(0x99FFFFFF);
const _kWhite30 = Color(0x4DFFFFFF);
const _kWhite12 = Color(0x1FFFFFFF);

// ─────────────────────────────────────────────────────────────────────────────
//  Auto-save debounce duration
// ─────────────────────────────────────────────────────────────────────────────
const _kDebounceDuration = Duration(milliseconds: 800);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late TextEditingController _apiKeyController;
  late TextEditingController _dbIdController;
  late TextEditingController _cloudNameController;
  late TextEditingController _uploadPresetController;

  // Debounce timers for auto-save
  Timer? _apiKeyTimer;
  Timer? _cloudNameTimer;
  Timer? _uploadPresetTimer;

  // Save-indicator animation controllers
  late AnimationController _saveIndicatorCtrl;
  late Animation<double> _saveIndicatorOpacity;

  List<Map<String, String>> _availableDatabases = [];
  bool _isFetching = false;
  bool _obscureKey = true;
  bool _interceptEnabled = false;
  bool _showSaved = false;
  bool _goalReminderEnabled = true;

  static const String _notionApiKeyVideoUrl =
      'https://www.youtube.com/watch?v=d4UeQVHB0vo';
  static const String _notionApiKeyVideoTitle = 'How to get API Key';
  static const String _cloudinaryUploadPresetVideoUrl =
      'https://www.youtube.com/watch?v=r1g5UIhaw5k';
  static const String _cloudinaryUploadPresetVideoTitle =
      'How to create upload preset and get the cloud name';

  // Set to false when uploading to Play Store
  static const bool showFocusSection = false;

  static const String _githubRepoUrl =
      'https://github.com/amrabdelhameeed/tikgood';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final storage = context.read<StorageService>();
    _apiKeyController =
        TextEditingController(text: storage.getNotionApiKey() ?? '');
    _dbIdController =
        TextEditingController(text: storage.getNotionDatabaseId() ?? '');
    _cloudNameController =
        TextEditingController(text: storage.getCloudinaryCloudName() ?? '');
    _uploadPresetController =
        TextEditingController(text: storage.getCloudinaryUploadPreset() ?? '');

    // Save-indicator fade animation
    _saveIndicatorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _saveIndicatorOpacity = CurvedAnimation(
      parent: _saveIndicatorCtrl,
      curve: Curves.easeOut,
    );

    // Wire up auto-save listeners
    _apiKeyController.addListener(_onApiKeyChanged);
    _cloudNameController.addListener(_onCloudNameChanged);
    _uploadPresetController.addListener(_onUploadPresetChanged);

    _checkInterceptStatus();

    // Initialize goal reminder setting
    final goalService = context.read<GoalService>();
    _goalReminderEnabled = goalService.getGoalReminderEnabled();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiKeyTimer?.cancel();
    _cloudNameTimer?.cancel();
    _uploadPresetTimer?.cancel();
    _saveIndicatorCtrl.dispose();
    _apiKeyController
      ..removeListener(_onApiKeyChanged)
      ..dispose();
    _dbIdController.dispose();
    _cloudNameController
      ..removeListener(_onCloudNameChanged)
      ..dispose();
    _uploadPresetController
      ..removeListener(_onUploadPresetChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkInterceptStatus();
  }

  // ── Auto-save handlers ────────────────────────────────────────────────────

  void _onApiKeyChanged() {
    _apiKeyTimer?.cancel();
    _apiKeyTimer = Timer(_kDebounceDuration, () async {
      final storage = context.read<StorageService>();
      await storage.saveNotionApiKey(_apiKeyController.text.trim());
      _flashSaved();
    });
  }

  void _onCloudNameChanged() {
    _cloudNameTimer?.cancel();
    _cloudNameTimer = Timer(_kDebounceDuration, () async {
      final storage = context.read<StorageService>();
      await storage.saveCloudinaryCloudName(_cloudNameController.text.trim());
      _flashSaved();
    });
  }

  void _onUploadPresetChanged() {
    _uploadPresetTimer?.cancel();
    _uploadPresetTimer = Timer(_kDebounceDuration, () async {
      final storage = context.read<StorageService>();
      await storage
          .saveCloudinaryUploadPreset(_uploadPresetController.text.trim());
      _flashSaved();
    });
  }

  void _flashSaved() {
    if (!mounted) return;
    setState(() => _showSaved = true);
    _saveIndicatorCtrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _saveIndicatorCtrl.reverse().then((_) {
            if (mounted) setState(() => _showSaved = false);
          });
        }
      });
    });
  }

  // ── Intercept ─────────────────────────────────────────────────────────────

  Future<void> _checkInterceptStatus() async {
    final enabled = await AccessibilityInterceptService.isServiceEnabled();
    if (mounted) setState(() => _interceptEnabled = enabled);
  }

  Future<void> _toggleIntercept(bool value) async {
    if (value) {
      await AccessibilityInterceptService.requestOverlayPermission();
      await AccessibilityInterceptService.openAccessibilitySettings();
    } else {
      await AccessibilityInterceptService.openAccessibilitySettings();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          _buildSection(
            label: 'settings_section_notion'.tr(),
            subtitle: 'settings_notion_subtitle'.tr(),
            icon: Icons.link_rounded,
            iconColor: _kCyan,
            children: [
              _buildField(
                label: 'settings_api_key'.tr(),
                controller: _apiKeyController,
                obscure: _obscureKey,
                suffix: _buildEyeIcon(),
                hint: 'secret_…',
              ),
              _buildDivider(),
              _buildHelpLink(
                  url: _notionApiKeyVideoUrl,
                  title: _notionApiKeyVideoTitle.tr()),
              _buildDivider(),
              _buildPageFetchRow(),
            ],
          ),
          _buildSection(
            label: 'settings_section_cloudinary'.tr(),
            subtitle: 'settings_cloudinary_subtitle'.tr(),
            icon: Icons.cloud_upload_rounded,
            iconColor: _kRed,
            children: [
              _buildField(
                  label: 'settings_cloud_name'.tr(),
                  controller: _cloudNameController,
                  hint: 'my-cloud'),
              _buildDivider(),
              _buildField(
                  label: 'settings_upload_preset'.tr(),
                  controller: _uploadPresetController,
                  hint: 'unsigned_preset'),
              _buildDivider(),
              _buildHelpLink(
                  url: _cloudinaryUploadPresetVideoUrl,
                  title: _cloudinaryUploadPresetVideoTitle.tr()),
            ],
          ),
          if (showFocusSection)
            _buildSection(
              label: 'settings_section_focus'.tr(),
              subtitle: 'settings_focus_subtitle'.tr(),
              icon: Icons.block_rounded,
              iconColor: _kRed,
              children: [
                _buildInterceptRow(),
              ],
            ),
          _buildSection(
            label: 'settings_section_streak'.tr(),
            subtitle: 'settings_streak_subtitle'.tr(),
            icon: Icons.local_fire_department_rounded,
            iconColor: _kRed,
            children: [
              _buildNavRow(
                label: 'settings_streak_nav'.tr(),
                onTap: () => context.push('/streak'),
              ),
            ],
          ),
          _buildSection(
            label: 'settings_section_goals'.tr(),
            subtitle: 'settings_goals_subtitle'.tr(),
            icon: Icons.flag_rounded,
            iconColor: _kCyan,
            children: [
              _buildGoalReminderRow(),
              _buildDivider(),
              _buildNavRow(
                label: 'settings_view_all_goals'.tr(),
                onTap: () => context.push('/goals'),
              ),
            ],
          ),
          _buildSection(
            label: 'settings_section_profile'.tr(),
            subtitle: null,
            icon: Icons.person_rounded,
            iconColor: _kWhite60,
            children: [
              _buildNavRow(
                label: 'settings_liked_videos'.tr(),
                onTap: () => context.push('/liked-videos'),
              ),
            ],
          ),
          _buildSection(
            label: 'settings_section_open_source'.tr(),
            subtitle: 'settings_open_source_subtitle'.tr(),
            icon: Icons.code_rounded,
            iconColor: _kCyan,
            children: [
              _buildOpenSourceRow(),
            ],
          ),
          _buildSection(
            label: 'settings_section_suggest'.tr(),
            subtitle: 'settings_suggest_subtitle'.tr(),
            icon: Icons.lightbulb_outline_rounded,
            iconColor: _kCyan,
            children: [
              _buildSuggestRow(),
            ],
          ),
          _buildSection(
            label: 'settings_section_upcoming'.tr(),
            subtitle: 'settings_upcoming_subtitle'.tr(),
            icon: Icons.auto_awesome_rounded,
            iconColor: _kRed,
            children: _buildUpcomingFeatures(),
          ),
          const SizedBox(height: 32),
          _buildFooter(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      title: _buildAppBarTitle(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFF2A2A2A), height: 0.5),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'settings_title'.tr(),
          style: const TextStyle(
            color: _kWhite,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        // const SizedBox(width: 8),
        // Auto-saved pill indicator
        // AnimatedBuilder(
        //   animation: _saveIndicatorOpacity,
        //   builder: (_, __) => Opacity(
        //     opacity: _saveIndicatorOpacity.value,
        //     child: Container(
        //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        //       decoration: BoxDecoration(
        //         color: _kCyan.withOpacity(0.15),
        //         borderRadius: BorderRadius.circular(20),
        //         border: Border.all(color: _kCyan.withOpacity(0.4), width: 0.8),
        //       ),
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           const Icon(Icons.check_rounded, color: _kCyan, size: 11),
        //           const SizedBox(width: 3),
        //           Text(
        //             'settings_saved_label'.tr(),
        //             style: const TextStyle(
        //               color: _kCyan,
        //               fontSize: 11,
        //               fontWeight: FontWeight.w600,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BRAND DIVIDER  (TikTok red/cyan shadow bar)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBrandDivider() {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kCyan, _kRed],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SECTION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSection({
    required String label,
    required String? subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: _kWhite30,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Card
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 0.8),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FIELD TILE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: _kWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              textAlign: TextAlign.end,
              cursorColor: _kCyan,
              style: const TextStyle(
                color: _kWhite60,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: hint ?? 'settings_required_hint'.tr(),
                hintStyle: const TextStyle(color: _kWhite12, fontSize: 13),
                border: InputBorder.none,
                suffixIcon: suffix,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PAGE FETCH ROW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPageFetchRow() {
    final showDropdown = _availableDatabases.isNotEmpty;
    final hasSelected = _dbIdController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: _isFetching
          ? const SizedBox(
              key: ValueKey('loading'),
              child: TikTokLoadingAnimation(),
            )
          : Row(
              children: [
                Text(
                  'settings_page_label'.tr(),
                  style: const TextStyle(
                    color: _kWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(), // pushes dropdown to the right

                if (showDropdown)
                  SizedBox(
                    width: 180, // control distance + prevent centering
                    child: _buildDropdown(),
                  )
                else
                  SizedBox(
                    width: 180,
                    child: Text(
                      hasSelected
                          ? _dbIdController.text
                          : 'settings_none_fetched'.tr(),
                      style: TextStyle(
                        color: hasSelected ? _kWhite60 : _kWhite30,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: _isFetching ? null : _fetchDatabases,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: const ValueKey('refresh'),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _kCyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: _kCyan,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDropdown() {
    return ButtonTheme(
      alignedDropdown: true,
      minWidth: 0,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: _kSurface2,
          icon:
              const Icon(Icons.expand_more_rounded, color: _kWhite30, size: 16),
          isExpanded: false,
          isDense: true,
          value: _availableDatabases.any((d) => d['id'] == _dbIdController.text)
              ? _dbIdController.text
              : null,
          items: _availableDatabases.map((db) {
            return DropdownMenuItem(
              value: db['id'],
              child: Text(
                db['title']!,
                style: const TextStyle(color: _kCyan, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (v) async {
            setState(() => _dbIdController.text = v!);
            final storage = context.read<StorageService>();
            await storage.saveNotionDatabaseId(v!);
            _flashSaved();
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  INTERCEPT ROW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInterceptRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: _kRed, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings_intercept_title'.tr(),
                  style: const TextStyle(
                    color: _kWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _interceptEnabled
                      ? 'settings_intercept_active'.tr()
                      : 'settings_disabled_label'.tr(),
                  style: TextStyle(
                    color:
                        _interceptEnabled ? _kCyan.withOpacity(0.8) : _kWhite30,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildTikTokSwitch(
            value: _interceptEnabled,
            onChanged: _toggleIntercept,
          ),
        ],
      ),
    );
  }

  //  GOAL REMINDER ROW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGoalReminderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _kCyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flag_rounded, color: _kCyan, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings_goal_reminder_title'.tr(),
                  style: const TextStyle(
                    color: _kWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _goalReminderEnabled
                      ? 'settings_goal_reminder_active'.tr()
                      : 'settings_disabled_label'.tr(),
                  style: TextStyle(
                    color: _goalReminderEnabled
                        ? _kCyan.withOpacity(0.8)
                        : _kWhite30,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildTikTokSwitch(
            value: _goalReminderEnabled,
            onChanged: _toggleGoalReminder,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleGoalReminder(bool value) async {
    final goalService = context.read<GoalService>();
    await goalService.setGoalReminderEnabled(value);
    setState(() {
      _goalReminderEnabled = value;
    });
  }

  /// TikTok-branded switch: cyan track when on, red thumb glow
  Widget _buildTikTokSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: _kBg,
      activeTrackColor: _kCyan,
      inactiveThumbColor: _kWhite30,
      inactiveTrackColor: _kWhite12,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  NAV ROW (Liked Videos, etc.)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNavRow({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: _kWhite, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: _kWhite30, size: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  OPEN SOURCE ROW
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOpenSourceRow() {
    return InkWell(
      onTap: () => _launchUrl(_githubRepoUrl),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.code_rounded, color: _kCyan, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings_open_source_title'.tr(),
                    style: const TextStyle(
                      color: _kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'settings_open_source_description'.tr(),
                    style: const TextStyle(
                      color: _kWhite30,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: _kWhite30, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestRow() {
    return InkWell(
      onTap: () => _showSuggestDialog(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded,
                  color: _kCyan, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings_suggest_title'.tr(),
                    style: const TextStyle(
                      color: _kWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'settings_suggest_description'.tr(),
                    style: const TextStyle(
                      color: _kWhite30,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kWhite30, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSuggestDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        title: Text(
          'settings_suggest_dialog_title'.tr(),
          style: const TextStyle(color: _kWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: _kWhite),
              decoration: InputDecoration(
                hintText: 'settings_suggest_title_hint'.tr(),
                hintStyle: const TextStyle(color: _kWhite30),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _kBorder),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _kCyan),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: _kWhite),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'settings_suggest_desc_hint'.tr(),
                hintStyle: const TextStyle(color: _kWhite30),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _kBorder),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: _kCyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('settings_suggest_cancel'.tr(),
                style: const TextStyle(color: _kWhite30)),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  descController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('suggestions').add({
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'createdAt': DateTime.now().toIso8601String(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _snack('settings_suggest_success'.tr());
              }
            },
            child: Text('settings_suggest_submit'.tr(),
                style: const TextStyle(color: _kCyan)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUpcomingFeatures() {
    final features = [
      {
        'icon': '🎥',
        'title': 'upcoming_youtube_courses'.tr(),
        'desc': 'upcoming_youtube_courses_desc'.tr()
      },
      {
        'icon': '🖥️',
        'title': 'upcoming_desktop'.tr(),
        'desc': 'upcoming_desktop_desc'.tr()
      },
      {
        'icon': '🔐',
        'title': 'upcoming_saf'.tr(),
        'desc': 'upcoming_saf_desc'.tr()
      },
      {
        'icon': '🎬',
        'title': 'upcoming_entertainment'.tr(),
        'desc': 'upcoming_entertainment_desc'.tr()
      },
      {
        'icon': '🤖',
        'title': 'upcoming_ai'.tr(),
        'desc': 'upcoming_ai_desc'.tr()
      },
      {
        'icon': '🌙',
        'title': 'upcoming_light_mode'.tr(),
        'desc': 'upcoming_light_mode_desc'.tr()
      },
      {
        'icon': '📱',
        'title': 'upcoming_widget'.tr(),
        'desc': 'upcoming_widget_desc'.tr()
      },
    ];

    return features.asMap().entries.map((entry) {
      final index = entry.key;
      final feature = entry.value;
      return Column(
        children: [
          if (index > 0) _buildDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(feature['icon']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title']!,
                        style: const TextStyle(
                            color: _kWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature['desc']!,
                        style: const TextStyle(color: _kWhite30, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'upcoming_soon'.tr(),
                    style: const TextStyle(
                        color: _kRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HELP LINK
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHelpLink({required String url, required String title}) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // TikTok-style play badge
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kCyan, _kRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: _kWhite, size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
              title,
              maxLines: 2,
              style: const TextStyle(
                color: _kWhite60,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )),
            // const Spacer(),
            const Icon(Icons.open_in_new_rounded, color: _kWhite30, size: 14),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  UTILITIES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDivider() =>
      const Divider(color: _kBorder, height: 1, indent: 16);

  Widget _buildEyeIcon() {
    return IconButton(
      icon: Icon(
        _obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: _kWhite30,
        size: 18,
      ),
      onPressed: () => setState(() => _obscureKey = !_obscureKey),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Mini TikTok-style logo row
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     Container(
        //       width: 18,
        //       height: 18,
        //       decoration: BoxDecoration(
        //         gradient: const LinearGradient(
        //           colors: [_kCyan, _kRed],
        //           begin: Alignment.topLeft,
        //           end: Alignment.bottomRight,
        //         ),
        //         borderRadius: BorderRadius.circular(4),
        //       ),
        //       child: const Icon(Icons.music_note_rounded,
        //           color: _kWhite, size: 11),
        //     ),
        //     const SizedBox(width: 6),
        //     const Text(
        //       'TikGood',
        //       style: TextStyle(
        //         color: _kWhite60,
        //         fontSize: 13,
        //         fontWeight: FontWeight.w700,
        //         letterSpacing: -0.3,
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 6),
        Text(
          '${'settings_version_label'.tr()} 0.0.1',
          style: const TextStyle(color: _kWhite30, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _fetchDatabases() async {
    setState(() => _isFetching = true);
    try {
      final dbs = await context
          .read<NotionService>()
          .fetchPages(_apiKeyController.text.trim());
      setState(() => _availableDatabases = dbs);
    } catch (_) {
      _snack('settings_fetch_error'.tr());
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
