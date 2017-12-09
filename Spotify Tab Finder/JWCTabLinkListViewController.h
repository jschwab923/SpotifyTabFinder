//
//  JWCTabLinkListViewController.h
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/30/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpotifyMetadata/SpotifyMetadata.h>


@interface JWCTabLinkListViewController : UIViewController

@property (nonatomic, strong) SPTPartialTrack *selectedTrack;
@property (nonatomic, strong) NSArray *tablinks;

@end
