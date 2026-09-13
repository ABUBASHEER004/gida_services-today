import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderPlatform {
  static final AudioRecorder _recorder = AudioRecorder();

  static String? _path;

  static Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        return false;
      }

      final dir = await getTemporaryDirectory();

      _path =
          "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _recorder.start(
        const RecordConfig(),
        path: _path!,
      );

      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  static Future<String?> stopAndUpload(
    String chatId,
  ) async {
    try {
      final path = await _recorder.stop();

      if (path == null) return null;

      final file = File(path);

      final ref = FirebaseStorage.instance
          .ref()
          .child("chat_audio")
          .child(chatId)
          .child(
            "${DateTime.now().millisecondsSinceEpoch}.m4a",
          );

      await ref.putFile(file);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}