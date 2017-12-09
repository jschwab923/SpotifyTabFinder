//
//  JWCTabLinkListViewController.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/30/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "JWCTabLinkListViewController.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <FaceAware/FaceAware-Swift.h>

#import "JWCTitleTableViewCell.h"

#import "UIColor+JWCColors.h"

@interface JWCTabLinkListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tabLinksTableView;
@property (weak, nonatomic) IBOutlet UIImageView *headerImageView;

@end

@implementation JWCTabLinkListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.headerImageView sd_setImageWithURL:self.selectedTrack.album.largestCover.imageURL completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            self.headerImageView.debugFaceAware = YES;
            self.headerImageView.focusOnFaces = YES;
        });
        
    }];
    
    [self.tabLinksTableView registerNib:[UINib nibWithNibName:@"JWCTitleTableViewCell" bundle:nil] forCellReuseIdentifier:@"TitleCell"];

    self.tabLinksTableView.backgroundColor = [UIColor blackColor];
    self.tabLinksTableView.separatorColor = [UIColor grayBlue];
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@ Tabs", self.selectedTrack.name];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tablinks.count;
}

- (JWCTitleTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"TitleCell";
    JWCTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.cellLabel.backgroundColor = tableView.backgroundColor;
    cell.cellLabel.text = [NSString stringWithFormat:@"  %@", self.tablinks[indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.tablinks[indexPath.row]] options:@{} completionHandler:^(BOOL success) {
        
    }];
}

@end
