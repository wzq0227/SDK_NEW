//
//  APPVersionTool.m
//  ULife3.5
//
//  Created by 广东省深圳市 on 2017/8/4.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APPVersionTool.h"
#import "YYModel.h"
#import "CMSCommand.h"
#import "NetSDK.h"
#import "SaveDataModel.h"
#import "APPVersionModel.h"


@interface APPVersionTool ()

@property (nonatomic,strong)APPVersionModel *versionModel;

@end


@implementation APPVersionTool

- (void)checkVersion{
    [self getNewVersionAPP];
}

+(instancetype)shareInstance
{
    static APPVersionTool *tool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (tool == nil) {
            tool = [[APPVersionTool alloc]init];
        }
    });
    return tool;
}



- (void)getNewVersionAPP{
    ServerAddress *upsAddr = [ServerAddress yy_modelWithDictionary:[mUserDefaults objectForKey:@"UPSAddress"]];

    if (!upsAddr) {
        return;
    }
    [self queryVersionFromServerWithIp:upsAddr.Address port:upsAddr.Port];
}


- (void)queryVersionFromServerWithIp:(NSString *)ip port:(int)port{
   NSString *bundid = [NSString stringWithFormat:@"%@.ios",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]];
    
    NSString *appName = [NSString stringWithFormat:@"%@ios",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
    
    NSDictionary *requestDict = @{
                                  @"MessageType":@"GetAppNewestFromUPSRequest",
                                  @"Body":@{@"AppName":appName,
                                            @"PackageName":bundid}
                                  };
    [[NetSDK sharedInstance] net_queryAPPVersionWithIP:ip port:port data:requestDict responseBlock:^(int result, NSDictionary *dict) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            return;
        }
        APPVersionModel *versionModel = [APPVersionModel yy_modelWithDictionary:dict];
        
        if (![versionModel.PackageName isKindOfClass:[NSString class]]) {
            return;
        }
        
        self.versionModel = versionModel;
        NSUInteger version = versionModel.VersionNumber;
        NSString *currentVerStr= [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CustomVersionKey"];
        NSUInteger currentVersion = currentVerStr.integerValue;
        
        if (version > currentVersion) {
            //需要升级  -- 弹窗
            dispatch_async_on_main_queue(^{
                [self showUpdateAlert];
            });
        }
        NSLog(@"%@",versionModel);
    }];
}


- (void)showUpdateAlert{
    UIAlertController *alertView = [UIAlertController alertControllerWithTitle:DPLocalizedString(@"check_update")
                         message:self.versionModel.UpdateDes
                        preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction *updateActin = [UIAlertAction actionWithTitle:DPLocalizedString(@"update_now")
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            [self jumpToAppstore];
                                                        }];
    
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:DPLocalizedString(@"next_time")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                         }];
    [alertView addAction:updateActin];
    [alertView addAction:cancelAction];
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    [vc presentViewController:alertView
                     animated:YES
                   completion:nil];
}


- (void)jumpToAppstore{
    NSString *unencodedString = self.versionModel.PackageUrl;
    NSURL *url = [NSURL URLWithString:unencodedString];
    [[UIApplication sharedApplication] openURL:url];
}

@end
