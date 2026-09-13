import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatMediaService {
  ChatMediaService._();

  static final ImagePicker _picker = ImagePicker();

  // =====================================================
  // IMAGE PICKER (GALLERY)
  // =====================================================

  static Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
      );
    } catch (e) {
      debugPrint("Gallery Error: $e");
      return null;
    }
  }

  // =====================================================
  // IMAGE PICKER (CAMERA)
  // =====================================================

  static Future<XFile?> pickFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
      );
    } catch (e) {
      debugPrint("Camera Error: $e");
      return null;
    }
  }
   // =====================================================
  // IMAGE UPLOAD
  // =====================================================

  static Future<String?> uploadImage({
    required String chatId,
    required XFile image,
  }) async {
    try {
      // Read bytes
      final Uint8List bytes = await image.readAsBytes();

      // Detect extension
      final extension =
          image.name.split('.').last.toLowerCase();

      // Detect MIME type
      String contentType;

      switch (extension) {
        case 'png':
          contentType = 'image/png';
          break;

        case 'gif':
          contentType = 'image/gif';
          break;

        case 'bmp':
          contentType = 'image/bmp';
          break;

        case 'webp':
          contentType = 'image/webp';
          break;

        case 'jpeg':
        case 'jpg':
          contentType = 'image/jpeg';
          break;

        default:
          contentType = 'application/octet-stream';
      }

      // Keep original extension
      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}.$extension";

      final ref = FirebaseStorage.instance
          .ref()
          .child("chat_images")
          .child(chatId)
          .child(fileName);

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          cacheControl: "public,max-age=3600",
        ),
      );

      final url = await ref.getDownloadURL();

      debugPrint("IMAGE UPLOADED");
      debugPrint(url);

      return url;
    } catch (e, stack) {
      debugPrint("Upload Image Error: $e");
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  // =====================================================
  // GALLERY → UPLOAD
  // =====================================================

  static Future<String?> pickGalleryAndUpload(
    String chatId,
  ) async {
    final image = await pickFromGallery();

    if (image == null) {
      return null;
    }

    return await uploadImage(
      chatId: chatId,
      image: image,
    );
  }

  // =====================================================
  // CAMERA → UPLOAD
  // =====================================================

  static Future<String?> pickCameraAndUpload(
    String chatId,
  ) async {
    final image = await pickFromCamera();

    if (image == null) {
      return null;
    }

    return await uploadImage(
      chatId: chatId,
      image: image,
    );
  }
    // =====================================================
  // VIDEO PICKER (GALLERY)
  // =====================================================

  static Future<XFile?> pickVideoFromGallery() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.gallery,
      );
    } catch (e) {
      debugPrint("Gallery Video Error: $e");
      return null;
    }
  }

  // =====================================================
  // VIDEO PICKER (CAMERA)
  // =====================================================

  static Future<XFile?> recordVideo() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.camera,
      );
    } catch (e) {
      debugPrint("Camera Video Error: $e");
      return null;
    }
  }

  // =====================================================
  // VIDEO UPLOAD
  // =====================================================

  static Future<Map<String, String>?> uploadVideo({
    required String chatId,
    required XFile video,
  }) async {
    try {
      final Uint8List bytes = await video.readAsBytes();

      final extension =
          video.name.split('.').last.toLowerCase();

      String contentType;

      switch (extension) {
        case "webm":
          contentType = "video/webm";
          break;

        case "mov":
          contentType = "video/quicktime";
          break;

        case "avi":
          contentType = "video/x-msvideo";
          break;

        case "mkv":
          contentType = "video/x-matroska";
          break;

        case "3gp":
          contentType = "video/3gpp";
          break;

        case "mp4":
        default:
          contentType = "video/mp4";
      }

      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}.$extension";

      final ref = FirebaseStorage.instance
          .ref()
          .child("chat_videos")
          .child(chatId)
          .child(fileName);

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          cacheControl: "public,max-age=3600",
        ),
      );

      final videoUrl = await ref.getDownloadURL();

      debugPrint("VIDEO UPLOADED");
      debugPrint(videoUrl);

      // Flutter Web cannot generate thumbnails.
      // Use the video itself as the thumbnail.
      return {
        "videoUrl": videoUrl,
        "thumbnailUrl": videoUrl,
      };
    } catch (e, stack) {
      debugPrint("Video Upload Error: $e");
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }

  // =====================================================
  // PICK GALLERY VIDEO + UPLOAD
  // =====================================================

  static Future<Map<String, String>?>
      pickVideoGalleryAndUpload(
    String chatId,
  ) async {
    final video = await pickVideoFromGallery();

    if (video == null) {
      return null;
    }

    return await uploadVideo(
      chatId: chatId,
      video: video,
    );
  }

  // =====================================================
  // RECORD VIDEO + UPLOAD
  // =====================================================

  static Future<Map<String, String>?>
      recordVideoAndUpload(
    String chatId,
  ) async {
    final video = await recordVideo();

    if (video == null) {
      return null;
    }

    return await uploadVideo(
      chatId: chatId,
      video: video,
    );
  }
    // =====================================================
  // DELETE MEDIA
  // =====================================================

  static Future<void> deleteMedia(
    String url,
  ) async {
    try {
      await FirebaseStorage.instance
          .refFromURL(url)
          .delete();

      debugPrint("Media deleted.");
    } catch (e) {
      debugPrint("Delete Media Error: $e");
    }
  }

  // =====================================================
  // CHECK IMAGE TYPE
  // =====================================================

  static bool isImage(String path) {
    final ext =
        path.split('.').last.toLowerCase();

    return const [
      "jpg",
      "jpeg",
      "png",
      "gif",
      "bmp",
      "webp",
      "svg",
      "avif",
    ].contains(ext);
  }

  // =====================================================
  // CHECK VIDEO TYPE
  // =====================================================

  static bool isVideo(String path) {
    final ext =
        path.split('.').last.toLowerCase();

    return const [
      "mp4",
      "webm",
      "mov",
      "avi",
      "mkv",
      "3gp",
      "m4v",
    ].contains(ext);
  }

  // =====================================================
  // GET FILE EXTENSION
  // =====================================================

  static String getExtension(String filename) {
    if (!filename.contains(".")) {
      return "";
    }

    return filename
        .split(".")
        .last
        .toLowerCase();
  }

  // =====================================================
  // GET MIME TYPE
  // =====================================================

  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case "png":
        return "image/png";

      case "gif":
        return "image/gif";

      case "bmp":
        return "image/bmp";

      case "webp":
        return "image/webp";

      case "svg":
        return "image/svg+xml";

      case "avif":
        return "image/avif";

      case "jpg":
      case "jpeg":
        return "image/jpeg";

      case "mp4":
        return "video/mp4";

      case "webm":
        return "video/webm";

      case "mov":
        return "video/quicktime";

      case "avi":
        return "video/x-msvideo";

      case "mkv":
        return "video/x-matroska";

      case "3gp":
        return "video/3gpp";

      default:
        return "application/octet-stream";
    }
  }
}