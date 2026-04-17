import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageHelper {
  // Compress image file (returns compressed bytes, not base64)
  static Future<Uint8List?> compressImage(String imagePath, {int quality = 70, int maxWidth = 1024}) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth > 0 ? (maxWidth * 0.75).toInt() : 768,
      );
      return result;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  // Create temporary compressed file for upload
  static Future<File?> compressImageFile(String imagePath, {int quality = 70, int maxWidth = 1024}) async {
    try {
      final bytes = await compressImage(imagePath, quality: quality, maxWidth: maxWidth);
      if (bytes == null) return null;
      
      final tempPath = '${imagePath}_compressed.jpg';
      final file = File(tempPath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Error creating compressed file: $e');
      return null;
    }
  }

  // Build optimized image widget with caching and shimmer
  static Widget buildOptimizedImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final shimmer = Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );

    final errorWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.local_offer, size: 40, color: Colors.white70),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget;
    }

    // Handle base64 images (legacy support)
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1));
        final image = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: width != null && width.isFinite && width > 0 ? width.toInt() : null,
          cacheHeight: height != null && height.isFinite && height > 0 ? height.toInt() : null,
          errorBuilder: (_, __, ___) => errorWidget,
        );
        
        if (borderRadius != null) {
          return ClipRRect(borderRadius: borderRadius, child: image);
        }
        return image;
      } catch (e) {
        return errorWidget;
      }
    }

    // Handle HTTP/HTTPS URLs with caching
    if (imageUrl.startsWith('http')) {
      final cachedImage = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width != null && width.isFinite && width > 0 ? width.toInt() : null,
        memCacheHeight: height != null && height.isFinite && height > 0 ? height.toInt() : null,
        maxWidthDiskCache: 1024,
        maxHeightDiskCache: 1024,
        placeholder: (_, __) => shimmer,
        errorWidget: (_, __, ___) => errorWidget,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
      
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius, child: cachedImage);
      }
      return cachedImage;
    }

    return errorWidget;
  }

  // Build thumbnail for lists (smaller, faster)
  static Widget buildThumbnail(
    String? imageUrl, {
    double size = 50,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return buildOptimizedImage(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }

  // Build hero image for detail screens
  static Widget buildHeroImage(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return buildOptimizedImage(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(16),
    );
  }

  // Build circular avatar
  static Widget buildAvatar(
    String? imageUrl, {
    double radius = 25,
    IconData fallbackIcon = Icons.person,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: Icon(fallbackIcon, size: radius, color: Colors.grey[600]),
      );
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1));
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey[300],
          child: Icon(fallbackIcon, size: radius, color: Colors.grey[600]),
        );
      }
    }

    if (imageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(
          imageUrl,
          maxWidth: radius.isFinite && radius > 0 ? (radius * 2).toInt() : 100,
          maxHeight: radius.isFinite && radius > 0 ? (radius * 2).toInt() : 100,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(fallbackIcon, size: radius, color: Colors.grey[600]),
    );
  }
}
