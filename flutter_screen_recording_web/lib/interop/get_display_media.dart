import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Wrapper class for web MediaStream
class MediaStream {
  MediaStream(this._stream);
  final web.MediaStream _stream;

  web.MediaStream get stream => _stream;
}

/// Navigator helper for media APIs
class navigator {
  static Future<MediaStream> getUserMedia(
      Map<String, dynamic> mediaConstraints) async {
    try {
      if (mediaConstraints['video'] is Map) {
        if (mediaConstraints['video']['facingMode'] != null) {
          mediaConstraints['video'].remove('facingMode');
        }
      }

      final constraints = web.MediaStreamConstraints(
        audio: (mediaConstraints['audio'] ?? false).jsify(),
        video: (mediaConstraints['video'] ?? false).jsify(),
      );

      final stream =
          await web.window.navigator.mediaDevices.getUserMedia(constraints).toDart;
      return MediaStream(stream);
    } catch (e) {
      throw 'Unable to getUserMedia: ${e.toString()}';
    }
  }

  static Future<MediaStream> getDisplayMedia(
      Map<String, dynamic> mediaConstraints) async {
    try {
      final constraints = web.DisplayMediaStreamOptions(
        video: (mediaConstraints['video'] ?? true).jsify(),
        audio: (mediaConstraints['audio'] ?? false).jsify(),
      );

      final stream =
          await web.window.navigator.mediaDevices.getDisplayMedia(constraints).toDart;
      return MediaStream(stream);
    } catch (e) {
      throw 'Unable to getDisplayMedia: ${e.toString()}';
    }
  }

  static Future<List<dynamic>> getSources() async {
    final devices =
        await web.window.navigator.mediaDevices.enumerateDevices().toDart;
    final result = <Map<String, String>>[];
    for (final device in devices.toDart) {
      result.add(<String, String>{
        'deviceId': device.deviceId,
        'groupId': device.groupId,
        'kind': device.kind,
        'label': device.label,
      });
    }
    return result;
  }
}
