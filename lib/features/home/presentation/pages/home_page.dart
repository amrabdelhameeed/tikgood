import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../widgets/video_player/video_feed_view.dart';
import '../../../../widgets/course_content_drawer.dart';
import '../../../../core/database/storage_service.dart';
import '../bloc/app_cubit.dart';
import '../bloc/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<VideoFeedViewState> _feedKey = GlobalKey<VideoFeedViewState>();

  Future<void> _requestPermissions() async {
    await Permission.videos.request();
    await Permission.storage.request();
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      drawer: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          // Calculate current video ID for selection highlighting
          String? currentVideoId;
          // Note: Ideally we'd get this from the feed state, but for now we can rely on index
          // if we pass it back or use a more robust way to track active video in cubit.

          final lastViewedVideoId =
              context.read<StorageService>().getLastViewedVideoId();

          return CourseContentDrawer(
            videos: state.videoFeed,
            courses: state.courses,
            currentVideoId: currentVideoId,
            lastViewedVideoId: lastViewedVideoId,
            onVideoSelected: (index) {
              Navigator.pop(context); // Close drawer
              _feedKey.currentState?.animateToVideo(index);
            },
          );
        },
      ),
      body: VideoFeedView(
        key: _feedKey,
        scaffoldKey: _scaffoldKey,
      ),
    );
  }
}
