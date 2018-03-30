//
//  UnderlineView.m
//  My Outlook
//
//  Created by Mukhtar Yusuf on 2/12/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import "UnderlineView.h"

@interface UnderlineView()
@end

@implementation UnderlineView

-(void)drawRect:(CGRect)rect{
    UIBezierPath *linePath = [[UIBezierPath alloc] init];
    
    CGPoint startOfLine = CGPointMake(rect.origin.x, rect.origin.y+rect.size.height);
    CGPoint endOfLine = CGPointMake(rect.origin.x+rect.size.width, rect.origin.y+rect.size.height);
    [linePath moveToPoint:startOfLine];
    [linePath addLineToPoint:endOfLine];
    
    [[UIColor lightGrayColor] setStroke];
    [linePath stroke];
}

-(void)awakeFromNib{
    [super awakeFromNib];
}

@end
