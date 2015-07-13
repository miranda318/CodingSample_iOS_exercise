//
//  AssestViewController.m
//
//
//  Created by Miranda Yang on 7/5/15.
//
//

#import "AssestViewController.h"
#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>
@import MediaPlayer;

static const NSString *ItemStatusContext;

@interface AssestViewController () {
    NSDateFormatter *_dateFormatter;
    NSString *totalTime;
    NSString *_totalTime;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *playControlButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseControlButton;
@property (weak, nonatomic) IBOutlet UISlider *videoSlider;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (nonatomic ,strong) id playbackTimeObserver;

- (IBAction)videoSlierChangeValue:(id)sender;
- (IBAction)videoSlierChangeValueEnd:(id)sender;

@end

@implementation AssestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    dateformatter.dateStyle = NSDateFormatterShortStyle;
    self.title = [dateformatter stringFromDate:self.asset.creationDate];
    
    if (self.asset.mediaType == PHAssetMediaTypeImage) {
        self.imageView.hidden = NO;
        self.playerView.hidden = YES;
        self.playControlButton.hidden = YES;
        self.pauseControlButton.hidden = YES;
        self.videoSlider.hidden = YES;

        [[PHImageManager defaultManager] requestImageForAsset:self.asset
                                                   targetSize:self.imageView.bounds.size
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:0
                                                resultHandler:^(UIImage *result, NSDictionary *info) {
                                                    self.imageView.image = result;
                                                }];
    } else if (self.asset.mediaType == PHAssetMediaTypeVideo) {
        self.imageView.hidden = YES;
        self.playerView.hidden = NO;
        self.playControlButton.hidden = NO;
        self.pauseControlButton.hidden = YES;
        self.videoSlider.hidden = NO;

        [[PHImageManager defaultManager] requestPlayerItemForVideo:self.asset
                                                           options:0
                                                     resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
                                                         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                             // ensure that this is done before the playerItem is associated with the player
                                                             [[NSNotificationCenter defaultCenter] addObserver:self
                                                                                                      selector:@selector(playerItemDidReachEnd:)
                                                                                                          name:AVPlayerItemDidPlayToEndTimeNotification
                                                                                                        object:playerItem];
                                                             self.player = [AVPlayer playerWithPlayerItem:playerItem];
                                                             self.playerItem = playerItem;
                                                             
                                                             [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
                                                             [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
                                                             [self.playerView setPlayer:self.player];
                                                         }];
                                                     }];
    } else {
        NSLog(@"This asset is not an image or video.");
        self.title = @"Error!";
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.player pause];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            CMTime duration = self.playerItem.duration;// 获取视频总长度
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
            _totalTime = [self convertTime:totalSecond];// 转换成播放时间
            [self customVideoSlider:duration];// 自定义UISlider外观
            NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
            [self monitoringPlayback:self.playerItem];// 监听播放状态
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"Time Interval:%f",timeInterval);
        CMTime duration = self.playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self updateVideoSlider:timeInterval / totalDuration];
    }
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
        [self updateVideoSlider:currentSecond];
    }];
}


- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.playerView.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (void)customVideoSlider:(CMTime)duration {
    self.videoSlider.maximumValue = CMTimeGetSeconds(duration);
}

- (IBAction)videoSlierChangeValue:(id)sender {
    UISlider *slider = (UISlider *)sender;
    NSLog(@"value change:%f",slider.value);
    
    if (slider.value == 0.000000) {
        __weak typeof(self) weakSelf = self;
        [self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [weakSelf.playerView.player play];
        }];
    }
}

- (IBAction)videoSlierChangeValueEnd:(id)sender {
    UISlider *slider = (UISlider *)sender;
    NSLog(@"value end:%f",slider.value);
    CMTime changedTime = CMTimeMakeWithSeconds(slider.value, 1);
    
    __weak typeof(self) weakSelf = self;
    [self.playerView.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        [weakSelf.playerView.player play];
    }];
}

- (void)updateVideoSlider:(CGFloat)currentSecond {
    [self.videoSlider setValue:currentSecond animated:YES];
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"Play end");
    
    __weak typeof(self) weakSelf = self;
    [self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.videoSlider setValue:0.0 animated:YES];
    }];
}

- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
}


- (IBAction)play:sender {
    [self.player play];
    self.playControlButton.hidden = YES;
    self.pauseControlButton.hidden = NO;
}

- (IBAction)pause:sender {
    [self.player pause];
    self.playControlButton.hidden = NO;
    self.pauseControlButton.hidden = YES;
}

@end
