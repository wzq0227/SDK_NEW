//
//  AddDeviceManager.m
//  ULife3.5
//
//  Created by Goscam on 2018/5/18.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "AddDeviceManager.h"

#import "NetSDK.h"
#import "CBSCommand.h"
#import "iRouterInterface.h"

@interface AddDeviceManager()
{}
//@property (strong, nonatomic)

@end


@implementation AddDeviceManager
ShareToOthersBlock shareBlock;



+ (void)shareDevice:(DeviceDataModel *)devModel toOthers:(NSString *)userName result:(ShareToOthersBlock)shareResultBlock{
    
    shareBlock = shareResultBlock;
    
    [self addSharefindDevciceState:devModel username:userName];
}

+ (void)addSharefindDevciceState:(DeviceDataModel*)devModel username:(NSString*)username
{
    
    __weak typeof(self) weakSelf = self;
    
    CBS_QueryBindRequest *req = [CBS_QueryBindRequest new];
    BodyQueryBindRequest *body = [BodyQueryBindRequest new];
    body.DeviceId = devModel.DeviceId;
    body.UserName = username;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
            
            if(result == IROUTER_DEVICE_NOT_EXIST){
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Device_Not_Exist")];
                });
            }
            else if (result !=0) {
                dispatch_async(dispatch_get_main_queue(),^{
                    [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                });
            }
            else {
                
                NSString * ret = dict[@"Body"][@"BindStatus"];
                
                switch (ret.integerValue)
                {
                        
                    case 0:   // 未绑定IROUTER_DEVICE_BIND_NOEXIST
                    {
                        
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            [SVProgressHUD dismiss];
                            //                            weakSelf.MyDeviceIdTextField.text=UID;
                            [weakSelf addFriendShareWithDevModel: devModel username:username];
                        });
                    }
                        break;
                        
                    case 1:    // 已被本账号以拥有方式绑定 IROUTER_DEVICE_BIND_DUPLICATED
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_we_bind")];
                            //                            weakSelf.MyDeviceIdTextField.text=@"";
                        });
                    }
                        break;
                    case 2:    // 已被本账号以分享方式绑定
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Already_Added")];
                            //                            weakSelf.MyDeviceIdTextField.text=@"";
                        });
                    }
                        break;
                        
                    case 3:     // 被其他账号绑定 IROUTER_DEVICE_BIND_INUSE
                    {
                        dispatch_async(dispatch_get_main_queue(),^{
                            
                            [SVProgressHUD dismiss];
                            //                            weakSelf.MyDeviceIdTextField.text=UID;
                            [weakSelf addFriendShareWithDevModel: devModel username:username];
                        });
                    }
                        break;
                    default:
                        dispatch_async(dispatch_get_main_queue(),^{
                            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                        });
                        break;
                }
            }
        }];
    });
}


+ (void)addFriendShareWithDevModel:(DeviceDataModel*)devModel username:(NSString*)username{
    
    NSString *password = @"goscam123";
    CBS_BindRequest *req = [CBS_BindRequest new];
    BodyBindRequest *body = [BodyBindRequest new];
    body.DeviceId = devModel.DeviceId;
    body.DeviceName = @"";
    body.DeviceType = devModel.DeviceType;
    body.DeviceOwner = 0;
    body.AreaId  = @"000001";
    body.StreamUser = @"admin";
    body.UserName = username;
    body.StreamPassword = password;
//    [SVProgressHUD showWithStatus:@"loading....."];
    
    if ([body.DeviceId hasPrefix:@"A"]) {
        
        if ( isENVersionNew) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportEN")];
            //            self.MyDeviceIdTextField.text = @"";
            //中文版
            return;
        }
        
    }
    else if ([body.DeviceId hasPrefix:@"Z"]){
        //英文版
        if (! isENVersionNew) {
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportCN")];
            //            self.MyDeviceIdTextField.text = @"";
            //中文版
            return;
        }
    }
    else{
        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"DeviceSupportNO")];
        //        self.MyDeviceIdTextField.text = @"";
        //不支持
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:10000 responseBlock:^(int result, NSDictionary *dict) {
            
            if (result == 0) {
                !shareBlock?:shareBlock(result);
            }else{
                dispatch_async_on_main_queue(^{
                    if (result ==  IROUTER_USER_NOEXIST){
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_AccountDoesNotExist")];
                    }
                    else if (result == IROUTER_DEVICE_NOT_EXIST){
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Device_Not_Exist")];
                    }
                    else{
                        [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Login_NetworkRequestTimeout")];
                    }
                });
            }
        }];
    });
}


@end
