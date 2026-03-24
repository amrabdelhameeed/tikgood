import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mk;
import 'package:easy_localization/easy_localization.dart'; // Added for localization
import '../../../../core/database/storage_service.dart';
import '../../../../core/utils/thumbnail_cache_service.dart';
import '../../../courses/data/models/video.dart';

class LikedVideosPage extends StatefulWidget {
  const LikedVideosPage({super.key});

  @override
  State<LikedVideosPage> createState() => _LikedVideosPageState();
}

class _LikedVideosPageState extends State<LikedVideosPage> {
  List<Map<String, dynamic>> _likedVideosWithDetails = [];
  bool _isLoading = true;

  // TikTok-style colors
  static const Color _accentColor = Color(0xFFFE2C55);
  static const Color _surfaceColor = Color(0xFF161722);

  @override
  void initState() {
    super.initState();
    _loadLikedVideos();
  }

  void _loadLikedVideos() {
    final storage = context.read<StorageService>();
    setState(() {
      _likedVideosWithDetails = storage.getLikedVideosWithDetails();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Liked Videos'.tr(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF252525), height: 0.5),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accentColor),
            )
          : _likedVideosWithDetails.isEmpty
              ? _buildEmptyState()
              : _buildLikedVideosGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No liked videos yet'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Videos you like will appear here.'.tr(),
            style: const TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLikedVideosGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16, // TikTok vertical video ratio
      ),
      itemCount: _likedVideosWithDetails.length,
      itemBuilder: (context, index) {
        final data = _likedVideosWithDetails[index];
        final video = data['video'] as Video;
        return _VideoThumbnail(
          video: video,
          onTap: () => _playVideo(video),
        );
      },
    );
  }

  void _playVideo(Video video) {
    context.push(
      '/video?path=${Uri.encodeComponent(video.filePath)}&name=${Uri.encodeComponent(video.name)}',
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final Video video;
  final VoidCallback onTap;

  const _VideoThumbnail({
    required this.video,
    required this.onTap,
  });

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
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
              color: const Color(0xFF161722),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFE2C55),
                ),
              ),
            )
          else if (_thumbnailPath != null)
            Image.file(
              File(_thumbnailPath!),
              fit: BoxFit.cover,
            )
          else
            Container(
              color: const Color(0xFF161722),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white.withOpacity(0.5),
                  size: 40,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            bottom: 4,
            child: Text(
              widget.video.name, // Usually dynamic content doesn't get .tr()
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Positioned(
            left: 4,
            top: 4,
            child: Icon(
              Icons.favorite,
              color: Color(0xFFFE2C55),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerPage extends StatefulWidget {
  final Video video;

  const _VideoPlayerPage({required this.video});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late final Player _player;
  late final mk.VideoController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  static const Color _accentColor = Color(0xFFFE2C55);

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = mk.VideoController(_player);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.video.filePath);
      if (await file.exists()) {
        await _player.open(Media(widget.video.filePath));
        await _player.play();
        setState(() {
          _isInitialized = true;
        });
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.video.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white38,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Video not available'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.video.name,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor),
      );
    }

    return Center(
      child: mk.Video(
        controller: _controller,
      ),
    );
  }
}
