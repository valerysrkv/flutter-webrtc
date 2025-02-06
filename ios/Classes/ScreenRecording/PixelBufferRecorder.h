//
//  PixelBufferRecorder.h
//  flutter_webrtc
//
//  Created by Valery Serykau on 3.02.25.
//

#import <Foundation/Foundation.h>
#import "RecordingDelegate.h"
#import "FlutterRTCVideoRenderer.h"
 

@interface PixelBufferRecorder : NSObject <RecordingDelegate>

- (void) handleBuffer:(CVPixelBufferRef _Nullable )buffer;

- (void) stopRecording:(nullable void(^)(NSString* _Nullable data)) completionHandler;

- (void) startSession: (FlutterRTCVideoRenderer *_Nonnull) render;

@end

