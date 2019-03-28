//
//  SDCloudVideoModel.m
//  ULife3.5
//
//  Created by AnDong on 2018/1/5.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "SDCloudVideoModel.h"

@implementation SDCloudVideoModel
- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) return NO;
    
    SDCloudVideoModel *model = object;
    if (model.S == self.S && model.E == self.E) return YES;
    
    return NO;
}
@end
