library flutter_screen_recording_web;

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'interop/get_display_media.dart';

import 'package:flutter_screen_recording_platform_interface/flutter_screen_recording_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class WebFlutterScreenRecording extends FlutterScreenRecordingPlatform {
  MediaStream? stream;
  String? name;
  web.MediaRecorder? mediaRecorder;
  web.Blob? recordedChunks;
  String? mimeType;

  static registerWith(Registrar registrar) {
    FlutterScreenRecordingPlatform.instance = WebFlutterScreenRecording();
  }

  @override
  Future<bool> startRecordScreen(
    String name, {
    String notificationTitle = "",
    String notificationMessage = "",
  }) async {
    return _record(name, true, false);
  }

  @override
  Future<bool> startRecordScreenAndAudio(
    String name, {
    String notificationTitle = "",
    String notificationMessage = "",
  }) async {
    return _record(name, true, true);
  }

  Future<bool> _record(String name, bool recordVideo, bool recordAudio) async {
    try {
      MediaStream? audioStream;

      if (recordAudio) {
        audioStream = await navigator.getUserMedia({"audio": true});
      }

      var options = {
        "video": {
          "displaySurface": 'browser',
        },
        "audio": {
          "suppressLocalAudioPlayback": false,
        },
        "preferCurrentTab": true,
        "selfBrowserSurface": 'include',
        "systemAudio": 'include',
        "surfaceSwitching": 'include',
        "monitorTypeSurfaces": 'include',
      };
      stream = await navigator.getDisplayMedia(options);
      this.name = name;
      if (recordAudio && audioStream != null) {
        stream!.stream.addTrack(audioStream.stream.getAudioTracks().toDart[0]);
      }

      if (_isTypeSupported('video/webm;codecs=vp9')) {
        mimeType = 'video/webm;codecs=vp9,opus';
      } else if (_isTypeSupported('video/webm;codecs=vp8.0')) {
        mimeType = 'video/webm;codecs=vp8.0,opus';
      } else if (_isTypeSupported('video/webm;codecs=vp8')) {
        mimeType = 'video/webm;codecs=vp8,opus';
      } else if (_isTypeSupported('video/mp4;codecs=h265')) {
        mimeType = 'video/mp4;codecs=h265,opus';
      } else if (_isTypeSupported('video/mp4;codecs=h264')) {
        mimeType = 'video/mp4;codecs=h264,opus';
      } else if (_isTypeSupported('video/webm;codecs=h265')) {
        mimeType = 'video/webm;codecs=h265,opus';
      } else if (_isTypeSupported('video/webm;codecs=h264')) {
        mimeType = 'video/webm;codecs=h264,opus';
      } else {
        mimeType = 'video/webm';
      }

      final options2 = web.MediaRecorderOptions(mimeType: mimeType!);
      mediaRecorder = web.MediaRecorder(stream!.stream, options2);

      mediaRecorder!.ondataavailable = ((web.BlobEvent event) {
        recordedChunks = event.data;
      }).toJS;

      stream!.stream.getVideoTracks().toDart[0].onended = ((web.Event event) {
        // If user stops sharing screen, stop record
        stopRecordScreen;
      }).toJS;

      mediaRecorder!.start();

      return true;
    } catch (e) {
      print("--->" + e.toString());
      return false;
    }
  }

  bool _isTypeSupported(String type) {
    return web.MediaRecorder.isTypeSupported(type);
  }

  @override
  Future<String> get stopRecordScreen {
    final c = Completer<String>();

    mediaRecorder!.onstop = ((web.Event event) {
      mediaRecorder = null;
      final tracks = stream!.stream.getTracks().toDart;
      for (final track in tracks) {
        track.stop();
      }
      stream = null;

      final a = web.document.createElement("a") as web.HTMLAnchorElement;
      final blobParts = <web.Blob>[recordedChunks!].jsify();
      final blobOptions = web.BlobPropertyBag(type: mimeType!);
      final blob = web.Blob(blobParts as JSArray<JSAny>, blobOptions);
      final url = web.URL.createObjectURL(blob);

      web.document.body!.append(a);
      a.style.display = "none";
      a.href = url;
      a.download = name ?? 'recording';
      a.click();
      web.URL.revokeObjectURL(url);

      c.complete(name);
    }).toJS;

    mediaRecorder!.stop();
    return c.future;
  }
}
