//
//  PixelBufferRecorder.m
//  flutter_webrtc
//
//  Created by Valery Serykau on 3.02.25.
//

#import "PixelBufferRecorder.h"
#import <Foundation/Foundation.h>
#import "AVFoundation/AVFoundation.h"
#import "AVKit/AVKit.h"
#import "Photos/Photos.h"

@implementation PixelBufferRecorder


bool isRecordingVideo = false;
AVAssetWriterInput * videoWriterInput;
NSString* videoOutputFullFileName;
AVAssetWriterInput* audioWriterInput;
AVAssetWriter* videoWriter;
CMTime lastSampleTime;
AVAssetWriterInputPixelBufferAdaptor* adaptor;
CMTime frameRate;


- (void) handleBuffer:(CVPixelBufferRef)buffer {
 
    NSLog(@"Saver: will appendPixelBuffer for time %lld", lastSampleTime.value);
    if (videoWriterInput.isReadyForMoreMediaData) {
        [adaptor appendPixelBuffer:buffer withPresentationTime: lastSampleTime];
        NSLog(@"Saver: appended PixelBuffer atTime %lld", lastSampleTime.value);
    }
    
    
    lastSampleTime = CMTimeAdd(lastSampleTime, frameRate);
    
 
    
    
}

- (void) startSession: (FlutterRTCVideoRenderer *) render  {
    frameRate = CMTimeMake(1, 30);
    lastSampleTime= CMTimeMake(0, 30);
  
    
    NSDictionary *pixelBufferAttributes = @{
    (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{},
    (__bridge NSString *)kCVPixelBufferMetalCompatibilityKey: @NO,
    (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @((int)kCVPixelFormatType_32ARGB),
    (__bridge NSString *)kCVPixelBufferWidthKey: @((int)640),
    (__bridge NSString *)kCVPixelBufferHeightKey: @((int)480),
    };
    
    NSFileManager* fileManeger = [NSFileManager defaultManager];
    NSArray *paths = [fileManeger URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];
    documentsURL = [documentsURL URLByAppendingPathComponent:@"test_capture_video.mp4"];
    
    videoOutputFullFileName = documentsURL.path;
   
    
    isRecordingVideo = true;
    
    if ([fileManeger fileExistsAtPath: videoOutputFullFileName]) {
        
        NSLog(@"WARN:::The file: \(self.videoOutputFullFileName!) exists, will delete the existing file");
        
        @try {
            
            [fileManeger removeItemAtPath:videoOutputFullFileName error:NULL];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }

    }
    
    
    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
    
    videoSettings[AVVideoCodecKey] = AVVideoCodecTypeHEVC;
    videoSettings[AVVideoWidthKey] = [NSNumber numberWithInt:640];
    videoSettings[AVVideoHeightKey] = [NSNumber numberWithInt:360];
   
     
    
    videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType: AVMediaTypeVideo outputSettings:videoSettings];
    
    adaptor =  [AVAssetWriterInputPixelBufferAdaptor  assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:pixelBufferAttributes];
    
   
    NSError *error = NULL;
    
    videoWriter = [[AVAssetWriter alloc] initWithURL:documentsURL fileType:AVFileTypeQuickTimeMovie error:&error];
    
    
    NSLog(@"WebRTC: videoWriter error %@", error.description);
    [videoWriter addInput:videoWriterInput];
   
    if (videoWriter.status != AVAssetWriterStatusWriting) {
    
       
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
       
    }
    
    render.delegate = self;
 
    
    
}
 

- (void) createOutput: (CMSampleBufferRef) sampleBuffer {
    NSFileManager* fileManeger = [NSFileManager defaultManager];
    NSArray *paths = [fileManeger URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];
    documentsURL = [documentsURL URLByAppendingPathComponent:@"test_capture_video.mp4"];
    
    videoOutputFullFileName = documentsURL.path;
   
    
    isRecordingVideo = true;
    
    if ([fileManeger fileExistsAtPath: videoOutputFullFileName]) {
        
        NSLog(@"WARN:::The file: \(self.videoOutputFullFileName!) exists, will delete the existing file");
        
        @try {
            
            [fileManeger removeItemAtPath:videoOutputFullFileName error:NULL];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
        }

    }
    
    
    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
    
    videoSettings[AVVideoCodecKey] = AVVideoCodecTypeH264;
    videoSettings[AVVideoWidthKey] = [NSNumber numberWithInt:640];
    videoSettings[AVVideoHeightKey] = [NSNumber numberWithInt:480];
   
     
    
    videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType: AVMediaTypeVideo outputSettings:videoSettings];
    
   

    NSError *error = NULL;
    
    videoWriter = [[AVAssetWriter alloc] initWithURL:documentsURL fileType:AVFileTypeMPEG4 error:&error];
    
    
    NSLog(@"WebRTC: videoWriter error %@", error.description);
    [videoWriter addInput:videoWriterInput];
    
    
    if (videoWriter.status != AVAssetWriterStatusWriting) {
    
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
        [videoWriterInput appendSampleBuffer:sampleBuffer];
    }
    
    
}

-(void)stopRecording:(nullable void(^)(NSString* data)) completionHandler {
    if (!isRecordingVideo) {
        return;
    }
    
    isRecordingVideo = false;
    
 
    if (videoWriter.status != AVAssetWriterStatusWriting) {
        return;
    }
    
    [videoWriter endSessionAtSourceTime: lastSampleTime];
    [videoWriter finishWritingWithCompletionHandler:^{
        NSFileManager* fileManeger = [NSFileManager defaultManager];
        
        
        
        if ([fileManeger fileExistsAtPath: videoOutputFullFileName]) {
            NSString * bundleId= [[NSBundle mainBundle].bundleIdentifier lowercaseString];
            
            NSURL *shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier: bundleId ]  ;
            
           
            
 
            if (shareUrl == nil) {
                shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:@"com.sc.command"];
            }
            
            if (shareUrl == nil) {
                shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:@"org.cocoapods.flutter-webrtc"];
            }
            
            if (shareUrl != nil) {
                shareUrl = [shareUrl URLByAppendingPathComponent:@"test_capture_video.mp4"];
                
                if ([fileManeger fileExistsAtPath: shareUrl.path]) {
                    
                    NSLog(@"WARN:::The file: \(self.videoOutputFullFileName!) exists, will delete the existing file");
                    
                    @try {
                        
                        [fileManeger removeItemAtPath:shareUrl.path error:NULL];
                        
                    
                    }
                    @catch (NSException * e) {
                        NSLog(@"Exception: %@", e);
                    }

                }
                
                NSError *copyError;
                
                [fileManeger copyItemAtURL:[NSURL fileURLWithPath: videoOutputFullFileName] toURL:shareUrl error:&copyError];
                
                
            }
            
          
            
          
            
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
               
                
                PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath: shareUrl == nil ?   videoOutputFullFileName : shareUrl.path]];
                 
        

            } completionHandler:^(BOOL success, NSError *error) {
                if (success)
                {

                    NSLog(@" success iOS 9");
                }
                else
                {
                
                    completionHandler(videoOutputFullFileName);
//                    return ;
//
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        UIViewController *rootViewController = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
//
//                        AVPlayerViewController * playerController = [[AVPlayerViewController alloc] init];
//
//                        playerController.player = [[AVPlayer alloc]initWithURL: [NSURL fileURLWithPath:videoOutputFullFileName ] ];
//
//
//                        [rootViewController presentViewController:playerController animated:YES completion:nil];
//
//                        [playerController.player play];
//                    });
//                    NSLog(@"%@", error);
//                    NSMutableArray* myArray = [[NSMutableArray alloc] init];
//
//                    [myArray addObject:NSURLLocalizedTypeDescriptionKey];
//                    [myArray addObject:NSURLFileSizeKey];
//                    NSLog(@"WebRTC:videoOutputFullFileName %@", videoOutputFullFileName);
//                    NSLog(@"WebRTC: %@", [[NSURL fileURLWithPath:videoOutputFullFileName] resourceValuesForKeys:myArray error:nil]);
                    
                }
            }];
        }
        
    
   
        
    }];
    
    
    
    
}

@end
