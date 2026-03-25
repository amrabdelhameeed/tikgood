import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../features/courses/data/models/video.dart';
import '../features/courses/data/models/course.dart';
import 'package:avatar_plus/avatar_plus.dart';

// ─── Data model for the recursive tree ───────────────────────────────────────

class _FolderNode {
  final String name;
  final Map<String, _FolderNode> children = {};
  final List<Video> videos = [];

  _FolderNode(this.name);

  /// Insert a video into the tree by splitting its subPath into segments.
  void insert(Video video) {
    final rawPath = video.subPath ?? '';
    final segments = rawPath
        .replaceAll('\\', '/')
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      videos.add(video);
      return;
    }

    children
        .putIfAbsent(segments.first, () => _FolderNode(segments.first))
        .insertAt(segments.sublist(1), video);
  }

  void insertAt(List<String> segments, Video video) {
    if (segments.isEmpty) {
      videos.add(video);
      return;
    }
    children
        .putIfAbsent(segments.first, () => _FolderNode(segments.first))
        .insertAt(segments.sublist(1), video);
  }

  bool containsVideo(String videoId) {
    if (videos.any((v) => v.id == videoId)) return true;
    return children.values.any((c) => c.containsVideo(videoId));
  }
}

// ─── Main Drawer ──────────────────────────────────────────────────────────────

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
    final colorScheme = Theme.of(context).colorScheme;

    // Build one root FolderNode per course
    final Map<String, _FolderNode> courseRoots = {};
    final Map<String, String> courseNameToId = {};

    for (final course in courses) {
      courseNameToId[course.name] = course.id;
      courseRoots[course.name] = _FolderNode(course.name);
    }

    for (final video in videos) {
      final course = courses.firstWhere(
        (c) => c.id == video.courseId,
        orElse: () => Course(id: 'unknown', name: 'Unknown', folderPath: ''),
      );
      courseRoots
          .putIfAbsent(course.name, () => _FolderNode(course.name))
          .insert(video);
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
                itemCount: courseRoots.length,
                itemBuilder: (context, index) {
                  final entry = courseRoots.entries.elementAt(index);
                  return _CourseSection(
                    courseName: entry.key,
                    courseId: courseNameToId[entry.key] ?? '',
                    root: entry.value,
                    allVideos: videos,
                    currentVideoId: currentVideoId,
                    lastViewedVideoId: lastViewedVideoId,
                    onVideoSelected: onVideoSelected,
                  );
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
      child: Row(
        children: [
          Icon(Icons.layers_outlined, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            "learning_path_title".tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Course-level section (Level 0) ──────────────────────────────────────────

class _CourseSection extends StatelessWidget {
  final String courseName;
  final String courseId;
  final _FolderNode root;
  final List<Video> allVideos;
  final String? currentVideoId;
  final String? lastViewedVideoId;
  final Function(int) onVideoSelected;

  const _CourseSection({
    required this.courseName,
    required this.courseId,
    required this.root,
    required this.allVideos,
    required this.currentVideoId,
    required this.lastViewedVideoId,
    required this.onVideoSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course header row
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 16, bottom: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    context.push('/course/${Uri.encodeComponent(courseId)}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AvatarPlus(courseName, height: 18, width: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      context.push('/course/${Uri.encodeComponent(courseId)}'),
                  child: Text(
                    courseName.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Videos directly under the course root (no subPath)
        if (root.videos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: _VideoList(
              videos: root.videos,
              allVideos: allVideos,
              currentVideoId: currentVideoId,
              lastViewedVideoId: lastViewedVideoId,
              onVideoSelected: onVideoSelected,
              depth: 0,
            ),
          ),

        // Recursive sub-folders
        ...root.children.values.map(
          (child) => _FolderTile(
            node: child,
            allVideos: allVideos,
            currentVideoId: currentVideoId,
            lastViewedVideoId: lastViewedVideoId,
            onVideoSelected: onVideoSelected,
            depth: 0,
          ),
        ),
      ],
    );
  }
}

// ─── Recursive folder tile ────────────────────────────────────────────────────

class _FolderTile extends StatelessWidget {
  final _FolderNode node;
  final List<Video> allVideos;
  final String? currentVideoId;
  final String? lastViewedVideoId;
  final Function(int) onVideoSelected;
  final int depth;

  const _FolderTile({
    required this.node,
    required this.allVideos,
    required this.currentVideoId,
    required this.lastViewedVideoId,
    required this.onVideoSelected,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = (currentVideoId != null &&
            node.containsVideo(currentVideoId!)) ||
        (lastViewedVideoId != null && node.containsVideo(lastViewedVideoId!));

    // Depth-based indentation (12px per level, capped so it doesn't go crazy)
    final leftPad = 12.0 + (depth * 12.0).clamp(0.0, 48.0);

    return Container(
      margin: EdgeInsets.only(left: leftPad, bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.surfaceContainerLow : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? colorScheme.outlineVariant : Colors.transparent,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isActive,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: EdgeInsets.zero,
          leading: Icon(
            isActive ? Icons.folder_open_rounded : Icons.folder_rounded,
            size: 20,
            color: isActive ? colorScheme.primary : colorScheme.outline,
          ),
          title: Text(
            node.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          // Show child count badge when collapsed
          trailing: isActive
              ? null
              : _CountBadge(
                  count: _countVideos(node),
                  colorScheme: colorScheme,
                ),
          children: [
            // Sub-folders first, then videos
            ...node.children.values.map(
              (child) => _FolderTile(
                node: child,
                allVideos: allVideos,
                currentVideoId: currentVideoId,
                lastViewedVideoId: lastViewedVideoId,
                onVideoSelected: onVideoSelected,
                depth: depth + 1,
              ),
            ),

            // Videos at this folder level
            if (node.videos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: _VideoList(
                  videos: node.videos,
                  allVideos: allVideos,
                  currentVideoId: currentVideoId,
                  lastViewedVideoId: lastViewedVideoId,
                  onVideoSelected: onVideoSelected,
                  depth: depth,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _countVideos(_FolderNode n) {
    return n.videos.length +
        n.children.values.fold(0, (sum, c) => sum + _countVideos(c));
  }
}

// ─── Video leaf list with hierarchy connector lines ───────────────────────────

class _VideoList extends StatelessWidget {
  final List<Video> videos;
  final List<Video> allVideos;
  final String? currentVideoId;
  final String? lastViewedVideoId;
  final Function(int) onVideoSelected;
  final int depth;

  const _VideoList({
    required this.videos,
    required this.allVideos,
    required this.currentVideoId,
    required this.lastViewedVideoId,
    required this.onVideoSelected,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: videos
          .map((v) => _VideoLeaf(
                video: v,
                allVideos: allVideos,
                currentVideoId: currentVideoId,
                lastViewedVideoId: lastViewedVideoId,
                onVideoSelected: onVideoSelected,
              ))
          .toList(),
    );
  }
}

class _VideoLeaf extends StatelessWidget {
  final Video video;
  final List<Video> allVideos;
  final String? currentVideoId;
  final String? lastViewedVideoId;
  final Function(int) onVideoSelected;

  const _VideoLeaf({
    required this.video,
    required this.allVideos,
    required this.currentVideoId,
    required this.lastViewedVideoId,
    required this.onVideoSelected,
  });

  static const _tikRed = Color(0xFFFE2C55);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrent = video.id == currentVideoId;
    final isLastViewed = video.id == lastViewedVideoId;
    final indexInFeed = allVideos.indexOf(video);

    final accentColor = isLastViewed
        ? _tikRed
        : isCurrent
            ? colorScheme.primary
            : null;

    return IntrinsicHeight(
      child: Row(
        children: [
          // Hierarchy connector line
          Container(
            width: 2,
            margin: const EdgeInsets.only(left: 8),
            color: accentColor ?? colorScheme.outlineVariant,
          ),
          Expanded(
            child: ListTile(
              onTap: () => onVideoSelected(indexInFeed),
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              leading: Icon(
                isLastViewed
                    ? Icons.visibility_rounded
                    : isCurrent
                        ? Icons.play_arrow_rounded
                        : Icons.circle_outlined,
                size: 15,
                color: accentColor ?? colorScheme.outline,
              ),
              title: Text(
                video.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isCurrent || isLastViewed)
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: accentColor ?? colorScheme.onSurface,
                ),
              ),
              trailing: isLastViewed
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _tikRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'last_watched_label'.tr(),
                        style: const TextStyle(
                          color: _tikRed,
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

// ─── Small video-count badge ──────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  final ColorScheme colorScheme;

  const _CountBadge({required this.count, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
