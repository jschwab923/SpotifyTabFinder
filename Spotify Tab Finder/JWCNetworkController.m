//
//  JWCNetworkController.m
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 11/27/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "JWCNetworkController.h"

static NSString *kXpathURL = @"https://polar-reef-19318.herokuapp.com/xpath";

@implementation JWCNetworkController

+ (JWCNetworkController *)sharedController
{
    static JWCNetworkController *sharedController = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedController = [[self alloc] init];
    });
    
    return sharedController;
}

- (void)getXPath
{
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    
    AFHTTPSessionManager *httpManager = [AFHTTPSessionManager manager];
    httpManager.securityPolicy = policy;
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"xpath"];
    
    [httpManager GET:kXpathURL parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"Succes: %@", (NSDictionary *)responseObject[@"xpath"]);
        [[NSUserDefaults standardUserDefaults] setObject:responseObject[@"xpath"] forKey:@"xpath"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"xpathUpdated" object:nil userInfo:@{@"xpath":responseObject[@"xpath"]}];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Failure: %@", error);
    }];
    
}

@end
