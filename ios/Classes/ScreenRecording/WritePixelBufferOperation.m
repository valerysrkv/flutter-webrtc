//
//  WritePixelBufferOperation.m
//  flutter_webrtc
//
//  Created by Valery Serykau on 7.02.25.
//

#import <Foundation/Foundation.h>
#import "WritePixelBufferOperation.h"

@interface WritePixelBufferOperation () {
    AVAssetWriterInputPixelBufferAdaptor *pixelAdaptor;
    CMTime timeStamp;
    CVPixelBufferRef pixelBuffer;
}

@end


@implementation WritePixelBufferOperation



- (_Nonnull instancetype)initWith:(AVAssetWriterInputPixelBufferAdaptor *_Nonnull)pixelAdaptor andInput:(CVPixelBufferRef _Nonnull)buffer timeStamp:(CMTime)time {
    self = [super init];

    if (self) {
        self->pixelAdaptor = pixelAdaptor;
        pixelBuffer = buffer;
        timeStamp = time;
    }

    return self;
}

- (BOOL)isReady {
    NSLog(@"WritePixelBufferOperation: Is trying to run Asset Write with time stamp %lld withValue %d", timeStamp.value, pixelAdaptor.assetWriterInput.isReadyForMoreMediaData);
    return pixelAdaptor.assetWriterInput.isReadyForMoreMediaData;
}

- (void)main {
    if (pixelAdaptor.assetWriterInput.isReadyForMoreMediaData) {
        @try {
            NSLog(@"WritePixelBufferOperation: pixelAdaptor will appendPixelBuffer:pixelBuffer %lld", timeStamp.value);
            [pixelAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:timeStamp];
            NSLog(@"WritePixelBufferOperation: pixelAdaptor appended PixelBuffer:pixelBuffer %lld", timeStamp.value);
        } @catch (NSException *exception) {
            NSLog(@"WritePixelBufferOperation: Is failed pixelBuffer %lld error: \n %@", timeStamp.value, exception);
        } @finally {
        }
    } else {
        NSLog(@"WritePixelBufferOperation: assetWriterInput.isReadyForMoreMediaData in Not ready %lld", timeStamp.value);
    }
}

@end
