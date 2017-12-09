//
//  JWCSongsViewController.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 8/25/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "JWCSongsViewController.h"

#import <SpotifyMetadata/SpotifyMetadata.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "TFHpple.h"

#import "JWCAuthManager.h"

#import "JWCTitleTableViewCell.h"

#import "JWCTabLinkListViewController.h"

#import "UIColor+JWCColors.h"

@interface JWCSongsViewController () <UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView *songsTableView;

@property (nonatomic, strong) SPTAuth *auth;
@property (nonatomic, strong) SPTListPage *currentPage;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, strong) NSMutableDictionary *tabLinks;
@property (nonatomic, strong) NSArray *selectedTabLinks;
@property (nonatomic, strong) SPTPartialTrack *selectedTrack;

@property (nonatomic, strong) NSArray *items;

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@property (nonatomic, strong) NSOperationQueue *tabSearchQueue;
@property (nonatomic, strong) NSMutableDictionary *inflightOperations;

@end

@implementation JWCSongsViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.songsTableView registerNib:[UINib nibWithNibName:@"JWCTitleTableViewCell" bundle:nil] forCellReuseIdentifier:@"TitleCell"];
    
    self.auth = [JWCAuthManager sharedAuthManager].auth;
    [self loadSongs];
    
    self.songsTableView.backgroundColor = [UIColor blackColor];
    self.songsTableView.separatorColor = [UIColor grayBlue];
    
    self.tabSearchQueue = [NSOperationQueue new];
    self.inflightOperations = [NSMutableDictionary new];
}

- (void)loadSongs
{
    [SPTYourMusic savedTracksForUserWithAccessToken:self.auth.session.accessToken callback:^(NSError *error, id object) {
       
        if ([object isKindOfClass:[SPTListPage class]]) {
            self.currentPage = (SPTListPage *)object;
            self.items = self.currentPage.items;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.songsTableView reloadData];
        });

    }];
}

- (NSDictionary *)tabLinks
{
    if (!_tabLinks) {
        _tabLinks = [NSMutableDictionary new];
    }
    return _tabLinks;
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

- (JWCTitleTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"TitleCell";
    
    JWCTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.backgroundColor = tableView.backgroundColor;
    
    SPTPartialTrack *track = self.items[indexPath.row];
    [cell.cellImageView sd_setImageWithURL:track.album.largestCover.imageURL];
    
    NSArray *tabLinks = [self.tabLinks objectForKey:track.name];
    NSString *tabsAvailable;
    if (tabLinks.count) {
        tabsAvailable = [NSString stringWithFormat:@" | Tab Count:%lu", (unsigned long)tabLinks.count];
    } else if (!self.inflightOperations[track.name]) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [self searchForTabsForTrack:track];
        }];
        self.inflightOperations[track.name] = operation;
        [self.tabSearchQueue addOperation:operation];
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
                [self.currentPage requestNextPageWithAccessToken:self.auth.session.accessToken callback:^(NSError *error, id object) {
                    
                    if ([object isKindOfClass:[SPTListPage class]]) {
                        self.currentPage = [self.currentPage pageByAppendingPage:object];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self.songsTableView reloadData];
                    });
                }];
            }
        }
    }
}

- (void)setCurrentPage:(SPTListPage *)currentPage
{
    _currentPage = currentPage;
    self.items = currentPage.items;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TabLinkSegue"]) {
        JWCTabLinkListViewController *tabViewController = segue.destinationViewController;
        tabViewController.tablinks = self.selectedTabLinks;
        tabViewController.selectedTrack = self.selectedTrack;
    }
}

- (void)searchForTabsForTrack:(SPTPartialTrack *)track
{
    if (track) {
        NSString *urlString = [[NSString stringWithFormat:@"https://www.ultimate-guitar.com/search.php?search_type=title&order=&value=%@%@", track.name, [[track.artists valueForKey:@"name"] componentsJoinedByString:@" "]] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        NSURL *ultimateGuitarURL = [NSURL URLWithString:urlString];
        
        NSMutableURLRequest *ultimateGuitarRequest = [[NSMutableURLRequest alloc] initWithURL:ultimateGuitarURL];
        
        [ultimateGuitarRequest setValue:@"" forHTTPHeaderField:@"User-Agent"];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSURLSessionDataTask *urlSession = [[NSURLSession sharedSession] dataTaskWithRequest:ultimateGuitarRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^(void) {
                
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                if (data) {
                    TFHpple *hpple = [TFHpple hppleWithHTMLData:data];
                    
                    
                    NSString *tabSearchXpathQueryString = [[NSUserDefaults standardUserDefaults] objectForKey:@"xpath"];
                    if (!tabSearchXpathQueryString) {
                        
                        NSString *tabSearchXpathQueryString = [[NSUserDefaults standardUserDefaults] objectForKey:@"xpath"];
                        if (!tabSearchXpathQueryString) {
                            
                            tabSearchXpathQueryString = @"//div[@class='content']/table/tr/td[@class='sres']/table[@class='tresults  ']/tr/td/div[a]";
                        }
                        
                        NSNotificationCenter * __weak center = [NSNotificationCenter defaultCenter];
                        id __block token = [center addObserverForName:@"xpathUpdated" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                            
                            [center removeObserver:token];
                            
                            [self searchForTabsForTrack:track];
                            
                        }];
                    }
                    
                    NSArray *searchResultNodes = [hpple searchWithXPathQuery:tabSearchXpathQueryString];
                    
                    NSMutableArray *searchResults = [[NSMutableArray alloc] initWithCapacity:0];
                    for (TFHppleElement *element in searchResultNodes) {
                        TFHppleElement *link = [element firstChildWithTagName:@"a"];
                        NSDictionary *nodeAttributes = link.attributes;
                        if (nodeAttributes.count) {
                            NSString *linkURLString = nodeAttributes[@"href"];
                            if (linkURLString) {
                                [searchResults addObject:linkURLString];
                            }
                        }
                    }
                    [self.tabLinks setValue:searchResults forKey:track.name];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self.songsTableView reloadData];
                    });
                    
                }
            });
        }];
        
        [urlSession resume];
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText
{
    [SPTSearch performSearchWithQuery:searchText queryType:SPTQueryTypeTrack accessToken:self.auth.session.accessToken callback:^(NSError *error, SPTListPage *object) {
       
        if (!error && [object isKindOfClass: [SPTListPage class]]) {
            self.items = object.items;
            [self.songsTableView reloadData];
        }
        
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.items = self.currentPage.items;
    [self.songsTableView reloadData];
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

@end
