//
//  JWCPlayListViewController.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/29/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "TFHpple.h"

#import <SDWebImage/UIImageView+WebCache.h>

#import "JWCSongListViewController.h"
#import "JWCTabLinkListViewController.h"

#import "JWCTitleTableViewCell.h"

#import "UIColor+JWCColors.h"

@interface JWCSongListViewController () <UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView *songTableView;
@property (strong, nonatomic) NSDictionary *tracksAndTabs;

@property (nonatomic, strong) SPTPlaylistSnapshot *playlist;
@property (nonatomic, strong) SPTListPage *currentPage;

@property (nonatomic, strong) NSMutableDictionary *tabLinks;
@property (nonatomic, strong) SPTPartialTrack *selectedTrack;
@property (nonatomic, strong) NSArray *selectedTabLinks;

@property (nonatomic, strong) NSArray *items;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation JWCSongListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.songTableView registerNib:[UINib nibWithNibName:@"JWCTitleTableViewCell" bundle:nil] forCellReuseIdentifier:@"TitleCell"];
    
    self.songTableView.backgroundColor = [UIColor blackColor];
    self.songTableView.separatorColor = [UIColor grayBlue];
    
    for (SPTPartialTrack *track in self.currentPage.items) {
        if ([[self.tabLinks objectForKey:track.name] count]) {
            self.selectedTabLinks = [self.tabLinks objectForKey:track.name];
            [self performSegueWithIdentifier:@"TabLinkSegue" sender:self];
        } else {
            [self searchForTabsForTrack:track];
        }
    }
}

- (NSDictionary *)tabLinks
{
    if (!_tabLinks) {
        _tabLinks = [NSMutableDictionary new];
    }
    return _tabLinks;
}

- (void)setCurrentPage:(SPTListPage *)currentPage
{
    _currentPage = currentPage;
    if (currentPage && self.searchBar.text.length) {
        self.items = [currentPage.items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name CONTAINS %@", self.searchBar.text]];
    } else {
        self.items = currentPage.items;
    }
}

- (void)searchForTabsForTrack:(SPTPartialTrack *)track
{
    if (track) {
        NSString *urlString = [[NSString stringWithFormat:@"https://www.ultimate-guitar.com/search.php?search_type=title&order=&value=%@%@", track.name, [[track.artists valueForKey:@"name"] componentsJoinedByString:@" "]] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

        NSURL *ultimateGuitarURL = [NSURL URLWithString:urlString];
        
        NSMutableURLRequest *ultimateGuitarRequest = [[NSMutableURLRequest alloc] initWithURL:ultimateGuitarURL];
        
        [ultimateGuitarRequest setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/7.0.3 Safari/7046A194A" forHTTPHeaderField:@"User-Agent"];
        
        NSURLSessionDataTask *urlSession = [[NSURLSession sharedSession] dataTaskWithRequest:ultimateGuitarRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
           
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^(void) {
                if (data) {
                    TFHpple *hpple = [TFHpple hppleWithHTMLData:data];
                    
                    NSString *tabSearchXpathQueryString = [[NSUserDefaults standardUserDefaults] objectForKey:@"xpath"];
                    if (!tabSearchXpathQueryString) {
                        tabSearchXpathQueryString = @"//div[@class='content']/table/tr/td[@class='sres']/table[@class='tresults  ']/tr/td/div[a]";
                    }
                    NSArray *searchResultNodes = [hpple searchWithXPathQuery:tabSearchXpathQueryString];
                    
                    NSMutableArray *searchResults = [[NSMutableArray alloc] initWithCapacity:0];
                    for (TFHppleElement *element in searchResultNodes) {
                        TFHppleElement *link = [element firstChildWithTagName:@"a"];
                        NSString *linkURLString = [link objectForKey:@"href"];
                        [searchResults addObject:linkURLString];
                    }
                    [self.tabLinks setValue:searchResults forKey:track.name];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self.songTableView reloadData];
                    });
                }
            });
        }];
        
        [urlSession resume];
    }
}

- (void)setPartialPlaylist:(SPTPartialPlaylist *)partialPlaylist
{
    _partialPlaylist = partialPlaylist;
    [SPTPlaylistSnapshot playlistWithURI:partialPlaylist.uri accessToken:self.auth.session.accessToken callback:^(NSError *error, id object) {
       
        if ([object isKindOfClass:[SPTPlaylistSnapshot class]]) {
            self.playlist = (SPTPlaylistSnapshot *)object;
            self.currentPage = self.playlist.firstTrackPage;
        }
        
        for (SPTPartialTrack *track in self.currentPage.items) {
            [self searchForTabsForTrack:track];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.songTableView reloadData];
        });

    }];
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

- (JWCTitleTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"TitleCell";
    
    JWCTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = tableView.backgroundColor;
    
    SPTPartialTrack *track = self.items[indexPath.row];
    [cell.cellImageView sd_setImageWithURL:track.album.largestCover.imageURL];
    
    NSArray *tabLinks = [self.tabLinks objectForKey:track.name];
    NSString *tabsAvailable;
    if (tabLinks.count) {
        tabsAvailable = [NSString stringWithFormat:@"| Tabs:%lu", (unsigned long)tabLinks.count];
    }
    
    cell.cellLabel.text = [NSString stringWithFormat:@"  %@%@", track.name, tabsAvailable ?: @""];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SPTPartialTrack *track = self.items[indexPath.row];
    if ([[self.tabLinks objectForKey:track.name] count]) {
        self.selectedTabLinks = [self.tabLinks objectForKey:track.name];
        self.selectedTrack = track;
        [self performSegueWithIdentifier:@"TabLinkSegue" sender:self];
    } else {
        [self searchForTabsForTrack:track];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.currentPage.hasNextPage) {
        CGPoint offset = scrollView.contentOffset;
        CGRect bounds = scrollView.bounds;
        CGSize size = scrollView.contentSize;
        UIEdgeInsets inset = scrollView.contentInset;
        float y = offset.y + bounds.size.height - inset.bottom;
        float h = size.height;
        
        float reload_distance = 10;
        if (y > h + reload_distance) {
            if (self.currentPage.hasNextPage) {
                [self.playlist.firstTrackPage requestNextPageWithAccessToken:self.auth.session.accessToken callback:^(NSError *error, id object) {
                   
                    if ([object isKindOfClass:[SPTListPage class]]) {
                        self.currentPage = [self.currentPage pageByAppendingPage:object];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self.songTableView reloadData];
                    });
                }];
            }
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TabLinkSegue"]) {
        JWCTabLinkListViewController *tabViewController = segue.destinationViewController;
        tabViewController.selectedTrack = self.selectedTrack;
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText
{
    [SPTSearch performSearchWithQuery:searchText queryType:SPTQueryTypeTrack accessToken:self.auth.session.accessToken callback:^(NSError *error, SPTListPage *object) {
        
        if (!error && [object isKindOfClass: [SPTListPage class]]) {
            self.items = object.items;
            [self.songTableView reloadData];
        }
        
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.items = self.currentPage.items;
    [self.songTableView reloadData];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}


@end
