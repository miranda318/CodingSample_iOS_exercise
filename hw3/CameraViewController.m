//
//  CameraViewController.m
//  hw3
//
//  Created by Yingyi Yang on 7/8/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//

#import "CameraViewController.h"
#import "PlayerView.h"

@import Accounts;
@import MediaPlayer;
@import Social;
@import AVFoundation;
@import Photos;
@import ImageIO;

@interface CameraViewController () <AVCaptureFileOutputRecordingDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *swapCamButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *videoStartButton;
@property (weak, nonatomic) IBOutlet UIButton *videoStopButton;
@property (weak, nonatomic) IBOutlet UIButton *photoActionButton;
@property (weak, nonatomic) IBOutlet UIButton *saveImageButton;
@property (weak, nonatomic) IBOutlet UIButton *discardImageButton;
@property (weak, nonatomic) IBOutlet UIButton *videoDoneButton;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) NSOperationQueue *captureSessionQueue;
@property (nonatomic, strong) AVCaptureDevice *backCameraDevice;
@property (nonatomic, strong) AVCaptureDevice *frontCameraDevice;
@property (nonatomic, weak) AVCaptureDevice *currentCameraDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *outputFileURL;
@property (nonatomic, strong) NSString *textString;
@property BOOL isImage;
@property UIBackgroundTaskIdentifier backgroundRecordingID;


@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self cameraMode];
    
    // Make image view transparend. (We don't need it for now.)
    self.imageView.alpha = 0;
    self.playerView.alpha = 0;
    
    // Setup session queue
    self.captureSessionQueue = [[NSOperationQueue alloc] init];
    self.captureSessionQueue.name = NSStringFromSelector(@selector(captureSessionQueue));
    
    // Setup capture session
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh]; // High res, babe!
    
    // Get available camera devices.
    NSArray *availableCameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in availableCameraDevices) {
        if (device.position == AVCaptureDevicePositionBack) {
            self.backCameraDevice = device;
        }
        else  if (device.position == AVCaptureDevicePositionFront) {
            self.frontCameraDevice = device;
        }
    }
    
    
    // Activate back camera (default) input.
    [self activateDeviceInputForDeivce:self.backCameraDevice];
    
    // Add still image output
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey,nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    
    // Add movie file output
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ( [self.session canAddOutput:self.movieFileOutput] ) {
        [self.session addOutput:self.movieFileOutput];
        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ( connection.isVideoStabilizationSupported ) {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    // Setup and add preview layer for live camera feed.
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.previewLayer setFrame:self.view.frame];
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    // Start the capture session.
    [self.session startRunning];
    
}

- (void) viewDidAppear:(BOOL)animated {
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Helper Methods
/**
 Gets and adds input of given device to capture session.
 
 @param device An AVCaptureDevice for creating capture device input.
 */
- (void)activateDeviceInputForDeivce:(AVCaptureDevice *)device {
    NSError *error = nil;
    AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error]; // Create capture device input with given device.
    if (cameraInput) {
        [self.session removeInput:[self.session.inputs firstObject]]; // Remove previous camera input from capture session.
        if ([self.session canAddInput:cameraInput]) { // Add new camera input to capture session if possible.
            [self.session addInput:cameraInput];
            self.currentCameraDevice = device;
        }
    }
}

- (void)cameraMode {
    self.cameraButton.hidden = YES;
    self.videoButton.hidden = NO;
    self.videoStartButton.hidden = YES;
    self.videoStopButton.hidden = YES;
    self.photoActionButton.hidden = NO;
    self.saveImageButton.hidden = YES;
    self.discardImageButton.hidden = YES;
    self.videoDoneButton.hidden = YES;
    self.title = @"Take a Photo";
}

- (void)videoMode {
    self.cameraButton.hidden = NO;
    self.videoButton.hidden = YES;
    self.videoStartButton.hidden = NO;
    self.videoStopButton.hidden = YES;
    self.photoActionButton.hidden = YES;
    self.saveImageButton.hidden = YES;
    self.discardImageButton.hidden = YES;
    self.videoDoneButton.hidden = YES;
    self.title = @"Record a video";
}

- (void)imagePreviewMode {
    self.cameraButton.hidden = YES;
    self.videoButton.hidden = YES;
    self.videoStartButton.hidden = YES;
    self.videoStopButton.hidden = YES;
    self.photoActionButton.hidden = YES;
    self.saveImageButton.hidden = NO;
    self.discardImageButton.hidden = NO;
    self.videoDoneButton.hidden = YES;
}

- (void)videoPreviewMode {
    self.cameraButton.hidden = YES;
    self.videoButton.hidden = YES;
    self.videoStartButton.hidden = YES;
    self.videoStopButton.hidden = YES;
    self.photoActionButton.hidden = YES;
    self.saveImageButton.hidden = YES;
    self.discardImageButton.hidden = YES;
    self.videoDoneButton.hidden = NO;
}

- (NSString *)getBasicInfo {
    
    //device info
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceModel = device.localizedModel;
    NSString *deviceSystemVersion = device.systemVersion;
    
    //date
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterLongStyle;
    NSString *todayString = [dateFormatter stringFromDate:today];
    NSString *textString = [NSString stringWithFormat:@"yingyiy, %@.%@, %@", deviceModel, deviceSystemVersion, todayString];
    return textString;
}

#pragma mark - IBActions
- (IBAction)videoButtonDidPushed:(id)sender {
    [self videoMode];
}

- (IBAction)cameraButtonDidPushed:(id)sender {
    [self cameraMode];
}

- (IBAction)phtotActionButtonDidPushed:(id)sender {
    // Find video connect for capturing still image from stillImageOutput
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    // Capture still image asynchronously from connection.
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        //        CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        self.isImage = YES;
        
        // Get image data from image sample buffer.
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        // Get image from image data
        self.image = [[UIImage alloc] initWithData:imageData];
        // Add image to image view
        self.imageView.image = self.image;
        
        // Show image view with animation.
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIView animateWithDuration:0.5 animations:^{
                self.imageView.alpha = 1;
            }];
        }];
        [self imagePreviewMode];
    }];
}

- (IBAction)videoStartButtonDidPushed:(id)sender {
    [self.captureSessionQueue addOperationWithBlock:^{
        if ( [UIDevice currentDevice].isMultitaskingSupported ) {
            // Setup background task. This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
            // callback is not received until AVCam returns to the foreground unless you request background execution time.
            // This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
            // To conclude this background execution, -endBackgroundTask is called in
            // -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
            self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        
        // Update the orientation on the movie file output video connection before starting recording.
        AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        connection.videoOrientation = self.previewLayer.connection.videoOrientation;
        
        // Start recording to a temporary file.
        NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
        NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
        [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
    }];
    self.videoStartButton.hidden = YES;
    self.videoStopButton.hidden = NO;
}

- (IBAction)videoStopButtionDidPushed:(id)sender {
    [self.movieFileOutput stopRecording];
    
    NSLog(@"%@",[self getBasicInfo]);
    
    self.isImage = NO;
    
    [self videoPreviewMode];
}


- (IBAction)saveImage:(id)sender {
    NSParameterAssert(self.image);
    UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil);
    [self cameraMode];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.imageView.alpha = 0;
    }];
    NSLog(@"%@", [self getBasicInfo]);
}

- (IBAction)discardImage:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.imageView.alpha = 0;
    }];
    [self cameraMode];
}

- (IBAction)doneWithVideo:(id)sender {
    [UIView animateWithDuration:0.5 animations:^{
        self.playerView.alpha = 0;
    }];
    // Check authorization status.
    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
        if ( status == PHAuthorizationStatusAuthorized ) {
            // Save the movie file to the photo library and cleanup.
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                // In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
                // This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
                
                //iOS9 code
                /*
                 if ( [PHAssetResourceCreationOptions class] ) {
                 PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                 options.shouldMoveFile = YES;
                 PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                 [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
                 }
                 */
                //else {
                [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.outputFileURL];
                //}
            } completionHandler:^( BOOL success, NSError *error ) {
                if ( ! success ) {
                    NSLog( @"Could not save movie to photo library: %@", error );
                }
                [self removeTempVideoFileWithURL:self.outputFileURL];
            }];
        }
        else {
            [self removeTempVideoFileWithURL:self.outputFileURL];
        }
    }];

    [self videoMode];
}

- (IBAction)swapCameraButtonDidPushed:(id)sender {
    [self.session stopRunning]; // Stop capture session before making changes.
    // Switch input camera device
    if ([self.currentCameraDevice isEqual:self.backCameraDevice]) {
        [self activateDeviceInputForDeivce:self.frontCameraDevice];
    }
    else if ([self.currentCameraDevice isEqual:self.frontCameraDevice]) {
        [self activateDeviceInputForDeivce:self.backCameraDevice];
    }
    [self.session startRunning]; // Re-start capture session.
}

- (IBAction)tweetTapped:(id)sender {
    //[_posting startAnimating];
    if (self.isImage){
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [tweetSheet  setInitialText:[self getBasicInfo]];
            [tweetSheet addImage:self.image];
            [self presentViewController:tweetSheet animated:YES completion:nil];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Sorry"
                                      message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                      delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        }
    } else {
        [self performSegueWithIdentifier:@"ToCustomComposeView" sender:nil];
    }
}

#pragma mark File Output Delegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    BOOL success = YES;
    
    if ( error ) {
        NSLog( @"Movie file finishing error: %@", error );
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    if ( success ) {
        self.outputFileURL = outputFileURL;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.outputFileURL];
            AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
            [self.playerView setPlayer:player];
            
            [UIView animateWithDuration:0.5 animations:^{
                self.playerView.alpha = 1;
            }];
        }];
    }
    else {
        [self removeTempVideoFileWithURL:outputFileURL];
    }
}

- (void)removeTempVideoFileWithURL:(NSURL *)fileURL {
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
        [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
    }
}


@end
