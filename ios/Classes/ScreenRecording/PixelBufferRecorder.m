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

- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

    CIContext *temporaryContext = [CIContext contextWithOptions:nil];

    CGImageRef videoImage = [temporaryContext createCGImage:ciImage
                                                   fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];

    UIImage *finalImage = [UIImage imageWithCGImage:videoImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];

    CGImageRelease(videoImage);

    return finalImage;
}

- (void)saveUIImageAsPNG:(UIImage *)image path:(NSString *)path fileName:(NSString *)fileName {
    NSString *imagePath;

    if (path) {
        imagePath = path;
    } else {
        imagePath = [self documentsPathForFileName:fileName];
    }

    NSData *imageData = UIImagePNGRepresentation(image);


    BOOL success = [imageData writeToFile:imagePath atomically:YES];

    if (success) {
        NSLog(@"PNG saved at %@", imagePath);
        [self saveImageUsingPHPhotoLibrary:imagePath];
    } else {
        NSLog(@"Failed to save PNG");
    }
}

- (void)saveImageToGallery:(UIImage *)image {
    if (image) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    } else {
        NSLog(@"Image is nil, cannot save to gallery");
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"Error saving image to gallery: %@", error.localizedDescription);
    } else {
        NSLog(@"Image saved successfully to gallery!");
    }
}

- (NSString *)documentsPathForFileName:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];


    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

- (void)screenShot:(FlutterRTCVideoRenderer *)render andArg:(NSDictionary *)args {
    UIImage *image = [self imageFromPixelBuffer:render.copyPixelBuffer];

    if (image != nil) {
        [self saveUIImageAsPNG:image path:args[@"path"] fileName:args[@"fileName"]];
    }
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
            (__bridge NSString *)kCVPixelBufferWidthKey:  @((int)render.frameSize.width),
            (__bridge NSString *)kCVPixelBufferHeightKey: @((int)render.frameSize.height),
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

    videoWriter = [[AVAssetWriter alloc] initWithURL:fileURl fileType:AVFileTypeMPEG4 error:&error];


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
          

            NSLog(@"PixelBufferRecorder: videoWriter createdOperationForLibrary %@", videoOutputFullFileName);

            [self saveVideoUsingPHPhotoLibrary:videoOutputFullFileName];
        }
    }];
}

- (void)saveVideoUsingPHPhotoLibrary:(NSString *)filePath {
    NSURL *videoURL = [NSURL fileURLWithPath:filePath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSLog(@"Video not found at path: %@", filePath);
        return;
    }

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
    }
                                      completionHandler:^(BOOL success, NSError *_Nullable error) {
        if (success) {
            NSLog(@"Video saved to Photos!");
        } else {
            NSLog(@"Failed to save video: %@", error.localizedDescription);
        }
    }];
}

- (void)saveImageUsingPHPhotoLibrary:(NSString *)filePath {
    NSURL *imageURL = [NSURL fileURLWithPath:filePath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSLog(@"Video not found at path: %@", filePath);
        return;
    }

    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:imageURL];
    }
                                      completionHandler:^(BOOL success, NSError *_Nullable error) {
        if (success) {
            NSLog(@"Image saved to Photos!");
        } else {
            NSLog(@"Failed to save image: %@", error.localizedDescription);
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
