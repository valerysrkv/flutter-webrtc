import 'package:flutter_webrtc/src/extension/extended_media_recorder.dart';
import '../flutter_webrtc.dart';

class MediaRecorder extends ExtendedMediaRecorder {
  MediaRecorder() : _delegate = mediaRecorder();
  final ExtendedMediaRecorder _delegate;

  @override
  Future<void> start(String path, {MediaStreamTrack? videoTrack, RecorderAudioChannel? audioChannel}) =>
      _delegate.start(path, videoTrack: videoTrack, audioChannel: audioChannel);

  @override
  Future stop() => _delegate.stop();

  @override
  void startWeb(
    MediaStream stream, {
    Function(dynamic blob, bool isLastOne)? onDataChunk,
    String? mimeType,
    int timeSlice = 1000,
  }) =>
      _delegate.startWeb(
        stream,
        onDataChunk: onDataChunk,
        mimeType: mimeType ?? 'video/webm',
        timeSlice: timeSlice,
      );

  @override
  Future<void> screenShot({required String path, required String fileName}) => _delegate.screenShot(path: path, fileName: fileName);
}
