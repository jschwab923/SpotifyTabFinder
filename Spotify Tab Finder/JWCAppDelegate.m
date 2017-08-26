//
//  AppDelegate.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/29/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "JWCAppDelegate.h"

@interface JWCAppDelegate ()

@property (nonatomic, strong) UIViewController *authViewController;

@end

@implementation JWCAppDelegate

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options
{
    // Close the authentication window
    [self.authViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.authViewController = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SpotifyLoggedIn"
                                                        object:nil
                                                      userInfo:@{@"loginURL":url}];
    return YES;
}

@end
