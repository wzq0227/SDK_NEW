//
//  APPVersionModel.h
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/8/4.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APPVersionModel : NSObject

@property (nonatomic,copy)NSString *AppName;
@property (nonatomic,copy)NSString *PackageName;
@property (nonatomic,copy)NSString *PackageUrl;
@property (nonatomic,copy)NSString *UpdateDes;
@property (nonatomic,copy)NSString *VersionName;
@property (nonatomic,assign)NSUInteger VersionNumber;

@end
