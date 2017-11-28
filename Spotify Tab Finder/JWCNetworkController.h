//
//  JWCNetworkController.h
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 11/27/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWCNetworkController : NSObject

+ (JWCNetworkController *)sharedController;

- (void)getXPath;

@end
