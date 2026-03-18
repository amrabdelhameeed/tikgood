import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<void> _pickDirectory(BuildContext context) async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null && context.mounted) {
      await context
          .read<AppCubit>()
          .addCourse(selectedDirectory, followByDefault: _followByDefault);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Scanning for videos...',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
      // --- Consistent TikTok AppBar ---
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text('Add Course',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Color(0xFF252525), height: 0.5),
        ),
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // ── Pick Folder Card (High Polish) ──────────────────────
              GestureDetector(
                onTap: state.isLoading ? null : () => _pickDirectory(context),
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
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: _tikTokRed, strokeWidth: 3),
                            SizedBox(height: 16),
                            Text('Syncing Library...',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500)),
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
                            const Text('Import Course Folder',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Tap to browse your files',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 12)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Settings Label ───────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text('PREFERENCES',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
              ),

              // ── Options Card ───────────────────────────────
              _buildSettingTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Follow by default',
                subtitle: 'Add new courses to your feed',
                trailing: Switch.adaptive(
                  value: _followByDefault,
                  onChanged: (v) => setState(() => _followByDefault = v),
                  activeColor: _tikTokRed,
                ),
              ),

              const SizedBox(height: 32),

              // ── Existing Courses Section ──────────────────────
              // if (state.courses.isNotEmpty) ...[
              //   // const Padding(
              //   //   padding: EdgeInsets.only(left: 4, bottom: 12),
              //   //   child: Text('MANAGED COURSES',
              //   //       style: TextStyle(
              //   //           color: Colors.white38,
              //   //           fontSize: 11,
              //   //           fontWeight: FontWeight.w800,
              //   //           letterSpacing: 1.2)),
              //   // ),
              //   ...state.courses
              //       .map((course) => _buildCourseTile(context, course)),
              // ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingTile(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Widget trailing}) {
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

  Widget _buildCourseTile(BuildContext context, Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: course.isFollowed
                    ? [_tikTokRed, _tikTokRed.withOpacity(0.6)]
                    : [Colors.white10, Colors.white10],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              course.isFollowed
                  ? Icons.collections_bookmark_rounded
                  : Icons.folder_copy_rounded,
              color: course.isFollowed ? Colors.white : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  course.folderPath.split(RegExp(r'[/\\]')).last,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: course.isFollowed,
            onChanged: (v) =>
                context.read<AppCubit>().setFollowCourse(course.id, v),
            activeColor: _tikTokRed,
          ),
        ],
      ),
    );
  }
}
