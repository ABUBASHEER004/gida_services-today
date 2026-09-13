import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
        maxHeight: 1600,
      );
    } catch (e) {
      debugPrint('Gallery error: $e');
      return null;
    }
  }

  static Future<XFile?> pickFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 1600,
        maxHeight: 1600,
      );
    } catch (e) {
      debugPrint('Camera error: $e');
      return null;
    }
  }

  static Future<String?> uploadProfileImage({
    required String uid,
    required XFile image,
  }) async {
    try {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(uid)
          .child('profile.jpg');

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=3600',
        ),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Profile upload error: $e');
      return null;
    }
  }

  static Future<String?> updateProfileImage({
    required String uid,
    required XFile image,
  }) async {
    return uploadProfileImage(uid: uid, image: image);
  }

}
