//
//  WritePixelBufferOperation.h
//  flutter_webrtc
//
//  Created by Valery Serykau on 7.02.25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>



@interface WritePixelBufferOperation : NSOperation

- (_Nonnull instancetype)initWith:(AVAssetWriterInputPixelBufferAdaptor *_Nonnull)pixelAdaptor andInput:(CVPixelBufferRef _Nonnull )buffer timeStamp:(CMTime)time;

@end
