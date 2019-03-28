//
//  UILabel+GosLayoutAdd.h
//  ULife3.5
//
//  Created by Goscam on 2017/11/16.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (GosLayoutAdd)

- (void)setLinespacing:(float)spacing;

- (void)insertImage:(UIImage*)image atIndex:(NSUInteger)index bounds:(CGRect)bounds;

@end
