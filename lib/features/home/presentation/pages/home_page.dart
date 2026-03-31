import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
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

    // ✅ Correct permission logic
    if (sdkInt >= 33) {
      isGranted = await Permission.videos.isGranted;
    } else {
      isGranted = await Permission.storage.isGranted;
    }

    // ✅ Stop if already granted
    if (isGranted) return;

    // ✅ Show your custom dialog
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

    Map<Permission, PermissionStatus> statuses = await [
      if (sdkInt >= 33) Permission.videos,
      if (sdkInt < 33) Permission.storage,
    ].request();

    // ✅ If permanently denied → open settings
    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      await openAppSettings();
      return;
    }

    // ✅ Re-check after request to avoid dialog loop
    bool grantedAfterRequest = false;

    if (sdkInt >= 33) {
      grantedAfterRequest = await Permission.videos.isGranted;
    } else {
      grantedAfterRequest = await Permission.storage.isGranted;
    }

    if (!grantedAfterRequest && mounted) {
      // Optional: show again OR handle gracefully
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
        key: _scaffoldKey,
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        drawer: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            String? currentVideoId;
            final lastViewedVideoId =
                context.read<StorageService>().getLastViewedVideoId();

            return CourseContentDrawer(
              videos: state.videoFeed,
              courses: state.courses,
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
