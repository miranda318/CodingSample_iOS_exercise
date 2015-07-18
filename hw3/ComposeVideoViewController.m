//
//  ComposeVideoViewController.m
//  hw3
//
//  Created by Yingyi Yang on 7/12/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//

#import "ComposeVideoViewController.h"
@import AVFoundation;
@import Social;

@interface ComposeVideoViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (strong, nonatomic) AVPlayer *player;

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
    
//    [[self.playerView layer] setBorderColor:[[UIColor grayColor] CGColor]];
//    [[self.playerView layer] setBorderWidth:2.3];
//    [[self.playerView layer] setCornerRadius:15];
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

#pragma mark - Buttons

- (void) completion {
    
}

- (IBAction)postButtonDidPush:(id)sender {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            
            // Check if the users has setup at least one Twitter account
            
            if (accounts.count > 0)
            {
                ACAccount *twitterAccount = [accounts objectAtIndex:0];
                NSData *videoData = [NSData dataWithContentsOfURL:self.outputFileURL];
                [self uploadTwitterVideo:videoData account:twitterAccount withCompletion:^{
                    [self completion];
                }];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Twiter" message:@"Sending your tweet..." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        else {
                NSLog(@"No access granted");
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"Sorry"
                                          message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                          delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];

            }
        }
    }
     ];
    // In case the post button is hit more than once.
    self.postButton.enabled = NO;
}

-(IBAction)cancelToCameraViewController:(id)sender {
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
        //NSLog(@"Stage 4 HTTP Response: %td, %@", [urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Error stage 4 - %@", error);
        } else {
            if ([urlResponse statusCode] == 200){
                NSLog(@"upload success !");
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
