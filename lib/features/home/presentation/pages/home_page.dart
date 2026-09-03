import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:upgrader/upgrader.dart';
import '../../../../widgets/video_player/video_feed_view.dart';
import '../../../../widgets/course_content_drawer.dart';
import '../../../../core/database/storage_service.dart';
import '../bloc/app_cubit.dart';
import '../bloc/app_state.dart';

import 'package:device_info_plus/device_info_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<VideoFeedViewState> _feedKey =
      GlobalKey<VideoFeedViewState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePermissions();
    });
  }

  Future<void> _handlePermissions() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    bool isGranted = false;

    if (sdkInt >= 33) {
      // Android 13+: granular media permissions
      isGranted = await Permission.videos.isGranted;
    } else if (sdkInt >= 30) {
      // Android 11-12: MANAGE_EXTERNAL_STORAGE ("All Files Access")
      isGranted = await Permission.manageExternalStorage.isGranted;
    } else {
      // Android 10 and below
      isGranted = await Permission.storage.isGranted;
    }

    if (isGranted) return;

    if (mounted) {
      _showRationaleDialog(sdkInt);
    }
  }

  Future<void> _showRationaleDialog(int sdkInt) async {
    final bool? beginRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Storage Access'),
          content: const Text(
              'This app needs access to your videos to display your courses.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    if (beginRequest != true) return;

    // Request the correct permission for each Android version
    Map<Permission, PermissionStatus> statuses = {};
    if (sdkInt >= 33) {
      // Android 13+: request granular media permissions
      statuses = await [
        Permission.videos,
        Permission.photos,
        Permission.audio,
      ].request();
    } else if (sdkInt >= 30) {
      // Android 11-12: open the "All Files Access" system settings page
      // (MANAGE_EXTERNAL_STORAGE cannot be requested via dialog)
      await Permission.manageExternalStorage.request();
      // Re-check after returning from settings
      final granted = await Permission.manageExternalStorage.isGranted;
      if (!granted && mounted) {
        debugPrint("MANAGE_EXTERNAL_STORAGE still not granted");
      }
      return;
    } else {
      // Android 10 and below
      statuses = await [
        Permission.storage,
      ].request();
    }

    // If permanently denied → open settings
    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      await openAppSettings();
      return;
    }

    // Re-check after request to avoid dialog loop
    bool grantedAfterRequest = false;
    if (sdkInt >= 33) {
      grantedAfterRequest = await Permission.videos.isGranted;
    } else if (sdkInt >= 30) {
      grantedAfterRequest = await Permission.manageExternalStorage.isGranted;
    } else {
      grantedAfterRequest = await Permission.storage.isGranted;
    }

    if (!grantedAfterRequest && mounted) {
      debugPrint("Permission still not granted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      barrierDismissible: false,
      showIgnore: false,
      showLater: true,
      showReleaseNotes: true,
      upgrader: Upgrader(
        languageCode: Locale('en').languageCode,
        durationUntilAlertAgain: const Duration(days: 1),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        drawer: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            String? currentVideoId;
            final lastViewedVideoId =
                context.read<StorageService>().getLastViewedVideoId();

            // In the Following tab the drawer mirrors the feed: only
            // followed courses, in the same order as the feed.
            final drawerCourses = state.isFollowingTab
                ? state.courses.where((c) => c.isFollowed).toList()
                : state.courses;

            return CourseContentDrawer(
              videos: state.videoFeed,
              courses: drawerCourses,
              currentVideoId: currentVideoId,
              lastViewedVideoId: lastViewedVideoId,
              onVideoSelected: (index) {
                Navigator.pop(context);
                _feedKey.currentState?.animateToVideo(index);
              },
            );
          },
        ),
        body: VideoFeedView(
          key: _feedKey,
          scaffoldKey: _scaffoldKey,
        ),
      ),
    );
  }
}
