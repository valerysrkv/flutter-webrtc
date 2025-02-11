//
//  PixelBufferRecorder.h
//  flutter_webrtc
//
//  Created by Valery Serykau on 3.02.25.
//

#import <Foundation/Foundation.h>
#import "FlutterRTCVideoRenderer.h"
#import "RecordingDelegate.h"


@interface PixelBufferRecorder : NSObject <RecordingDelegate>

- (void)handleBuffer:(CVPixelBufferRef _Nullable)buffer;

- (void)stopRecording:(nullable void (^)(NSString *_Nullable data))completionHandler;

- (void)startSession:(FlutterRTCVideoRenderer *_Nonnull)render andArg:(NSDictionary *_Nullable)args;

- (void)screenShot:(FlutterRTCVideoRenderer *_Nonnull)render andArg:(NSDictionary *_Nullable)args;

@end
