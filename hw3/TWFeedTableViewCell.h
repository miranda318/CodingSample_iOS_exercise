//
//  TWFeedTableViewCell.h
//  hw3
//
//  Created by Yingyi Yang on 7/14/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerView.h"

@interface TWFeedTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *screenNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *feedLabel;
@property (nonatomic, weak) IBOutlet UIImageView *userImageView;
@property (nonatomic, weak) IBOutlet UIImageView *photoImageView;
@property (nonatomic, weak) IBOutlet PlayerView *playerView;

@end
