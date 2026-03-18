import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avatar_plus/avatar_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../home/presentation/bloc/app_cubit.dart';
import '../../../home/presentation/bloc/app_state.dart';
import '../../data/models/course.dart';
import '../../data/models/video.dart';
import '../../../../core/database/storage_service.dart';
import '../../../../core/utils/thumbnail_cache_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CourseProfilePage
// ─────────────────────────────────────────────────────────────────────────────

class CourseProfilePage extends StatefulWidget {
  final String courseId;

  const CourseProfilePage({super.key, required this.courseId});

  @override
  State<CourseProfilePage> createState() => _CourseProfilePageState();
}

class _CourseProfilePageState extends State<CourseProfilePage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final course = state.courses.firstWhere(
          (c) => c.id == widget.courseId,
          orElse: () => Course(id: '', name: 'Unknown', folderPath: ''),
        );

        if (course.id.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: Text('Course not found',
                  style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final storage = context.read<StorageService>();
        final videos = storage.getVideosForCourse(course.id);

        return Scaffold(
          backgroundColor: Colors.black,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, course),
              _buildProfileHeader(context, course, videos.length),
              _buildVideoGrid(context, videos),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, Course course) {
    return SliverAppBar(
      backgroundColor: Colors.black,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(
        course.name,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Course course, int videoCount) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFE2C55), width: 2),
              ),
              child: ClipOval(
                child: AvatarPlus(course.name, width: 96, height: 96),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              course.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem('$videoCount', 'Videos'),
                const SizedBox(width: 32),
                _buildStatItem(
                    course.isFollowed ? 'Following' : 'Follow', 'Status'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context
                    .read<AppCubit>()
                    .setFollowCourse(course.id, !course.isFollowed),
                style: ElevatedButton.styleFrom(
                  backgroundColor: course.isFollowed
                      ? Colors.white
                      : const Color(0xFFFE2C55),
                  foregroundColor:
                      course.isFollowed ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  course.isFollowed ? 'Following ✓' : 'Follow',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }

  Widget _buildVideoGrid(BuildContext context, List<Video> videos) {
    if (videos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.video_library_outlined,
                    size: 64, color: Colors.white12),
                SizedBox(height: 16),
                Text('No videos yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1 / 1.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final video = videos[index];
            return _VideoGridItem(
              video: video,
              onTap: () => _playVideo(context, video, videos),
            );
          },
          childCount: videos.length,
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, Video video, List<Video> allVideos) {
    // Navigate to the video player page with video details
    context.push(
      '/video?path=${Uri.encodeComponent(video.filePath)}&name=${Uri.encodeComponent(video.name)}',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VideoGridItem — delegates thumbnail loading to ThumbnailCacheService
// ─────────────────────────────────────────────────────────────────────────────

class _VideoGridItem extends StatefulWidget {
  final Video video;
  final VoidCallback onTap;

  const _VideoGridItem({required this.video, required this.onTap});

  @override
  State<_VideoGridItem> createState() => _VideoGridItemState();
}

class _VideoGridItemState extends State<_VideoGridItem> {
  String? _thumbnailPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final path = await ThumbnailCacheService.instance
        .getThumbnail(widget.video.filePath);
    if (mounted) {
      setState(() {
        _thumbnailPath = path;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isLoading)
            Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFE2C55),
                ),
              ),
            )
          else if (_thumbnailPath != null)
            Image.file(File(_thumbnailPath!), fit: BoxFit.cover)
          else
            Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(
                child: Icon(Icons.play_circle_fill,
                    color: Color(0xFFFE2C55), size: 40),
              ),
            ),
          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
          // Video name
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              widget.video.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Watch progress badge
          if (widget.video.lastSecondWatched > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE2C55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}
