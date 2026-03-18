import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tikgood/core/utils/accessibility_intercept_service.dart';
import '../../../../core/database/storage_service.dart';
import '../../../notes/data/datasources/notion_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  late TextEditingController _apiKeyController;
  late TextEditingController _dbIdController;
  late TextEditingController _cloudNameController;
  late TextEditingController _uploadPresetController;

  List<Map<String, String>> _availableDatabases = [];
  bool _isFetching = false;
  bool _isSyncing = false;
  bool _obscureKey = true;

  // ── Intercept state ────────────────────────────────────────────────────────
  bool _interceptEnabled = false;

  static const double _hPadding = 16.0;
  static const Color _surface = Color(0xFF121212);
  static const Color _accent = Color(0xFFFE2C55);
  static const Color _divider = Color(0xFF252525);

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
    _checkInterceptStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiKeyController.dispose();
    _dbIdController.dispose();
    _cloudNameController.dispose();
    _uploadPresetController.dispose();
    super.dispose();
  }

  // Re-check when user comes back from Accessibility Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkInterceptStatus();
  }

  Future<void> _checkInterceptStatus() async {
    final enabled = await AccessibilityInterceptService.isServiceEnabled();
    if (mounted) setState(() => _interceptEnabled = enabled);
  }

  Future<void> _toggleIntercept(bool value) async {
    if (value) {
      // Request overlay permission first, then open accessibility settings
      await AccessibilityInterceptService.requestOverlayPermission();
      await AccessibilityInterceptService.openAccessibilitySettings();
      // Status will update via didChangeAppLifecycleState on return
    } else {
      // Direct them to disable it in accessibility settings
      await AccessibilityInterceptService.openAccessibilitySettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildSectionLabel('INTEGRATIONS'),
          _buildSettingsGroup([
            _buildInputTile(
              label: 'Notion API Key',
              controller: _apiKeyController,
              obscure: _obscureKey,
              suffix: _buildVisibilityIcon(),
            ),
            _buildInputTile(
              label: 'Page ID',
              controller: _dbIdController,
              hint: 'Paste ID or select...',
            ),
            _buildDatabasePickerTile(),
          ]),
          _buildSectionLabel('STORAGE'),
          _buildSettingsGroup([
            _buildInputTile(
                label: 'Cloud Name', controller: _cloudNameController),
            _buildInputTile(
                label: 'Upload Preset', controller: _uploadPresetController),
          ]),

          // ── NEW: Focus section ───────────────────────────────────────────
          _buildSectionLabel('FOCUS'),
          _buildSettingsGroup([
            _buildInterceptTile(),
          ]),
          // ── End Focus section ────────────────────────────────────────────

          _buildSectionLabel('PROFILE'),
          _buildSettingsGroup([
            _buildLikedVideosTile(),
          ]),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Intercept tile ─────────────────────────────────────────────────────────
  Widget _buildInterceptTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.swap_horiz_rounded, color: _accent, size: 19),
          ),
          const SizedBox(width: 12),
          // Label + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Intercept TikTok',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _interceptEnabled
                      ? 'Active — prompts when TikTok opens'
                      : 'Opens TikGood instead of TikTok',
                  style: TextStyle(
                    color: _interceptEnabled
                        ? _accent.withOpacity(0.8)
                        : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Toggle
          Switch(
            value: _interceptEnabled,
            onChanged: _toggleIntercept,
            activeColor: _accent,
            activeTrackColor: _accent.withOpacity(0.25),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // ── Rest of existing UI (unchanged) ───────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      title: const Text('Settings',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: _divider, height: 0.5),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPadding, 24, _hPadding, 8),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _hPadding),
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final child = entry.value;
          return Column(
            children: [
              child,
              if (idx != children.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Divider(color: _divider, height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputTile({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 15)),
          const Spacer(),
          Expanded(
            flex: 4,
            child: TextField(
              controller: controller,
              obscureText: obscure,
              textAlign: TextAlign.end,
              cursorColor: _accent,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint ?? 'Required',
                hintStyle: const TextStyle(color: Colors.white12),
                border: InputBorder.none,
                suffixIcon: suffix,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabasePickerTile() {
    return InkWell(
      onTap: _isFetching ? null : _fetchDatabases,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Text('Select Page',
                style: TextStyle(color: Colors.white, fontSize: 15)),
            const Spacer(),
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: _isFetching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _accent),
                          )
                        : (_availableDatabases.isNotEmpty
                            ? _buildDropdown()
                            : const Text('Fetch list',
                                style: TextStyle(
                                    color: _accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600))),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      color: Colors.white24, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikedVideosTile() {
    return InkWell(
      onTap: () => context.push('/liked-videos'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: const Row(
          children: [
            Text('Liked Videos',
                style: TextStyle(color: Colors.white, fontSize: 15)),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        dropdownColor: _surface,
        icon: const SizedBox.shrink(),
        isExpanded: false,
        value: _availableDatabases.any((d) => d['id'] == _dbIdController.text)
            ? _dbIdController.text
            : null,
        items: _availableDatabases.map((db) {
          return DropdownMenuItem(
            value: db['id'],
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(db['title']!,
                  style: const TextStyle(color: _accent, fontSize: 14),
                  overflow: TextOverflow.ellipsis),
            ),
          );
        }).toList(),
        onChanged: (v) => setState(() => _dbIdController.text = v!),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPadding),
      child: Column(
        children: [
          _buildPrimaryButton(
            onPressed: _isSyncing ? null : _sync,
            label: _isSyncing ? 'Syncing...' : 'Sync to Notion',
            icon: Icons.sync,
          ),
          const SizedBox(height: 12),
          _buildSecondaryButton(
            onPressed: _saveSettings,
            label: 'Save Changes',
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _divider, width: 1.5),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildVisibilityIcon() {
    return IconButton(
      icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility,
          color: Colors.white24, size: 18),
      onPressed: () => setState(() => _obscureKey = !_obscureKey),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text('TikGood for Mobile',
            style: TextStyle(
                color: Colors.white24,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        Text('Version 1.0.4',
            style: TextStyle(color: Colors.white10, fontSize: 11)),
      ],
    );
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: _accent,
      behavior: SnackBarBehavior.floating));

  Future<void> _fetchDatabases() async {
    setState(() => _isFetching = true);
    try {
      final dbs = await context
          .read<NotionService>()
          .fetchPages(_apiKeyController.text.trim());
      setState(() => _availableDatabases = dbs);
    } catch (e) {
      _snack('Failed to fetch databases');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _sync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isSyncing = false);
    _snack('Sync Complete');
  }

  Future<void> _saveSettings() async {
    final storage = context.read<StorageService>();
    await Future.wait([
      storage.saveNotionApiKey(_apiKeyController.text.trim()),
      storage.saveNotionDatabaseId(_dbIdController.text.trim()),
      storage.saveCloudinaryCloudName(_cloudNameController.text.trim()),
      storage.saveCloudinaryUploadPreset(_uploadPresetController.text.trim()),
    ]);
    _snack('Settings Saved');
  }
}
