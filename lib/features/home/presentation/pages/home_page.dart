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

    // 1. Check current status based on version
    if (sdkInt >= 33) {
      final storage = await Permission.storage.isGranted;
      final videos = await Permission.videos.isGranted;
      isGranted = storage && videos;
    } else {
      isGranted = await Permission.storage.isGranted;
    }

    // 2. If already granted, stop here.
    if (isGranted) return;

    // 3. If NOT granted, show YOUR dialog first to explain why.
    // This ensures the user sees your UI before the system pop-up.
    _showRationaleDialog(sdkInt);
  }

  Future<void> _showRationaleDialog(int sdkInt) async {
    final bool? beginRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('storage_access_title'.tr()),
          content: Text('storage_access_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('allow'.tr()),
            ),
          ],
        );
      },
    );

    // 4. If user clicked "Allow" in your dialog, trigger the system prompt
    if (beginRequest == true) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        if (sdkInt >= 33) Permission.videos,
      ].request();

      // Check if they denied the system prompt permanently
      if (statuses.values.any((s) => s.isPermanentlyDenied)) {
        openAppSettings();
      }
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
