import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/courses/data/models/course.dart';
import 'features/courses/data/models/video.dart';
import 'features/courses/data/models/liked_video.dart';
import 'features/notes/data/models/note.dart';
import 'firebase_options.dart';
import 'core/database/storage_service.dart';
import 'features/notes/data/datasources/notion_service.dart';
import 'features/home/presentation/bloc/app_cubit.dart';
import 'features/courses/data/datasources/video_service.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Firebase
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CourseAdapter());
  Hive.registerAdapter(VideoAdapter());
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(LikedVideoAdapter());

  // Services
  final storageService = StorageService();
  await storageService.init();
  final notionService = NotionService(storageService);
  final videoService = VideoService();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<StorageService>.value(value: storageService),
          RepositoryProvider<VideoService>.value(value: videoService),
          RepositoryProvider<NotionService>.value(value: notionService),
        ],
        child: BlocProvider(
          // Pass notionService directly — no context.read needed
          create: (_) => AppCubit(storageService, videoService, notionService),
          child: const TikGoodApp(),
        ),
      ),
    ),
  );
}

class TikGoodApp extends StatelessWidget {
  const TikGoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => ClarityWidget(
        clarityConfig: ClarityConfig(
          projectId: 's1j4mcipjt',
          logLevel: LogLevel.None,
        ),
        app: MaterialApp.router(
          title: 'TikGood',
          debugShowCheckedModeBanner: false,
          // debugShowMaterialGrid: true,
          // showPerformanceOverlay: true,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
            primaryColor: const Color(0xFFFE2C55),
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
