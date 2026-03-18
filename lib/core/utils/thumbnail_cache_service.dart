import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ThumbnailCacheService
// Saves generated thumbnails to <appDocs>/thumbnails/<md5_of_path>.jpg
// and returns the cached file on subsequent requests — no re-generation needed.
// ─────────────────────────────────────────────────────────────────────────────

class ThumbnailCacheService {
  ThumbnailCacheService._();
  static final ThumbnailCacheService instance = ThumbnailCacheService._();

  Directory? _cacheDir;

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/thumbnails');
    if (!dir.existsSync()) await dir.create(recursive: true);
    _cacheDir = dir;
    return dir;
  }

  String _cacheKey(String videoPath) =>
      md5.convert(utf8.encode(videoPath)).toString();

  /// Returns a cached thumbnail path if it exists, otherwise generates,
  /// caches, and returns it. Returns null if generation fails.
  Future<String?> getThumbnail(String videoPath) async {
    final cacheDir = await _getCacheDir();
    final cachedFile = File('${cacheDir.path}/${_cacheKey(videoPath)}.jpg');

    // ── Cache hit — instant return ───────────────────────────────────────────
    if (cachedFile.existsSync()) {
      return cachedFile.path;
    }

    // ── Source file guard ───────────────────────────────────────────────────
    if (!File(videoPath).existsSync()) {
      debugPrint('[Thumbnail] Source not found: $videoPath');
      return null;
    }

    // ── Cache miss — generate then persist ───────────────────────────────────
    try {
      final tempDir = await getTemporaryDirectory();

      final String? generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 75,
      );

      if (generatedPath == null) return null;

      // Move from temp → persistent cache (survives app restarts)
      await File(generatedPath).copy(cachedFile.path);
      await File(generatedPath).delete();

      return cachedFile.path;
    } on MissingPluginException {
      debugPrint(
        '[Thumbnail] Plugin not registered. '
        'Run: flutter clean && flutter pub get, then reinstall.',
      );
      return null;
    } catch (e) {
      debugPrint('[Thumbnail] Generation error: $e');
      return null;
    }
  }

  /// Call this when a video is deleted so its stale thumbnail is cleaned up.
  Future<void> evict(String videoPath) async {
    final cacheDir = await _getCacheDir();
    final file = File('${cacheDir.path}/${_cacheKey(videoPath)}.jpg');
    if (file.existsSync()) await file.delete();
  }

  /// Wipes the entire thumbnail cache (e.g. from a settings screen).
  Future<void> clearAll() async {
    final cacheDir = await _getCacheDir();
    if (cacheDir.existsSync()) await cacheDir.delete(recursive: true);
    _cacheDir = null;
  }
}
