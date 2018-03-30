//
//  Separator.m
//  My Outlook
//
//  Created by Mukhtar Yusuf on 2/12/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SeparatorView.h"

@interface SeparatorView()

@end

@implementation SeparatorView

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self)
        self.backgroundColor = [UIColor lightGrayColor];
    
    return self;
}

@end
