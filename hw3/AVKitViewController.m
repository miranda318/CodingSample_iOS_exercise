//
//  AVKitViewController.m
//  hw3
//
//  Created by Miranda Yang on 9/26/15.
//  Copyright © 2015 Yingyi Yang. All rights reserved.
//

#import "AVKitViewController.h"

@interface AVKitViewController ()

@property (weak, nonatomic) IBOutlet UIView *container;

@end

@implementation AVKitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeButtonDidPushed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showMovie"]) {
        AVPlayerViewController *playerViewController = segue.destinationViewController;
        
        //Setup layer view controller for movie.
        playerViewController.player = [AVPlayer playerWithURL:self.mediaURL];
    }
}


@end
