//
//  ComposeVideoViewController.h
//  hw3
//
//  Created by Yingyi Yang on 7/12/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerView.h"
#import "CameraViewController.h"
@import Accounts;

@interface ComposeVideoViewController : UIViewController
@property (strong, nonatomic) NSURL *outputFileURL;
@property (strong, nonatomic) NSString *string;
@property (strong, nonatomic) ACAccount *twitterAccount;
@property UIBackgroundTaskIdentifier backgroundRecordingID;
@end
