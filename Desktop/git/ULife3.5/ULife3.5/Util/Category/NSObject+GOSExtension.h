//
//  NSObject+GOSExtension.h
//  ULife3.5
//
//  Created by Goscam on 2018/6/22.
//  Copyright © 2018 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (GOSExtension)

- (void)setInteger:(NSInteger)intValue forKey:(nonnull NSString *)defaultName;

- (NSInteger)integerForKey:(NSString *)defaultName;


@end

NS_ASSUME_NONNULL_END
