//
//  ReadTimelineTableViewController.m
//  hw3
//
//  Created by Yingyi Yang on 7/14/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//
//  This tab displays tweets from the user (the first Twitter account in account store). If a tweet comes with a video, user can play this video in AVKit view controller in the next level. 

#import "ReadTimelineTableViewController.h"
#import "TWFeedTableViewCell.h"
#import "AVKitViewController.h"
@import Social;
@import Accounts;
static NSString * const newsFeedCellIdentifier = @"NewsFeedCell";

@interface ReadTimelineTableViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) NSArray *tweets;
@property NSOperationQueue *imageLoadingQueue;
@property (nonatomic, strong) NSString *mediaType;
@property (nonatomic, strong) NSURL *mediaURL;

@end

@implementation ReadTimelineTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Timeline";
    
    // Set dynamic row height
    self.tableView.estimatedRowHeight = 210;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    // Init queue
    self.imageLoadingQueue = [[NSOperationQueue alloc] init];
    self.imageLoadingQueue.maxConcurrentOperationCount = 4;
    self.imageLoadingQueue.name = @"imageLoadingQueue";
    
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            
            // Check if the users has setup at least one Twitter account
            
            if (accounts.count > 0)
            {
                ACAccount *twitterAccount = [accounts objectAtIndex:0];
                NSURL *twitterGetURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/user_timeline.json"];
                NSDictionary *getParams = @{@"user_id": @"yingyiy"};
                SLRequest *getRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:twitterGetURL parameters:getParams];
                getRequest.account = twitterAccount;
                
                [getRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        if (!error) {
                            NSLog(@"Get timeline succeed!");
                            id JSONResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                            if ([JSONResponse isKindOfClass:[NSArray class]]) {
                                self.tweets = JSONResponse;
                                NSLog(@"%@", self.tweets[0]);
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    [self.tableView reloadData];
                                }];
                            }
                        }
                        else {
                            NSLog(@"Error get timeline - %@", error);
                        }
                    }
                 ];
                
            } else {
                NSLog(@"No access granted");
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sorry"
                                                                               message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Don't Allow" style:UIAlertActionStyleCancel handler:^(UIAlertAction *backToCameraViewController) {
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
    }];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma helper methods

- (UIImage *)convertURLStringToImage: (NSString *) urlString {
    NSURL *imageNSURL = [NSURL URLWithString:urlString];
    NSData *imageData = [NSData dataWithContentsOfURL:imageNSURL];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    return image;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.tweets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TWFeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewsFeedCell"];
     // Hide play button first.
    cell.playButton.hidden = YES;
    
    // Find tweet
    NSDictionary *tweetDict = self.tweets[indexPath.row];
    
    // Configure the cell...
    if (tweetDict[@"user"]) {
        cell.screenNameLabel.text = tweetDict[@"user"][@"screen_name"];
        cell.nameLabel.text = [NSString stringWithFormat:@"@%@", tweetDict[@"user"][@"name"]];
        
    } else NSLog(@"No user dictorory.");
    
    cell.feedLabel.text = tweetDict[@"text"];
    
    // Format date
    NSString *JSONTimeString = tweetDict[@"created_at"];
    NSLog(@"JSON date: %@", JSONTimeString);
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    NSDate *createDate = [dateFormatter dateFromString:JSONTimeString];
    NSDate *today = [NSDate date];
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = NSDateFormatterLongStyle;
    
    NSInteger displayTimeDistance = 0;
    NSString *timeString = @"";
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *differenceValue = [calendar components:NSCalendarUnitDay
                                                    fromDate:createDate toDate:today options:0];
    
    displayTimeDistance = [differenceValue day];
    if (displayTimeDistance < 1) {
        differenceValue = [calendar components:NSCalendarUnitHour
                                      fromDate:createDate toDate:today options:0];
        displayTimeDistance = [differenceValue hour];
        if (displayTimeDistance < 1) {
            differenceValue = [calendar components:NSCalendarUnitMinute
                                          fromDate:createDate toDate:today options:0];
            displayTimeDistance = [differenceValue minute];
            if (displayTimeDistance < 1) {
                differenceValue = [calendar components:NSCalendarUnitSecond
                                              fromDate:createDate toDate:today options:0];
                displayTimeDistance = [differenceValue second];
                timeString = [NSString stringWithFormat:@"%lds", (long)displayTimeDistance];
            } else {
                timeString = [NSString stringWithFormat:@"%ldm", (long)displayTimeDistance];
            }
        } else {
            timeString = [NSString stringWithFormat:@"%ldh", (long)displayTimeDistance];
        }
    } else {
        timeString = [NSString stringWithFormat:@"%ldd", (long)displayTimeDistance];
    }
    
    cell.timeLabel.text = timeString;

    
    // Load image from queue.
    [self.imageLoadingQueue addOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Porfile image
            NSString *porfileImageURLString = tweetDict[@"user"][@"profile_image_url"];
            NSLog(@"porfile: %@", porfileImageURLString);
            cell.userImageView.image = [self convertURLStringToImage:porfileImageURLString];
            
            //News feed image
            if (tweetDict[@"extended_entities"]) {
                NSArray *mediaArray = tweetDict[@"extended_entities"][@"media"];
                NSDictionary *mediaDic = [mediaArray firstObject];
                NSString *feedImageURLString = mediaDic[@"media_url"];
                cell.photoImageView.image = [self convertURLStringToImage:feedImageURLString];
                
                if ([mediaDic[@"type"] isEqualToString:@"photo"]) {
                    cell.playButton.hidden = YES;
                } else if ([mediaDic[@"type"] isEqualToString:@"video"]) {
                    cell.playButton.hidden = NO;
                } else {
                    NSLog(@"Unknow media type in Read Timeline Table View Controller.");
                    cell.playButton.hidden = YES;
                }

            }
            // This tweet does not have images or videos.
            else {
                //[cell.photoImageView removeFromSuperview];
                cell.photoImageView.image = nil;
                cell.playButton.hidden = YES;

            }
        }];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Find tweet
    NSDictionary *tweetDict = self.tweets[indexPath.row];
    NSArray *mediaArray = tweetDict[@"extended_entities"][@"media"];
    NSDictionary *mediaDic = [mediaArray firstObject];
    if ([mediaDic[@"type"] isEqualToString:@"video"]) {
        [self performSegueWithIdentifier:@"playVideo" sender:nil];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    // Find tweet
    NSDictionary *tweetDict = self.tweets[indexPath.row];
    NSArray *mediaArray = tweetDict[@"extended_entities"][@"media"];
    NSDictionary *mediaDic = [mediaArray firstObject];
    if ([[segue identifier] isEqualToString:@"playVideo"]) {
        AVKitViewController *viewController = segue.destinationViewController;
        //Setup layer view controller for movie.
        if (mediaDic[@"media_url"] != nil && [mediaDic[@"type"] isEqualToString:@"video"]) {
            NSArray *variants = mediaDic[@"video_info"][@"variants"];
            for (NSDictionary *oneVariant in variants) {
                if ([oneVariant[@"content_type"] isEqualToString:@"video/mp4"] && [oneVariant[@"bitrate"] integerValue] == 832000) {
                    viewController.mediaURL = [NSURL URLWithString:oneVariant[@"url"]];
                    break;
                }
            }
        }
    }
}

@end
