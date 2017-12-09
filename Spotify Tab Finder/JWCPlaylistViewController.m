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
#import <SDWebImage/UIImageView+WebCache.h>

#import "JWCAuthManager.h"

#import "JWCLabelledImageTableViewCell.h"

#import "UIColor+JWCColors.h"

@interface JWCPlaylistViewController () <UIScrollViewDelegate, JWCAuthDelegate, UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView *playlistsTableView;

@property (nonatomic, strong) SPTAuth *auth;
@property (nonatomic, strong) SPTPlaylistList *playlists;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) NSArray *items;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation JWCPlaylistViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    [self.playlistsTableView registerNib:[UINib nibWithNibName:@"JWCLabelledImageTableViewCell" bundle:nil] forCellReuseIdentifier:@"LabelledImageCell"];
    
    self.playlistsTableView.backgroundColor = [UIColor blackColor];
    self.playlistsTableView.separatorColor = [UIColor grayBlue];
    
    [self getListOfPlaylists];
    
    [self login];
}

- (void)setPlaylists:(SPTPlaylistList *)playlists
{
    _playlists = playlists;
    if (_playlists && self.searchBar.text.length) {
        self.items = [playlists.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name CONTAINS %@", self.searchBar.text]];
    } else {
        self.items = playlists.items;
    }
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
    return self.items.count;
}

- (JWCLabelledImageTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"LabelledImageCell";
    JWCLabelledImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = tableView.backgroundColor;
    
    SPTPartialPlaylist *playlist = self.items[indexPath.row];
    SPTImage *playlistImage = [playlist largestImage];
    
    [cell.cellImageView sd_setImageWithURL:playlistImage.imageURL];
    
    cell.cellLabel.numberOfLines = 0;
    cell.cellLabel.text = [NSString stringWithFormat:@"  %@ - %lu songs", playlist.name, (unsigned long)playlist.trackCount];
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SongListSegue"]) {
        JWCSongListViewController *songListVC = segue.destinationViewController;
        songListVC.auth = self.auth;
        songListVC.partialPlaylist = self.items[self.selectedIndexPath.row];
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
            if (self.playlists.hasNextPage) {
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
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText
{
    [SPTSearch performSearchWithQuery:searchText queryType:SPTQueryTypePlaylist accessToken:self.auth.session.accessToken callback:^(NSError *error, SPTListPage *object) {
        
        if (!error && [object isKindOfClass: [SPTListPage class]]) {
            self.items = object.items;
            [self.playlistsTableView reloadData];
        }
        
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.items = self.playlists.items;
    [self.playlistsTableView reloadData];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

@end
