//
//  JWCPlayListViewController.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/29/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "TFHpple.h"

#import "JWCSongListViewController.h"
#import "JWCTabLinkListViewController.h"

#import "UIColor+JWCColors.h"

@interface JWCSongListViewController ()

@property (strong, nonatomic) IBOutlet UITableView *songTableView;
@property (strong, nonatomic) NSDictionary *tracksAndTabs;

@property (nonatomic, strong) SPTPlaylistSnapshot *playlist;
@property (nonatomic, strong) SPTListPage *currentPage;

@property (nonatomic, strong) NSMutableDictionary *tabLinks;
@property (nonatomic, strong) NSArray *selectedTabLinks;

@end

@implementation JWCSongListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.songTableView.backgroundColor = [UIColor gunMetal];
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
    return self.playlist.firstTrackPage.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SongCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    SPTPartialTrack *track = self.currentPage.items[indexPath.row];
    NSArray *tabLinks = [self.tabLinks objectForKey:track.name];
    NSString *tabsAvailable;
    if (tabLinks.count) {
        tabsAvailable = [NSString stringWithFormat:@"| Tabs:%lu", (unsigned long)tabLinks.count];
    }
    
    cell.backgroundColor = tableView.backgroundColor;
    
    cell.textLabel.textColor = [UIColor tealBlue];
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@", track.name, tabsAvailable ?: @""];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SPTPartialTrack *track = self.currentPage.items[indexPath.row];
    if ([[self.tabLinks objectForKey:track.name] count]) {
        self.selectedTabLinks = [self.tabLinks objectForKey:track.name];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TabLinkSegue"]) {
        JWCTabLinkListViewController *tabViewController = segue.destinationViewController;
        tabViewController.tablinks = self.selectedTabLinks;
    }
}

@end
