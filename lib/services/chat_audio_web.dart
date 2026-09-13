import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class AudioRecorderPlatform {
  AudioRecorderPlatform._();

  static html.MediaRecorder? _recorder;
  static html.MediaStream? _stream;

  static final List<html.Blob> _chunks = [];

  static bool _isRecording = false;

  //==================================================
  // START RECORDING
  //==================================================

  static Future<bool> startRecording() async {
    try {
      if (_isRecording) return true;

      _chunks.clear();

      _stream = await html.window.navigator.mediaDevices!
          .getUserMedia({
        "audio": true,
      });

      // Let the browser choose the supported codec.
      _recorder = html.MediaRecorder(_stream!);

      _recorder!.addEventListener(
        "dataavailable",
        (event) {
          final blobEvent = event as html.BlobEvent;

          if (blobEvent.data != null &&
              blobEvent.data!.size > 0) {
            _chunks.add(blobEvent.data!);

            debugPrint(
              "Audio chunk received (${blobEvent.data!.size} bytes)",
            );
          }
        },
      );

      _recorder!.start();

      _isRecording = true;

      debugPrint("Recording started");

      return true;
    } catch (e, stack) {
      debugPrint("Start Recording Error");
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stack);

      return false;
    }
  }

  //==================================================
  // STOP + UPLOAD
  //==================================================

  static Future<String?> stopAndUpload(
    String chatId,
  ) async {
    try {
      if (!_isRecording || _recorder == null) {
        debugPrint("Recorder not running.");
        return null;
      }

      final completer = Completer<String?>();

      late void Function(html.Event) stopListener;
      stopListener = (event) async {
        try {
          final blob = html.Blob(_chunks);

          if (blob.size == 0) {
            debugPrint("Recorded blob is empty.");
            completer.complete(null);
            return;
          }

          final reader = html.FileReader();

          reader.readAsArrayBuffer(blob);

          await reader.onLoad.first;

          final bytes = Uint8List.view(
            reader.result as ByteBuffer,
          );

          debugPrint(
            "Audio bytes: ${bytes.length}",
          );

          final ref = FirebaseStorage.instance
              .ref()
              .child("chat_audio")
              .child(chatId)
              .child(
                "${DateTime.now().millisecondsSinceEpoch}.webm",
              );

          await ref.putData(
            bytes,
            SettableMetadata(
              contentType: "audio/webm",
              cacheControl: "public,max-age=3600",
            ),
          );

          final url = await ref.getDownloadURL();

          debugPrint("Audio uploaded:");
          debugPrint(url);

          completer.complete(url);
        } catch (e, stack) {
          debugPrint("Upload Error");
          debugPrint(e.toString());
          debugPrintStack(stackTrace: stack);

          completer.complete(null);
        } finally {
          _chunks.clear();

          _isRecording = false;

          if (_stream != null) {
            for (final track in _stream!.getTracks()) {
              track.stop();
            }
          }

          _stream = null;

          _recorder?.removeEventListener(
            "stop",
            stopListener,
          );

          _recorder = null;
        }
      };

      _recorder!.addEventListener(
        "stop",
        stopListener,
      );

      _recorder!.stop();

      return completer.future;
    } catch (e, stack) {
      debugPrint("Stop Upload Error");
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stack);

      return null;
    }
  }
}