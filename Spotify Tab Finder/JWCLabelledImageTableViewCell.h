//
//  JWCLabelledImageTableViewCell.h
//  Spotify Tab Finder
//
//  Created by Jeff Schwab on 12/7/17.
//  Copyright © 2017 Jeff Writes Code. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWCLabelledImageTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet UILabel *cellLabel;

@end
