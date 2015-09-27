//
//  UniversialPlayerTableView.m
//  hw3
//
//  Created by Yingyi Yang on 7/1/15.
//  Copyright (c) 2015 Yingyi Yang. All rights reserved.
//
//  This tab gives a user the access of all his/her pictures and video in camera roll. 

#import "UniversialPlayerTableViewController.h"
#import "AssestViewController.h"

@import Photos;

@interface UniversialPlayerTableViewController ()
@property (strong, nonatomic) PHFetchResult *fetchAlbumsResesult;
@property (strong, nonatomic) PHFetchResult *fetchAssetResesult;
@property (strong, nonatomic) PHAssetCollection *cammeraRollCollection;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation UniversialPlayerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterLongStyle;

}

- (void)viewWillAppear:(BOOL)animated {
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined || [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted ||[PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied){
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                NSLog(@"Authorized.");
                [self fetchPHAssetFromAssetCollection];
            } else {
                NSLog(@"Denied");
            }
        }];
    } else {
        NSLog(@"Authorized.");
        [self fetchPHAssetFromAssetCollection];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchPHAssetFromAssetCollection{
    // Fetch only camera roll by using PHAssetCollectionTypeSmartAlbum and PHAssetCollectionSubtypeSmartAlbumUserLibrary.
    self.fetchAlbumsResesult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    
    // Select camera roll collection from album result.
    self.cammeraRollCollection = [self.fetchAlbumsResesult firstObject]; //won't crash by using firstObject compared to using index. If fetchAlbumsResult is empty, return nil.
    if (!self.cammeraRollCollection) {
        NSLog(@"Collection is nil.");
        return;
    }
    NSLog(@"Fetch camera roll succeed.");
    
    // Fetch all assets, sorted by date created.
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(creationDate)) ascending:NO]];
    self.fetchAssetResesult = [PHAsset fetchAssetsInAssetCollection:self.cammeraRollCollection options:options];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.fetchAssetResesult.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MultimediaCell" forIndexPath:indexPath];
    UIImageView *previewImageView = [[UIImageView alloc] init];
    previewImageView.translatesAutoresizingMaskIntoConstraints = NO;
    previewImageView.contentMode = UIViewContentModeScaleAspectFill;
    previewImageView.clipsToBounds = YES;
    [cell.contentView addSubview:previewImageView];
    NSArray *previewImageViewHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[previewImageView(70)]|"
                                                                                             options:0
                                                                                             metrics:nil
                                                                                               views:NSDictionaryOfVariableBindings(previewImageView)];
    [NSLayoutConstraint activateConstraints:previewImageViewHorizontalConstraints];
    NSArray *previewImageViewVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[previewImageView(70)]"
                                                                                           options:0
                                                                                           metrics:nil
                                                                                             views:NSDictionaryOfVariableBindings(previewImageView)];
    [NSLayoutConstraint activateConstraints:previewImageViewVerticalConstraints];
    PHAsset *asset = self.fetchAssetResesult[indexPath.row];
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:CGSizeMake(70, 70)
                                              contentMode:PHImageContentModeAspectFit
                                                  options:nil
                                            resultHandler:^(UIImage *result, NSDictionary *info) {
                                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                    previewImageView.image = result;
                                                }];
                                            }];
    
    cell.textLabel.text = [self.dateFormatter stringFromDate:asset.creationDate];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // Get the new view controller using [segue destinationViewController].
    AssestViewController *assetviewController = segue.destinationViewController;
    
    // Find the selected indexPath
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    // Find selected asset
    PHAsset *selectedAsset = self.fetchAssetResesult[indexPath.row];
    
    // Pass the selected object to the new view controller.
    assetviewController.asset = selectedAsset;
}


@end
