//
//  ComposeVideoViewController.m
//  hw3
//
//  Created by Yingyi Yang on 7/12/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//
//  This tabs allows users to take a picture or vedio using front/back camera. After taking the picture/video, they can also tweet it using the first Twitter account in the account store.

#import "ComposeVideoViewController.h"
@import AVFoundation;
@import Social;

@interface ComposeVideoViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation ComposeVideoViewController
@synthesize string;
@synthesize outputFileURL;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.outputFileURL];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    [self.playerView setPlayer:self.player];

    [[self.textView layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[self.textView layer] setBorderWidth:2.3];
    [[self.textView layer] setCornerRadius:15];
    self.textView.text = [NSString stringWithFormat:@"@MobileApp4 %@", self.string];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    // Reactivate the post button.
    self.postButton.enabled = YES;
}

#pragma Helper methods

- (void)removeTempVideoFileWithURL:(NSURL *)fileURL {
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
    if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
        [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
    }
    NSLog(@"Output file URL is removed.");

}


- (void) completion {
    
}

#pragma mark - Buttons

- (IBAction)postButtonDidPush:(id)sender {
    NSData *videoData = [NSData dataWithContentsOfURL:self.outputFileURL];
    [self uploadTwitterVideo:videoData account:self.twitterAccount withCompletion:^{
        [self completion];
    }];
    
    if (!self.loadingView) {
        // Init loading view
        self.loadingView = [[UIView alloc] init];
        self.loadingView.translatesAutoresizingMaskIntoConstraints = NO;
        self.loadingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        [self.view addSubview:self.loadingView];
        // Add loading view auto layout constraints
        NSArray *loadingViewHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[loadingView]|"
                                                                                            options:0
                                                                                            metrics:nil
                                                                                              views:@{@"loadingView": self.loadingView}];
        NSArray *loadingViewVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[loadingView]|"
                                                                                          options:0
                                                                                          metrics:nil
                                                                                            views:@{@"loadingView": self.loadingView}];
        [NSLayoutConstraint activateConstraints:loadingViewHorizontalConstraints];
        [NSLayoutConstraint activateConstraints:loadingViewVerticalConstraints];
        
        // Init activity indicator
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.translatesAutoresizingMaskIntoConstraints = NO;
        [spinner startAnimating];
        [self.loadingView addSubview:spinner];
        // Add spinner auto layout constraints
        NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:spinner
                                                                             attribute:NSLayoutAttributeCenterX
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.loadingView
                                                                             attribute:NSLayoutAttributeCenterX
                                                                            multiplier:1
                                                                              constant:0];
        centerXConstraint.active = YES;
        NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:spinner
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:self.loadingView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1
                                                                              constant:0];
        centerYConstraint.active = YES;
    }
    self.loadingView.hidden = NO;
    
    // In case the post button is hit more than once.
    self.postButton.enabled = NO;
}

-(IBAction)cancelToCameraViewController:(id)sender {
    [self removeTempVideoFileWithURL:self.outputFileURL];
    [self performSegueWithIdentifier:@"UnwindToCameraViewController" sender:self];
}

-(IBAction)playButtonDidPush:(id)sender {
    [self.player play];
    self.playButton.hidden = YES;
}


#pragma mark - CameraViewControllDelegate
-(void)cameraViewControllerDidTweetVideo:(CameraViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma SendVideoTweeet Method

- (void)uploadTwitterVideo:(NSData*)videoData account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSDictionary *postParams = @{@"command": @"INIT",
                                 @"total_bytes" : [NSNumber numberWithInteger: videoData.length].stringValue,
                                 @"media_type" : @"video/mp4"
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    request.account = account;
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Stage 1 HTTP Response: %td, responseData: %@", [urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"There was an error:%@", [error localizedDescription]);
            // Hide spinner
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.loadingView.hidden = NO;
            }];
            
            // Show error alert
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Video upload errors in stage 1." preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleCancel handler:^(UIAlertAction *backToCameraViewController) {
                [self performSegueWithIdentifier:@"UnwindToCameraViewController" sender:self];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSString *mediaID = [NSString stringWithFormat:@"%@", [returnedData valueForKey:@"media_id_string"]];
            
            [self tweetVideoStage2:videoData mediaID:mediaID account:account withCompletion:completion];
            
            NSLog(@"stage one success, mediaID -> %@", mediaID);
        }
    }];
}

- (void)tweetVideoStage2:(NSData*)videoData mediaID:(NSString *)mediaID account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    NSDictionary *postParams = @{@"command": @"APPEND",
                                 @"media_id" : mediaID,
                                 @"media_data": [videoData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength],
                                 @"segment_index" : @"0",
                                 };
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    postRequest.account = account;
    
//    [postRequest addMultipartData:videoData withName:@"media" type:@"video/mp4" filename:@"video"];
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Stage2 HTTP Response: %td, %@", [urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (!error) {
            [self tweetVideoStage3:videoData mediaID:mediaID account:account withCompletion:completion];
            NSLog(@"Stage 2 succeed.");
        }
        else {
            NSLog(@"Error stage 2 - %@", error);
            // Hide spinner
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.loadingView.hidden = NO;
            }];
            
            // Show error alert
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Video upload errors in stage 2." preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleCancel handler:^(UIAlertAction *backToCameraViewController) {
                [self performSegueWithIdentifier:@"UnwindToCameraViewController" sender:self];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)tweetVideoStage3:(NSData*)videoData mediaID:(NSString *)mediaID account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSDictionary *postParams = @{@"command": @"FINALIZE",
                                 @"media_id" : mediaID };
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    
    // Set the account and begin the request.
    postRequest.account = account;
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Stage3 HTTP Response: %td, %@", [urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Error stage 3 - %@", error);
            // Hide spinner
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.loadingView.hidden = NO;
            }];
            
            // Show error alert
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Video upload errors in stage 3." preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Back" style:UIAlertActionStyleCancel handler:^(UIAlertAction *backToCameraViewController) {
                [self performSegueWithIdentifier:@"UnwindToCameraViewController" sender:self];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
            
        } else {
            [self tweetVideoStage4:videoData mediaID:mediaID account:account withCompletion:completion];
            NSLog(@"Stage 3 succeed.");

        }
    }];
}

- (void)tweetVideoStage4:(NSData*)videoData mediaID:(NSString *)mediaID account:(ACAccount*)account withCompletion:(dispatch_block_t)completion{
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    
    // Set the parameters for the third twitter video request.
    NSDictionary *postParams = @{@"status": self.textView.text,
                                 @"media_ids" : @[mediaID]};
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    postRequest.account = account;
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        // Hide spinner
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.loadingView.hidden = NO;
        }];
        if (error) {
            NSLog(@"Error stage 4 - %@", error);
        } else {
            if ([urlResponse statusCode] == 200){
                NSLog(@"upload success !");
                // Remove output file url
                [self removeTempVideoFileWithURL:self.outputFileURL];
                
                // Show success alert
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Twitter" message:@"Your tweet is sent!" preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *backToCameraViewController) {
                    [self performSegueWithIdentifier:@"UnwindToCameraViewController" sender:self];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }];
    
}

@end
