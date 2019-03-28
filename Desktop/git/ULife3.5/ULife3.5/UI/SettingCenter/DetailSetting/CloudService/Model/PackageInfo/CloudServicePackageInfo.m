//
//  CloudServicePackageInfo.m
//  ULife3.5
//
//  Created by Goscam on 2017/9/26.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "CloudServicePackageInfo.h"

@implementation CloudServicePackageInfo

+ (NSString*)packageNameWithPackageType:(PackageType)type{
    NSString *typeStr = @"";
    switch (type) {
        case PackageTypeDays3_Monthly:
        {
            typeStr = DPLocalizedString(@"PackageTypeDays3_Monthly");
            break;
        }
        case PackageTypeDays7_Monthly:
        {
            typeStr = DPLocalizedString(@"PackageTypeDays7_Monthly");
            break;
        }
        case PackageTypeDays30_Monthly:
        {
            typeStr = DPLocalizedString(@"PackageTypeDays30_Monthly");
            break;
        }
        case PackageTypeDays3_Annual:
        {
            typeStr = DPLocalizedString(@"PackageTypeDays3_Annual");
            break;
        }
        case PackageTypeDays7_Annual:
        {
            typeStr = DPLocalizedString(@"PackageTypeDays7_Annual");
            break;
        }
        case PackageTypeDays30_Annual:
        {
            typeStr = DPLocalizedString(@"PackageTypeDays30_Annual");
            break;
        }
        default:
            break;
    }
    return DPLocalizedString(typeStr);
}

@end
