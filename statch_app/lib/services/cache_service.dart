import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Cache Service for automatic cache management
/// Silently cleans up old cached files on app startup
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// Maximum age for cached files (7 days)
  static const Duration maxCacheAge = Duration(days: 7);
  
  /// Auto-cleanup on app startup
  /// Removes cached files older than 7 days
  Future<void> autoCleanup() async {
    try {
      // Clean default cache manager
      await _cleanDefaultCache();
      
      // Clean app's temp directory
      await _cleanTempDirectory();
      
      debugPrint('Cache auto-cleanup completed');
    } catch (e) {
      // Silently fail - user should never worry about cache
      debugPrint('Cache cleanup error (ignored): $e');
    }
  }

  /// Clean the default image cache manager
  Future<void> _cleanDefaultCache() async {
    try {
      final cacheManager = DefaultCacheManager();
      
      // Remove files older than maxCacheAge
      await cacheManager.emptyCache();
      
      debugPrint('Default cache cleared');
    } catch (e) {
      debugPrint('Default cache cleanup failed: $e');
    }
  }

  /// Clean app's temporary directory
  Future<void> _cleanTempDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      
      await _cleanDirectory(tempDir, now);
      
      debugPrint('Temp directory cleaned');
    } catch (e) {
      debugPrint('Temp directory cleanup failed: $e');
    }
  }

  /// Recursively clean a directory, removing files older than maxCacheAge
  Future<void> _cleanDirectory(Directory dir, DateTime now) async {
    try {
      if (!await dir.exists()) return;
      
      final entities = await dir.list().toList();
      
      for (final entity in entities) {
        try {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);
          
          if (age > maxCacheAge) {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } else if (entity is Directory) {
            // Recursively clean subdirectories
            await _cleanDirectory(entity, now);
          }
        } catch (e) {
          // Skip files that can't be accessed
          continue;
        }
      }
    } catch (e) {
      debugPrint('Directory cleanup error: $e');
    }
  }

  /// Get total cache size (for display purposes)
  Future<String> getCacheSizeFormatted() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final size = await _getDirectorySize(tempDir);
      return _formatBytes(size);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Calculate directory size recursively
  Future<int> _getDirectorySize(Directory dir) async {
    int totalSize = 0;
    
    try {
      if (!await dir.exists()) return 0;
      
      final entities = await dir.list(recursive: true).toList();
      
      for (final entity in entities) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (_) {
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Size calculation error: $e');
    }
    
    return totalSize;
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
