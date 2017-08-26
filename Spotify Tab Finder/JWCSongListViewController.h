//
//  JWCPlayListViewController.h
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/29/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <SpotifyMetadata/SpotifyMetadata.h>
#import <SpotifyAuthentication/SpotifyAuthentication.h>

@interface JWCSongListViewController : UIViewController

@property (nonatomic, strong) SPTAuth *auth;
@property (nonatomic, strong) SPTPartialPlaylist *partialPlaylist;

@end
