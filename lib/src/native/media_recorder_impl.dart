import 'dart:async';
import 'dart:math';

import 'package:flutter_webrtc/src/extension/extended_media_recorder.dart';
import 'package:flutter_webrtc/src/native/ios/stream_configuration.dart';
import 'package:webrtc_interface/webrtc_interface.dart';

import 'media_stream_track_impl.dart';
import 'utils.dart';

class MediaRecorderNative extends ExtendedMediaRecorder {
  static final _random = Random();
  final _recorderId = _random.nextInt(0x7FFFFFFF);

  @override
  Future<void> start(
    String path, {
    MediaStreamTrack? videoTrack,
    RecorderAudioChannel? audioChannel,
    // TODO(cloudwebrtc): add codec/quality options
    StreamConfiguration? config,
  }) async {
    if (audioChannel == null && videoTrack == null) {
      throw Exception('Neither audio nor video track were provided');
    }

    await WebRTC.invokeMethod('startRecordToFile', {
      'path': path,
      if (audioChannel != null) 'audioChannel': audioChannel.index,
      if (videoTrack != null) 'videoTrackId': videoTrack.id,
      'recorderId': _recorderId,
      'peerConnectionId': videoTrack is MediaStreamTrackNative ? videoTrack.peerConnectionId : null
    });
  }

  @override
  void startWeb(MediaStream stream, {Function(dynamic blob, bool isLastOne)? onDataChunk, String? mimeType, int timeSlice = 1000}) {
    throw 'It\'s for Flutter Web only';
  }

  @override
  Future<dynamic> stop() async => await WebRTC.invokeMethod('stopRecordToFile', {'recorderId': _recorderId});

  @override
  Future<void> screenShot({required String path, required String fileName}) async {
    await WebRTC.invokeMethod('screenShot', {
      'path': path,
      'fileName': fileName,
      'recorderId': _recorderId,
    });
  }
}
