//
//  WritePixelBufferOperation.m
//  flutter_webrtc
//
//  Created by Valery Serykau on 7.02.25.
//

#import <Foundation/Foundation.h>
#import "WritePixelBufferOperation.h"

@interface WritePixelBufferOperation() {
    AVAssetWriterInputPixelBufferAdaptor *pixelAdaptor;
    AVAssetWriterInput *input;
    CMTime timeStamp;
    CVPixelBufferRef pixelBuffer;
}

@end


@implementation WritePixelBufferOperation



bool isOperationReady;

- (_Nonnull instancetype)initWith:(AVAssetWriterInputPixelBufferAdaptor *_Nonnull)pixelAdaptor andInput:(AVAssetWriterInput *_Nullable)pixelInput timeStamp:(CMTime)time {
    self = [super init];

    if (self) {
        self->pixelAdaptor = pixelAdaptor;
        input = pixelInput;
        isOperationReady = false;
        timeStamp =time;
    }
   
    [input addObserver:self
            forKeyPath:@"isReadyForMoreMediaData"
               options:NSKeyValueObservingOptionNew
               context:nil];

    return self;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"isReadyForMoreMediaData"]) {
        if (!isOperationReady) {
            [self willChangeValueForKey:@"isReady"];
            isOperationReady =  change[@"new"];
            [self didChangeValueForKey:@"isReady"];
        }
   
    }

//    if (context == <#context#>) {
//
//    } else {
//        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//    }
}

- (BOOL)isReady {
    return isOperationReady;
}

- (void)main {
    
    if (input.isReadyForMoreMediaData) {
        [pixelAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:timeStamp];
    } else {
        NSLog(@"[!!! buffer can not be append] %lld", timeStamp.value);
    }
    
}

@end
