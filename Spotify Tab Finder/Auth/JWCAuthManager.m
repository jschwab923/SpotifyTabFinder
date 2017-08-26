//
//  JWCAuthManager.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 8/25/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "JWCAuthManager.h"
#import <SafariServices/SafariServices.h>

@interface JWCAuthManager ()

@property (nonatomic, weak) UIViewController *viewController;

@end

@implementation JWCAuthManager

+ (JWCAuthManager *)sharedAuthManager
{
    static JWCAuthManager *sharedAuthManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedAuthManager = [[self alloc] init];
    });
    
    return sharedAuthManager;
}

- (void)loginFromViewController:(UIViewController *)viewController
{
    self.viewController = viewController;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spotifyLoggedIn:) name:@"SpotifyLoggedIn" object:nil];
    
    self.auth = [SPTAuth defaultInstance];
    self.auth.clientID = @"772156b6c56c42598e759ba4e10a4085";
    self.auth.redirectURL = [NSURL URLWithString:@"TabFinder://login"];
    self.auth.sessionUserDefaultsKey = @"current session";
    self.auth.requestedScopes = @[SPTAuthStreamingScope,
                                  SPTAuthUserReadPrivateScope,
                                  SPTAuthUserLibraryReadScope,
                                  SPTAuthPlaylistReadCollaborativeScope];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *authURL = [self.auth spotifyWebAuthenticationURL];
        self.authViewController = [[SFSafariViewController alloc] initWithURL:authURL];
        [viewController presentViewController:self.authViewController animated:YES completion:nil];
    });
}

- (void)spotifyLoggedIn:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SpotifyLoggedIn" object:nil];
    
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    
    NSURL *loginURL = notification.userInfo[@"loginURL"];
    [self.auth handleAuthCallbackWithTriggeredAuthURL:loginURL callback:^(NSError *error, SPTSession *session) {
        if ([self.delegate respondsToSelector:@selector(authDelegateDidLogin)]) {
            [self.delegate authDelegateDidLogin];
        }
    }];
}

@end
