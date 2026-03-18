import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
        title: const Text('Following',
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

                    // --- Course Info ---
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context
                            .push('/course/${Uri.encodeComponent(course.id)}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                            // const SizedBox(height: 2),
                            // Text(
                            //   course.name
                            //       .toLowerCase()
                            //       .replaceAll(' ', '_'), // Mock handle
                            //   style: const TextStyle(
                            //     color: Colors.white38,
                            //     fontSize: 13,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),

                    // --- TikTok Style Follow Button ---
                    const Spacer(),
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
          isFollowed ? 'Following' : 'Follow',
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
          const Text(
            'No courses followed',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Courses you follow will appear here.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
