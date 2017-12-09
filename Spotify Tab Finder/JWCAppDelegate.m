//
//  AppDelegate.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 5/29/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import "JWCAppDelegate.h"

#import "JWCNetworkController.h"

#import "UIColor+JWCColors.h"

@interface JWCAppDelegate ()

@property (nonatomic, strong) UIViewController *authViewController;

@end

@implementation JWCAppDelegate

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setBarTintColor:[UIColor colorWithWhite:0 alpha:0.6]];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithWhite:0 alpha:0.6]];
    
    [[JWCNetworkController sharedController] getXPath];
}

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
