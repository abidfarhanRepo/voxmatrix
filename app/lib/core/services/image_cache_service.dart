import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for caching images to improve performance and reduce network usage
@singleton
class ImageCacheService {
  ImageCacheService(this._logger);

  final Logger _logger;
  final Map<String, Uint8List> _memoryCache = {};
  static const int _maxMemoryCacheSize = 50; // Maximum items in memory cache
  static const int _maxCacheAgeHours = 24; // Clear cache after 24 hours

  Directory? _cacheDir;
  Timer? _cleanupTimer;

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      final directory = await getTemporaryDirectory();
      _cacheDir = Directory('${directory.path}/image_cache');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Start periodic cleanup
      _cleanupTimer = Timer.periodic(const Duration(hours: 6), (_) {
        _cleanupOldCache();
      });

      _logger.i('Image cache service initialized');
    } catch (e) {
      _logger.e('Failed to initialize image cache', error: e);
    }
  }

  /// Get cached image or download if not available
  Future<Uint8List?> getImage(String url) async {
    if (_cacheDir == null) {
      await initialize();
    }

    final cacheKey = _getCacheKey(url);

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // Check disk cache
    final cachedFile = File('${_cacheDir!.path}/$cacheKey');
    if (await cachedFile.exists()) {
      try {
        final bytes = await cachedFile.readAsBytes();
        _addToMemoryCache(cacheKey, bytes);
        return bytes;
      } catch (e) {
        _logger.w('Error reading cached image', error: e);
      }
    }

    // Download and cache
    return await _downloadAndCache(url, cacheKey);
  }

  /// Download image and cache it
  Future<Uint8List?> _downloadAndCache(String url, String cacheKey) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Save to disk
        final cachedFile = File('${_cacheDir!.path}/$cacheKey');
        await cachedFile.writeAsBytes(bytes);
        
        // Add to memory cache
        _addToMemoryCache(cacheKey, bytes);
        
        return bytes;
      }
    } catch (e) {
      _logger.w('Error downloading image: $url', error: e);
    }

    return null;
  }

  /// Add image to memory cache with size limit
  void _addToMemoryCache(String key, Uint8List bytes) {
    // Remove oldest entries if cache is full
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final firstKey = _memoryCache.keys.first;
      _memoryCache.remove(firstKey);
    }

    _memoryCache[key] = bytes;
  }

  /// Generate cache key from URL
  String _getCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Clean up old cached files
  Future<void> _cleanupOldCache() async {
    if (_cacheDir == null) return;

    try {
      final files = await _cacheDir!.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          if (age.inHours > _maxCacheAgeHours) {
            await file.delete();
            _logger.d('Deleted old cached file: ${file.path}');
          }
        }
      }
    } catch (e) {
      _logger.e('Error cleaning up cache', error: e);
    }
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    _memoryCache.clear();

    if (_cacheDir != null && await _cacheDir!.exists()) {
      try {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create();
        _logger.i('Image cache cleared');
      } catch (e) {
        _logger.e('Error clearing cache', error: e);
      }
    }
  }

  /// Get current cache size in MB
  Future<double> getCacheSize() async {
    if (_cacheDir == null || !await _cacheDir!.exists()) {
      return 0.0;
    }

    try {
      final files = await _cacheDir!.list().toList();
      int totalBytes = 0;

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalBytes += stat.size;
        }
      }

      return totalBytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      _logger.e('Error calculating cache size', error: e);
      return 0.0;
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _memoryCache.clear();
    _logger.i('Image cache service disposed');
  }
}
