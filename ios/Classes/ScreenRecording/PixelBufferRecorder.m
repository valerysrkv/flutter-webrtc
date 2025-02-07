//
//  PixelBufferRecorder.m
//  flutter_webrtc
//
//  Created by Valery Serykau on 3.02.25.
//


#import "Photos/Photos.h"
#import "PixelBufferRecorder.h"
#import "WritePixelBufferOperation.h"




@implementation PixelBufferRecorder
bool isRecordingVideo = false;
AVAssetWriterInput *videoWriterInput;
NSString *videoOutputFullFileName;
AVAssetWriterInput *audioWriterInput;
AVAssetWriter *videoWriter;
CMTime lastSampleTime;
AVAssetWriterInputPixelBufferAdaptor *adaptor;
CMTime frameRate;
NSOperationQueue *queue;


- (void)handleBuffer:(CVPixelBufferRef)buffer {
//    WritePixelBufferOperation *appendOperation = [[WritePixelBufferOperation alloc] initWith: adaptor andInput:videoWriterInput timeStamp:lastSampleTime];
//
//    [queue addOperation:appendOperation];

    NSLog(@"Saver: will appendPixelBuffer for time %lld", lastSampleTime.value);

//    if (videoWriterInput.isReadyForMoreMediaData) {
//        [adaptor appendPixelBuffer:buffer withPresentationTime:lastSampleTime];
//        NSLog(@"Saver: appended PixelBuffer atTime %lld", lastSampleTime.value);
//    }

    lastSampleTime = CMTimeAdd(lastSampleTime, frameRate);
}

- (void)startSession:(FlutterRTCVideoRenderer *)render  {
    queue = [NSOperationQueue new];



    frameRate = CMTimeMake(1, 30);
    lastSampleTime = CMTimeMake(0, 30);


    NSDictionary *pixelBufferAttributes = @{
            (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{},
            (__bridge NSString *)kCVPixelBufferMetalCompatibilityKey: @NO,
            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @((int)kCVPixelFormatType_32ARGB),
            (__bridge NSString *)kCVPixelBufferWidthKey: @((int)640),
            (__bridge NSString *)kCVPixelBufferHeightKey: @((int)480),
    };

    NSFileManager *fileManeger = [NSFileManager defaultManager];
    NSArray *paths = [fileManeger URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];
    documentsURL = [documentsURL URLByAppendingPathComponent:@"test_capture_video.mp4"];

    videoOutputFullFileName = documentsURL.path;


    isRecordingVideo = true;

    if ([fileManeger fileExistsAtPath:videoOutputFullFileName]) {
        NSLog(@"WARN:::The file: \(self.videoOutputFullFileName!) exists, will delete the existing file");

        @try {
            [fileManeger removeItemAtPath:videoOutputFullFileName error:NULL];
        } @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
        }
    }

    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];

    videoSettings[AVVideoCodecKey] = AVVideoCodecTypeHEVC;
    videoSettings[AVVideoWidthKey] = [NSNumber numberWithInt:640];
    videoSettings[AVVideoHeightKey] = [NSNumber numberWithInt:360];



    videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];

    adaptor =  [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:pixelBufferAttributes];


    NSError *error = NULL;

    videoWriter = [[AVAssetWriter alloc] initWithURL:documentsURL fileType:AVFileTypeQuickTimeMovie error:&error];


    NSLog(@"WebRTC: videoWriter error %@", error.description);
    [videoWriter addInput:videoWriterInput];

    if (videoWriter.status != AVAssetWriterStatusWriting) {
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
    }

    [videoWriterInput addObserver:self forKeyPath:@"isReadyForMoreMediaData" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionNew context:nil];

    render.delegate = self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
}

- (void)createOutput:(CMSampleBufferRef)sampleBuffer {
    NSFileManager *fileManeger = [NSFileManager defaultManager];
    NSArray *paths = [fileManeger URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];

    documentsURL = [documentsURL URLByAppendingPathComponent:@"test_capture_video.mp4"];

    videoOutputFullFileName = documentsURL.path;


    isRecordingVideo = true;

    if ([fileManeger fileExistsAtPath:videoOutputFullFileName]) {
        NSLog(@"WARN:::The file: \(self.videoOutputFullFileName!) exists, will delete the existing file");

        @try {
            [fileManeger removeItemAtPath:videoOutputFullFileName error:NULL];
        } @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
        }
    }

    NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];

    videoSettings[AVVideoCodecKey] = AVVideoCodecTypeH264;
    videoSettings[AVVideoWidthKey] = [NSNumber numberWithInt:640];
    videoSettings[AVVideoHeightKey] = [NSNumber numberWithInt:480];



    videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];



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

- (void)stopRecording:(nullable void (^)(NSString *data))completionHandler {
    if (!isRecordingVideo) {
        return;
    }

    isRecordingVideo = false;

    if (videoWriter.status != AVAssetWriterStatusWriting) {
        return;
    }
    
    [queue waitUntilAllOperationsAreFinished];

    [videoWriter endSessionAtSourceTime:lastSampleTime];
    [videoWriter finishWritingWithCompletionHandler:^{
        NSFileManager *fileManeger = [NSFileManager defaultManager];

        if ([fileManeger fileExistsAtPath:videoOutputFullFileName]) {
            NSString *bundleId = [[NSBundle mainBundle].bundleIdentifier lowercaseString];

            NSURL *shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:bundleId ];

            if (shareUrl == nil) {
                shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:@"com.sc.command"];
            }

            if (shareUrl == nil) {
                shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:@"org.cocoapods.flutter-webrtc"];
            }

            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:shareUrl == nil ?
                                                                                 videoOutputFullFileName : shareUrl.path]];
            }
                                              completionHandler:^(BOOL success, NSError *error) {
                if (success) {
                    NSLog(@" success iOS 9");
                } else {
                    completionHandler(videoOutputFullFileName);
                    
                }
            }];
        }
    }];
}



- (void)playRecordedClip:(NSString *)path {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *rootViewController = (UIViewController *)[[[UIApplication sharedApplication] windows].firstObject rootViewController];

        AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];

        playerController.player = [[AVPlayer alloc]initWithURL:[NSURL fileURLWithPath:path]];


        [rootViewController presentViewController:playerController animated:YES completion:nil];

        [playerController.player play];
    });

    NSError *error;

    NSLog(@"%@", error);
    NSMutableArray *myArray = [[NSMutableArray alloc] init];

    [myArray addObject:NSURLLocalizedTypeDescriptionKey];
    [myArray addObject:NSURLFileSizeKey];
    NSLog(@"WebRTC:videoOutputFullFileName %@", videoOutputFullFileName);
    NSLog(@"WebRTC: %@", [[NSURL fileURLWithPath:videoOutputFullFileName] resourceValuesForKeys:myArray error:nil]);
}

@end
