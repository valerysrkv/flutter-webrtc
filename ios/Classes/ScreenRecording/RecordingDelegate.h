//
//  RecordingDelegate.h
//  flutter_webrtc
//
//  Created by Valery Serykau on 5.02.25.
//

@protocol RecordingDelegate <NSObject>   //define delegate protocol
   - (void) handleBuffer:(CVPixelBufferRef _Nullable )buffer;
@end
