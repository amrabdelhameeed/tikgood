import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart'; // Added for .tr()
import '../../../home/presentation/bloc/app_cubit.dart';
import '../../../home/presentation/bloc/app_state.dart';
import 'package:avatar_plus/avatar_plus.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  // TikTok Design Constants
  static const Color _accentColor = Color(0xFFFE2C55); // TikTok Red/Pink
  static const Color _surfaceColor = Color(0xFF161722); // TikTok Dark Grey

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'following_title'.tr(), // Updated with .tr()
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF252525), height: 0.5),
        ),
      ),
      body: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final courses = state.courses;

          if (courses.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final isFollowed = course.isFollowed;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    // --- Circular Avatar ---
                    GestureDetector(
                      onTap: () => context
                          .push('/course/${Uri.encodeComponent(course.id)}'),
                      child: Container(
                        padding: const EdgeInsets.all(1.5), // Border effect
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 1),
                        ),
                        child: ClipOval(
                          child: AvatarPlus(
                            course.name,
                            height: 54,
                            width: 54,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12), // Added small gap for alignment

                    // --- Course Info ---
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context
                            .push('/course/${Uri.encodeComponent(course.id)}'),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Fixed alignment
                          children: [
                            Text(
                              course.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- TikTok Style Follow Button ---
                    _buildFollowButton(context, course.id, isFollowed),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFollowButton(
      BuildContext context, String courseId, bool isFollowed) {
    return SizedBox(
      height: 28,
      width: 88,
      child: TextButton(
        onPressed: () {
          context.read<AppCubit>().setFollowCourse(courseId, !isFollowed);
        },
        style: TextButton.styleFrom(
          backgroundColor: isFollowed ? _surfaceColor : _accentColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          isFollowed
              ? 'following_btn'.tr()
              : 'follow_btn'.tr(), // Updated with .tr()
          style: TextStyle(
            color: isFollowed ? Colors.white.withOpacity(0.9) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_add_alt_1_outlined,
              size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'no_courses_followed'.tr(), // Updated with .tr()
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'no_courses_subtitle'.tr(), // Updated with .tr()
            style: const TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
