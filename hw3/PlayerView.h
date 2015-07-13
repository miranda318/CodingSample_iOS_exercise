//
//  PlayerView.h
//  
//
//  Created by Miranda Yang on 7/5/15.
//
//

#import <UIKit/UIKit.h>
@import AVFoundation;

@interface PlayerView : UIView

@property (nonatomic) AVPlayer *player;

+ (Class)layerClass;
- (AVPlayer *)player;
- (void)setPlayer:(AVPlayer *)player;

@end
