//
//  SelectedBGView.m
//  My Outlook
//
//  Created by Mukhtar Yusuf on 2/13/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "SelectedBGView.h"

@interface SelectedBGView()
@end

@implementation SelectedBGView

-(void)drawRect:(CGRect)rect{
    CGFloat offsetRatio = 0.15; //Offset in terms of ratio of rect size. Assumes rect is always a square
    CGFloat offset = offsetRatio * rect.size.width;
    CGRect offsetRect = CGRectMake(rect.origin.x + offset, rect.origin.y + offset, rect.size.width-(offset*2), rect.size.height-(offset*2));
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:offsetRect];
    
    [[UIColor blueColor] setFill];
    [path fill];
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self)
        self.backgroundColor = [UIColor clearColor];
    
    return self;
}

@end
