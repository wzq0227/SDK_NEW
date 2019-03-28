//
//  NSObject+GOSExtension.m
//  ULife3.5
//
//  Created by Goscam on 2018/6/22.
//  Copyright © 2018 GosCam. All rights reserved.
//

#import "NSObject+GOSExtension.h"

@implementation NSObject (GOSExtension)

- (void)setInteger:(NSInteger)intValue forKey:(nonnull NSString *)defaultName{
    [self setValue:@(intValue) forKey:defaultName];
}

- (NSInteger)integerForKey:(NSString *)defaultName{
    return [[self valueForKey:defaultName] intValue];
}


@end
