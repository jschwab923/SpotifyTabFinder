//
//  JWCTabLinkListViewController.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/30/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "JWCTabLinkListViewController.h"

@interface JWCTabLinkListViewController ()

@end

@implementation JWCTabLinkListViewController

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tablinks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"TabLinkCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", self.tablinks[indexPath.row]];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.tablinks[indexPath.row]] options:@{} completionHandler:^(BOOL success) {
        
    }];
}

@end