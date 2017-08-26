//
//  JWCAuthManager.h
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 8/25/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpotifyAuthentication/SpotifyAuthentication.h>

@protocol JWCAuthDelegate <NSObject>
@optional

- (void)authDelegateDidLogin;

@end


@interface JWCAuthManager : NSObject

@property (nonatomic, unsafe_unretained) id<JWCAuthDelegate> delegate;

@property (nonatomic, strong) SPTAuth *auth;
@property (nonatomic, strong) UIViewController *authViewController;

+ (JWCAuthManager *)sharedAuthManager;
- (void)loginFromViewController:(UIViewController *)viewController;

@end
