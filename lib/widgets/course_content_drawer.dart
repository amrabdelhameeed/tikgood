import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart'; // Added for localization
import '../features/courses/data/models/video.dart';
import '../features/courses/data/models/course.dart';
import 'package:avatar_plus/avatar_plus.dart';

class CourseContentDrawer extends StatelessWidget {
  final List<Video> videos;
  final List<Course> courses;
  final Function(int) onVideoSelected;
  final String? currentVideoId;
  final String? lastViewedVideoId;

  const CourseContentDrawer({
    required this.videos,
    required this.courses,
    required this.onVideoSelected,
    this.currentVideoId,
    this.lastViewedVideoId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Map<String, Map<String?, List<Video>>> grouped = {};
    for (var video in videos) {
      final course = courses.firstWhere(
        (c) => c.id == video.courseId,
        orElse: () => Course(id: 'unknown', name: 'Unknown', folderPath: ''),
      );
      grouped.putIfAbsent(course.name, () => {});
      grouped[course.name]!.putIfAbsent(video.subPath, () => []);
      grouped[course.name]![video.subPath]!.add(video);
    }

    // Create a map of courseName -> course for navigation
    final courseNameToId = <String, String>{};
    for (var course in courses) {
      courseNameToId[course.name] = course.id;
    }

    return Drawer(
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: grouped.entries.length,
                itemBuilder: (context, index) {
                  final courseEntry = grouped.entries.elementAt(index);
                  return _buildCourseNode(context, courseEntry,
                      courseNameToId[courseEntry.key] ?? '');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                "learning_path_title".tr(), // Localized title
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseNode(
      BuildContext context,
      MapEntry<String, Map<String?, List<Video>>> courseEntry,
      String courseId) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEVEL 1: COURSE
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  context.push('/course/${Uri.encodeComponent(courseId)}');
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AvatarPlus(
                    courseEntry.key,
                    height: 18,
                    width: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  context.push('/course/${Uri.encodeComponent(courseId)}');
                },
                child: Text(
                  courseEntry.key.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              )),
            ],
          ),
        ),
        // LEVEL 2: SECTIONS (Inside the Course)
        ...courseEntry.value.entries.map((subPathEntry) {
          final title = subPathEntry.key?.replaceAll('\\', '/') ??
              "general_concepts".tr(); // Localized fallback
          final videosInPath = subPathEntry.value;
          final isExpanded = videosInPath
              .any((v) => v.id == currentVideoId || v.id == lastViewedVideoId);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isExpanded
                  ? colorScheme.surfaceContainerLow
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded
                    ? colorScheme.outlineVariant
                    : Colors.transparent,
              ),
            ),
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: isExpanded,
                leading: Icon(
                  isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                  color: isExpanded ? colorScheme.primary : colorScheme.outline,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
                    color: isExpanded
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  // LEVEL 3: VIDEOS
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 8),
                    child: Column(
                      children: videosInPath
                          .map((video) => _buildVideoLeaf(context, video))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVideoLeaf(BuildContext context, Video video) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrent = video.id == currentVideoId;
    final isLastViewed = video.id == lastViewedVideoId;
    final indexInFeed = videos.indexOf(video);

    return IntrinsicHeight(
      child: Row(
        children: [
          // The "Hierarchy Line" connector
          Container(
            width: 2,
            margin: const EdgeInsets.only(left: 12),
            color: isLastViewed
                ? const Color(0xFFFE2C55)
                : isCurrent
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
          ),
          Expanded(
            child: ListTile(
              onTap: () => onVideoSelected(indexInFeed),
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(
                isLastViewed
                    ? Icons.visibility_rounded
                    : isCurrent
                        ? Icons.play_arrow_rounded
                        : Icons.circle_outlined,
                size: 16,
                color: isLastViewed
                    ? const Color(0xFFFE2C55)
                    : isCurrent
                        ? colorScheme.primary
                        : colorScheme.outline,
              ),
              title: Text(
                video.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isCurrent || isLastViewed)
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: isLastViewed
                      ? const Color(0xFFFE2C55)
                      : isCurrent
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                ),
              ),
              trailing: isLastViewed
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE2C55).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'last_watched_label'.tr(), // Localized label
                        style: const TextStyle(
                          color: Color(0xFFFE2C55),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
