//
//  CameraViewController.h
//  hw3
//
//  Created by Yingyi Yang on 7/8/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraViewController;

@protocol CameraViewControllerDelegate <NSObject>
-(void)cameraViewControllerDidGoBack:
(CameraViewController *)controller;

@end

@interface CameraViewController : UIViewController


@end
