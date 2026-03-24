import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tikgood/app_router.dart';
import 'package:tikgood/features/courses/data/models/course.dart';
import '../../../home/presentation/bloc/app_cubit.dart';
import '../../../home/presentation/bloc/app_state.dart';
import '../../../../core/database/storage_service.dart';
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
                style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: _tikTokRed,
            behavior: SnackBarBehavior.floating,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── Pick Folder Card ─────────────────────────────────────────
              GestureDetector(
                onTap: state.isLoading
                    ? null
                    : () {
                        _pickDirectory(context);
                        AppRouter.router.go('/');
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: state.isLoading ? _tikTokRed : Colors.white10,
                        width: 1.5),
                  ),
                  child: state.isLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                                color: _tikTokRed, strokeWidth: 3),
                            const SizedBox(height: 16),
                            Text(
                              'add_course_scanning'.tr(),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _tikTokRed.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: _tikTokRed, size: 40),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'add_course_import_folder'.tr(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'add_course_tap_to_browse'.tr(),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // ── YouTube Coming Soon Card ──────────────────────────────────
              _buildYouTubeSoonCard(),

              const SizedBox(height: 24),

              // ── Preferences Label ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'add_course_preferences'.tr(),
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2),
                ),
              ),

              // ── Options Card ──────────────────────────────────────────────
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

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ── YouTube Coming Soon Card ───────────────────────────────────────────────

  Widget _buildYouTubeSoonCard() {
    return Stack(
      children: [
        // Dimmed card
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.06), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // YouTube icon badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.red, size: 36),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'add_course_youtube_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'add_course_youtube_subtitle'.tr(),
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // SOON badge
        Positioned(
          top: 10,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _tikTokCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _tikTokCyan.withOpacity(0.5), width: 0.8),
            ),
            child: Text(
              'add_course_soon'.tr(),
              style: const TextStyle(
                color: _tikTokCyan,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Setting Tile ───────────────────────────────────────────────────────────

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
