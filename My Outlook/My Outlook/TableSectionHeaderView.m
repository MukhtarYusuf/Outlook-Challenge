//
//  TableSectionHeaderView.m
//  My Outlook
//
//  Created by Mukhtar Yusuf on 2/13/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "TableSectionHeaderView.h"

@interface TableSectionHeaderView()
@end

@implementation TableSectionHeaderView

-(void)setStrokeColor:(UIColor *)strokeColor{
    _strokeColor = strokeColor;
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect{
    UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
    
    CGPoint topLeftCorner = CGPointMake(rect.origin.x, rect.origin.y);
    CGPoint topRightCorner = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y);
    CGPoint bottomRightCorner = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
    CGPoint bottomLeftCorner = CGPointMake(rect.origin.x, rect.origin.y + rect.size.height);
    
    [bezierPath moveToPoint:topLeftCorner];
    [bezierPath addLineToPoint:topRightCorner];
    
    [bezierPath moveToPoint:bottomLeftCorner];
    [bezierPath addLineToPoint:bottomRightCorner];
    
    bezierPath.lineWidth = 0.2;
    
    [self.strokeColor setStroke];
    [bezierPath stroke];
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        UIColor *backgroundColor = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:255.0/255.0 alpha:1.0];
        self.backgroundColor = backgroundColor;
    }
    
    return self;
}

@end
