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
dispatch_queue_t serialQueue;



- (void)handleBuffer:(CVPixelBufferRef)buffer {
    NSLog(@"PixelBufferRecorder: will appendPixelBuffer for time %lld", lastSampleTime.value);

    WritePixelBufferOperation *appendOperation = [[WritePixelBufferOperation alloc] initWith:adaptor andInput:buffer timeStamp:lastSampleTime];
    [queue addOperation:appendOperation];
//
//    if (videoWriterInput.isReadyForMoreMediaData) {
//        [adaptor appendPixelBuffer:buffer withPresentationTime:lastSampleTime];
//        NSLog(@"PixelBufferRecorder: appended PixelBuffer atTime %lld", lastSampleTime.value);
//    }

    lastSampleTime = CMTimeAdd(lastSampleTime, frameRate);
}

-(void)screenShot:(FlutterRTCVideoRenderer *)render andArg:(NSDictionary *)args  {
    serialQueue = dispatch_queue_create("com.example.mySerialQueue", DISPATCH_QUEUE_SERIAL);
    
    // Get the Documents directory path
    NSString *directoryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/live_view"];
    NSString *filePath = [directoryPath stringByAppendingPathComponent:@"output.jpg"];
    
    NSDictionary *pixelBufferAttributes = @{
            (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{},
            (__bridge NSString *)kCVPixelBufferMetalCompatibilityKey: @NO,
            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @((int)CVPixelBufferGetPixelFormatType(render.copyPixelBuffer)),
            (__bridge NSString *)kCVPixelBufferWidthKey:  @((int)640),
            (__bridge NSString *)kCVPixelBufferHeightKey: @((int)480),
    };

    NSDictionary *videoSettings = @{
//            AVVideoCodecKey: AVVideoCodecTypeH264,
            AVVideoWidthKey:  [NSNumber numberWithInt:((int)640)],
            AVVideoHeightKey: [NSNumber numberWithInt:((int)480)]
    };
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        NSLog(@"PixelBufferRecorder: WARN:::The file: \(self.videoOutputFullFileName!) exists, will delete the existing file");

        @try {
            [fileManager removeItemAtPath:filePath error:NULL];
        } @catch (NSException *e) {
            NSLog(@"PixelBufferRecorder: Exception: %@ line:%d", e, __LINE__);
        }
    }
    
    videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];

    adaptor =  [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:pixelBufferAttributes];
    
    NSError *error = NULL;
    
    NSURL *fileURl = [NSURL fileURLWithPath:filePath];

    videoWriter = [[AVAssetWriter alloc] initWithURL: fileURl fileType:AVFileTypeJPEG error:&error];


    NSLog(@"PixelBufferRecorder: videoWriter error %@", error.description);
    [videoWriter addInput:videoWriterInput];

    if (videoWriter.status != AVAssetWriterStatusWriting) {
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
    }
    
    [videoWriterInput requestMediaDataWhenReadyOnQueue:serialQueue usingBlock:^{
        [adaptor appendPixelBuffer:render.copyPixelBuffer withPresentationTime:kCMTimeZero];
        [videoWriter endSessionAtSourceTime:kCMTimeZero];
        [videoWriter finishWritingWithCompletionHandler:^{
            NSFileManager *fileManeger = [NSFileManager defaultManager];

            if ([fileManeger fileExistsAtPath:filePath]) {
                NSString *bundleId = [[NSBundle mainBundle].bundleIdentifier lowercaseString];

                NSURL *shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:bundleId ];

                if (shareUrl == NULL) {
                    shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:@"com.sc.command"];
                }

                if (shareUrl == NULL) {
                    shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:@"org.cocoapods.flutter-webrtc"];
                }

                NSLog(@"PixelBufferRecorder: videoWriter createdOperationForLibrary %@", filePath);

                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:shareUrl == nil ?
                                                                                                 filePath : shareUrl.path]];
                }
                                                  completionHandler:^(BOOL success, NSError *error) {
                    if (success) {
                        NSLog(@"PixelBufferRecorder: success iOS 9");
                    } else {
                        NSLog(@"PixelBufferRecorder: videoWriter failed to save %@", error);
    //                    completionHandler(filePath);
                    }
                }];
            }
        }];
    }];

    

     
//     // Convert CVPixelBufferRef to CIImage
//     CIImage *ciImage = [CIImage imageWithCVPixelBuffer:render.copyPixelBuffer];
//
//     // Convert CIImage to UIImage
//     CIContext *context = [CIContext contextWithOptions:nil];
//     CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
//
//     UIImage *image = [UIImage imageWithCGImage:cgImage];
//
//     // Release CGImageRef to avoid memory leak
//     CGImageRelease(cgImage);
//

     
     // Convert UIImage to PNG data
//     NSData *imageData = UIImageJPEGRepresentation(image, 1);
//
//     // Save image to file
//     BOOL success = [imageData writeToFile:filePath atomically:YES];
//
//     if (success) {
//         NSLog(@"✅ Image saved successfully at %@", filePath);
//     } else {
//         NSLog(@"❌ Failed to save image");
//     }
}

- (void)startSession:(FlutterRTCVideoRenderer *)render andArg:(NSDictionary *)args  {
    queue = [NSOperationQueue new];
    serialQueue = dispatch_queue_create("com.example.mySerialQueue", DISPATCH_QUEUE_SERIAL);
    frameRate = CMTimeMake(1, 30);
    lastSampleTime = CMTimeMake(0, 30);


    videoOutputFullFileName = args[@"path"];


    NSFileManager *fileManager = [NSFileManager defaultManager];
    

    if (videoOutputFullFileName == NULL) {
        NSArray *paths = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsURL = [paths lastObject];
        documentsURL = [documentsURL URLByAppendingPathComponent:@"test_capture_video.mp4"];
        videoOutputFullFileName = documentsURL.path;
    }

    isRecordingVideo = true;

    if ([fileManager fileExistsAtPath:videoOutputFullFileName]) {
        NSLog(@"PixelBufferRecorder: WARN:::The file: \(self.videoOutputFullFileName!) exists, will delete the existing file");

        @try {
            [fileManager removeItemAtPath:videoOutputFullFileName error:NULL];
        } @catch (NSException *e) {
            NSLog(@"PixelBufferRecorder: Exception: %@ line:%d", e, __LINE__);
        }
    }
    
    // Check if the directory already exists
    if (![fileManager fileExistsAtPath:videoOutputFullFileName]) {
        NSError *error = nil;
        NSString *directoryPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/live_view"];

        // Create the directory (with intermediate directories if needed)
        BOOL success = [fileManager createDirectoryAtPath:directoryPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];

        if (success) {
            NSLog(@"✅ Folder created at: %@", videoOutputFullFileName);
        } else {
            NSLog(@"❌ Failed to create folder: %@", error.localizedDescription);
        }
    } else {
        NSLog(@"ℹ️ Folder already exists: %@", videoOutputFullFileName);
    }


    NSDictionary *pixelBufferAttributes = @{
            (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{},
            (__bridge NSString *)kCVPixelBufferMetalCompatibilityKey: @NO,
            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @((int)CVPixelBufferGetPixelFormatType(render.copyPixelBuffer)),
            (__bridge NSString *)kCVPixelBufferWidthKey:  @((int)640),
            (__bridge NSString *)kCVPixelBufferHeightKey: @((int)480),
    };

    NSDictionary *videoSettings = @{
            AVVideoCodecKey: AVVideoCodecTypeH264,
            AVVideoWidthKey:  [NSNumber numberWithInt:((int)640)],
            AVVideoHeightKey: [NSNumber numberWithInt:((int)480)]
    };





    videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];

    adaptor =  [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:pixelBufferAttributes];

    NSError *error = NULL;
    
    NSURL *fileURl = [NSURL fileURLWithPath:videoOutputFullFileName];

    videoWriter = [[AVAssetWriter alloc] initWithURL: fileURl fileType:AVFileTypeMPEG4 error:&error];


    NSLog(@"PixelBufferRecorder: videoWriter error %@", error.description);

    [videoWriter addInput:videoWriterInput];

    if (videoWriter.status != AVAssetWriterStatusWriting) {
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
    }

    render.delegate = self;
}

- (void)stopRecording:(nullable void (^)(NSString *data))completionHandler {
    NSLog(@"PixelBufferRecorder: videoWriter will Stop");

    if (!isRecordingVideo) {
        return;
    }

    isRecordingVideo = false;

    NSLog(@"PixelBufferRecorder: videoWriter waitUntilAllOperationsAreFinished");
    [queue waitUntilAllOperationsAreFinished];
    NSLog(@"PixelBufferRecorder: videoWriter waitUntilAllOperationsAreFinished- done");

    [videoWriter endSessionAtSourceTime:lastSampleTime];
    [videoWriter finishWritingWithCompletionHandler:^{
        NSFileManager *fileManeger = [NSFileManager defaultManager];

        if ([fileManeger fileExistsAtPath:videoOutputFullFileName]) {
            NSString *bundleId = [[NSBundle mainBundle].bundleIdentifier lowercaseString];

            NSURL *shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:bundleId ];

            if (shareUrl == NULL) {
                shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:@"com.sc.command"];
            }

            if (shareUrl == NULL) {
                shareUrl = [fileManeger containerURLForSecurityApplicationGroupIdentifier:@"org.cocoapods.flutter-webrtc"];
            }

            NSLog(@"PixelBufferRecorder: videoWriter createdOperationForLibrary %@", videoOutputFullFileName);

            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:shareUrl == nil ?
                                                                                 videoOutputFullFileName : shareUrl.path]];
            }
                                              completionHandler:^(BOOL success, NSError *error) {
                if (success) {
                    NSLog(@"PixelBufferRecorder: success iOS 9");
                } else {
                    NSLog(@"PixelBufferRecorder: videoWriter failed to save %@", error);
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

- (void)createOutput:(CMSampleBufferRef)sampleBuffer {
    NSFileManager *fileManeger = [NSFileManager defaultManager];
    NSArray *paths = [fileManeger URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];

    documentsURL = [documentsURL URLByAppendingPathComponent:@"test_capture_video.mp4"];

    videoOutputFullFileName = documentsURL.path;


    isRecordingVideo = true;

    if ([fileManeger fileExistsAtPath:videoOutputFullFileName]) {
        NSLog(@"WARN:::The file: %@ exists, will delete the existing file", videoOutputFullFileName);

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

@end
