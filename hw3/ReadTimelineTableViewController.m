//
//  ReadTimelineTableViewController.m
//  hw3
//
//  Created by Yingyi Yang on 7/14/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//

#import "ReadTimelineTableViewController.h"
#import "TWFeedTableViewCell.h"
@import Social;
@import Accounts;
static NSString * const newsFeedCellIdentifier = @"NewsFeedCell";

@interface ReadTimelineTableViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) NSArray *tweets;

@end

@implementation ReadTimelineTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            
            // Check if the users has setup at least one Twitter account
            
            if (accounts.count > 0)
            {
                ACAccount *twitterAccount = [accounts objectAtIndex:0];
                NSURL *twitterGetURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/user_timeline.json"];
                NSDictionary *getParams = @{@"user_id": @"yingyiy",
                                            @"exclude_replies":@"true",
                                            };
                SLRequest *getRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:twitterGetURL parameters:getParams];
                getRequest.account = twitterAccount;
                
                [getRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                        NSLog(@"Get timeline HTTP Response)%li, %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                        if (!error) {
                            NSLog(@"Get timeline succeed!");
                            id JSONResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
                            if ([JSONResponse isKindOfClass:[NSArray class]]) {
                                self.tweets = JSONResponse;
                            }
                        }
                        else {
                            NSLog(@"Error get timeline - %@", error);
                        }
                    }
                 ];
                
            } else {
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
    TWFeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewsFeedCell" forIndexPath:indexPath];
    
    // Find tweet
    NSDictionary *tweetDict = self.tweets[indexPath.row];
    
    // Configure the cell...
    cell.screenNameLabel.text = tweetDict[@"user"][@"screen_name"];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
