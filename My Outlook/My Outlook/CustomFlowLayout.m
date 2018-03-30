//
//  CustomFlowLayout.m
//  My Outlook
//
//  Created by Mukhtar Yusuf on 2/12/17.
//  Copyright © 2017 Mukhtar Yusuf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CustomFlowLayout.h"

@interface CustomFlowLayout()
@end

@implementation CustomFlowLayout

//Trying to implement separator lines
-(NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    return [super layoutAttributesForElementsInRect:rect];
//    NSArray *layoutAttributes = [super layoutAttributesForElementsInRect:rect];
//    NSMutableArray *separatorLayoutAttributes = [[NSMutableArray alloc] initWithCapacity:[layoutAttributes count]];
//    
//    for(UICollectionViewLayoutAttributes *attributes in layoutAttributes){
//        NSIndexPath *indexPath = attributes.indexPath;
//        if(indexPath.item > 0){
//            CGRect cellFrame = attributes.frame;
//            
//            UICollectionViewLayoutAttributes *separatorAttributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:@"SeparatorView" withIndexPath:indexPath];
//            
//            separatorAttributes.frame = CGRectMake(cellFrame.origin.x, cellFrame.origin.y+cellFrame.size.height, cellFrame.size.width, 0.0);
//            [separatorLayoutAttributes addObject:separatorAttributes];
//        }
//    }
//    return [layoutAttributes arrayByAddingObjectsFromArray:separatorLayoutAttributes];
}

@end
