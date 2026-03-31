import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tikgood/app_router.dart';
import '../../../home/presentation/bloc/app_cubit.dart';
import '../../../home/presentation/bloc/app_state.dart';
import 'package:file_picker/file_picker.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  bool _followByDefault = true;
  static const Color _tikTokRed = Color(0xFFFE2C55);
  static const Color _tikTokCyan = Color(0xFF25F4EE);
  static const Color _cardGrey =
      Color(0xFF161722); // TikTok's specific dark grey

  Future<void> _pickDirectory(BuildContext context) async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null && context.mounted) {
      await context
          .read<AppCubit>()
          .addCourse(selectedDirectory, followByDefault: _followByDefault);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('add_course_scanning_snack'.tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white)),
            backgroundColor: _tikTokRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'add_course_title'.tr(),
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF252525), height: 0.5),
        ),
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              // --- SECTION: IMPORT ---
              _buildSectionHeader('add_course_import_section'.tr()),
              const SizedBox(height: 12),

              // 1. Pick Folder Card (Primary Action)
              GestureDetector(
                onTap: state.isLoading
                    ? null
                    : () {
                        _pickDirectory(context);
                        AppRouter.router.go('/');
                      },
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: _cardGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.isLoading
                          ? _tikTokRed
                          : Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: _tikTokRed, strokeWidth: 2))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.drive_folder_upload_rounded,
                                color: Colors.white, size: 42),
                            const SizedBox(height: 12),
                            Text(
                              'add_course_import_folder'.tr(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'add_course_tap_to_browse'.tr(),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. YouTube Card (Secondary/Disabled state)
              _buildYouTubeSoonCard(),

              const SizedBox(height: 32),

              // --- SECTION: PREFERENCES ---
              _buildSectionHeader('add_course_preferences'.tr()),
              const SizedBox(height: 12),

              // Settings Tile
              _buildSettingTile(
                icon: Icons.auto_awesome_rounded,
                title: 'add_course_follow_default'.tr(),
                subtitle: 'add_course_follow_subtitle'.tr(),
                trailing: Switch.adaptive(
                  value: _followByDefault,
                  onChanged: (v) => setState(() => _followByDefault = v),
                  activeColor: _tikTokRed,
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // --- UI Components for Consistency ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildYouTubeSoonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_circle_filled,
                color: Colors.white24, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'add_course_youtube_title'.tr(),
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  'add_course_youtube_subtitle'.tr(),
                  style: const TextStyle(color: Colors.white12, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'add_course_soon'.tr().toUpperCase(),
              style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
