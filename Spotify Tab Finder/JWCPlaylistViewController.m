//
//  ViewController.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/29/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "JWCPlaylistViewController.h"
#import "JWCSongListViewController.h"

#import <SpotifyMetadata/SpotifyMetadata.h>

#import "JWCAuthManager.h"

#import "UIColor+JWCColors.h"

@interface JWCPlaylistViewController () <UIScrollViewDelegate, JWCAuthDelegate>

@property (strong, nonatomic) IBOutlet UITableView *playlistsTableView;

@property (nonatomic, strong) SPTAuth *auth;
@property (nonatomic, strong) SPTPlaylistList *playlists;
@property (nonatomic, strong) SPTListPage *currentPage;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation JWCPlaylistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playlistsTableView.backgroundColor = [UIColor gunMetal];
    self.playlistsTableView.separatorColor = [UIColor grayBlue];
    
    [self getListOfPlaylists];
    
    [self login];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SpotifyLoggedIn" object:nil];
}

- (void)login
{
    [JWCAuthManager sharedAuthManager].delegate = self;
    [[JWCAuthManager sharedAuthManager] loginFromViewController:self];
}

- (void)authDelegateDidLogin
{
    self.auth = [JWCAuthManager sharedAuthManager].auth;
    [self getListOfPlaylists];
}

- (void)getListOfPlaylists
{
    [SPTPlaylistList playlistsForUser:self.auth.session.canonicalUsername withAccessToken:self.auth.session.accessToken callback:^(NSError *error, id object) {
        
        if ([object isKindOfClass:[SPTPlaylistList class]]) {
            self.playlists = (SPTPlaylistList *)object;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.playlistsTableView reloadData];
        });
        
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.playlistsTableView deselectRowAtIndexPath:indexPath animated:NO];
    
    self.selectedIndexPath = indexPath;
    [self performSegueWithIdentifier:@"SongListSegue" sender:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.playlists.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PlaylistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSArray *items =  self.playlists.items;
    SPTPartialPlaylist *playlist = [items objectAtIndex:indexPath.row];
    
    cell.backgroundColor = tableView.backgroundColor;
    
    cell.textLabel.textColor = [UIColor tealBlue];
    cell.textLabel.text = [NSString stringWithFormat:@"%@\nTrack Count:%lu", playlist.name, (unsigned long)playlist.trackCount];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SongListSegue"]) {
        JWCSongListViewController *songListVC = segue.destinationViewController;
        songListVC.auth = self.auth;
        songListVC.partialPlaylist = self.playlists.items[self.selectedIndexPath.row];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.playlists.hasNextPage) {
        CGPoint offset = scrollView.contentOffset;
        CGRect bounds = scrollView.bounds;
        CGSize size = scrollView.contentSize;
        UIEdgeInsets inset = scrollView.contentInset;
        float y = offset.y + bounds.size.height - inset.bottom;
        float h = size.height;
        
        float reload_distance = 10;
        if (y > h + reload_distance) {
            [self.playlists requestNextPageWithAccessToken:self.auth.session.accessToken callback:^(NSError *error, id object) {
                
                if ([object isKindOfClass:[SPTListPage class]]) {
                    self.playlists = [self.playlists pageByAppendingPage:object];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.playlistsTableView reloadData];
                });


            }];
        }
    }
}

@end
