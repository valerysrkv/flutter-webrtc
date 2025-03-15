import 'package:webrtc_interface/webrtc_interface.dart';

abstract class ExtendedMediaRecorder extends MediaRecorder {
  Future<void> screenShot({required String path, required String fileName});
}
