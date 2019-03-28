//
//  CaiyiInterface.m
//  QQI
//
//  Created by goscam on 16/7/15.
//  Copyright © 2016年 yuanx. All rights reserved.
//

#import "CaiyiInterface.h"
#import "HttpTool.h"


@interface CaiyiInterface()
@property(nonatomic,strong)NSString *secretKey;
@property(nonatomic,strong)BlockSuccess resultSuccess;
@property(nonatomic,strong)BlockQueryList Querylist;
@end
@implementation CaiyiInterface

+(CaiyiInterface *)sharedInstance
{
    static CaiyiInterface *g_caiyiInterface = nil;
    static dispatch_once_t token;
    if(g_caiyiInterface == nil)
    {
        dispatch_once(&token,^{
            g_caiyiInterface = [[CaiyiInterface alloc] init];}
                      );
    }
    return g_caiyiInterface;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.secretKey = nil;
    }
    return self;
}

-(void)addSecretKey:(NSString *)secretKey
{
    self.secretKey = secretKey;
}

-(BOOL)getSecretKeyState
{
    if (self.secretKey == nil) {
        return NO;
    }
    return YES;
}


-(void)AddCamera:(NSString *)UID and:(NSString *)deviceName andBlock:(BlockSuccess)result
{
    NSString *serverUrl = @"http://www.a371369.cn/";
    NSString *fileName = @"svc_camera.php";
    NSMutableString *path = [[NSMutableString alloc] init];
    [path appendFormat:@"%@%@?eventID=add.camera", serverUrl, fileName];
    
    NSDictionary *params = @{@"secretKey":self.secretKey,@"id":UID,@"name":deviceName};
    
    [HttpTool postWithPath:path params:params timeout:10 success:^(id obj) {
        result(YES,nil);
       // [self showContentView:[NSString stringWithFormat:@"新增成功：\n\n id:%@      name:%@",_addIDLbl.text,_addNameLbl.text]];
    } failure:^(NSInteger code, NSString *err_msg) {
        if (err_msg == nil)
        {
            result(NO,nil);
        }
        else
        {
            result(NO,err_msg);
        }
    }];

}

-(void)queryCamera:(BlockQueryList)result
{
    NSString *serverUrl = @"http://www.a371369.cn/";
    NSString *fileName = @"svc_camera.php";
    NSMutableString *path = [[NSMutableString alloc] init];
    [path appendFormat:@"%@%@?eventID=query.camera", serverUrl, fileName];
    
    NSDictionary *params = @{@"secretKey":self.secretKey};
    
    NSMutableArray *array = [[NSMutableArray alloc]init];
    [HttpTool postWithPath:path params:params timeout:10 success:^(id obj) {
        NSArray *listArr = [obj objectForKey:@"camera_list"];
        for (NSInteger i = 0; i < listArr.count; i++)
        {
            NSDictionary *cameraDic = listArr[i];
            NSString *UID = cameraDic[@"id"];
            UID = [UID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([UID length] != 20) {
                continue;
            }
            NSString *b = [UID substringFromIndex:16];
            if (![b isEqualToString:@"111A"]) {
                continue;
            }
//            DeviceModel *model = [[DeviceModel alloc]init];
//            model.uid = cameraDic[@"id"];
//            model.nikeName = cameraDic[@"name"];
//            model.password = @"goscam123";
//            [array addObject:model];
        }
        result(YES,array,nil);
    } failure:^(NSInteger code, NSString *err_msg) {
        NSLog(@"err_msg = %@",err_msg);
        if (err_msg == nil)
        {
            result(NO,nil,nil);
        }
        else
        {
            result(NO,nil,err_msg);
        }
    }];

}

-(void)editCamera:(NSString *)UID and:(NSString *)deviceName andBlock:(BlockSuccess)result
{
    NSString *serverUrl = @"http://www.a371369.cn/";
    NSString *fileName = @"svc_camera.php";
    NSMutableString *path = [[NSMutableString alloc] init];
    [path appendFormat:@"%@%@?eventID=edit.camera", serverUrl, fileName];

    NSDictionary *params = @{@"secretKey":self.secretKey,@"id":UID,@"name":deviceName};
    
    [HttpTool postWithPath:path params:params timeout:10 success:^(id obj) {
        result(YES,nil);
    } failure:^(NSInteger code, NSString *err_msg) {
        if (err_msg == nil)
        {
            result(NO,nil);
        }
        else
        {
            result(NO,err_msg);
        }
    }];

}

-(void)authCamera:(NSString *)UID andBlock:(BlockSuccess)result
{
    NSString *serverUrl = @"http://www.a371369.cn/";
    NSString *fileName = @"svc_camera.php";
    NSMutableString *path = [[NSMutableString alloc] init];
    [path appendFormat:@"%@%@?eventID=auth.camera", serverUrl, fileName];
    
    NSDictionary *params = @{@"secretKey":self.secretKey,@"id":UID};
    
    [HttpTool postWithPath:path params:params timeout:10 success:^(id obj) {
        result(YES,nil);
    } failure:^(NSInteger code, NSString *err_msg) {
        if (err_msg == nil)
        {
            result(NO,nil);
        }
        else
        {
            result(YES,nil);
        }
    }];

}

-(void)deleteCamera:(NSString *)UID andBlock:(BlockSuccess)result
{
    NSString *serverUrl = @"http://www.a371369.cn/";
    NSString *fileName = @"svc_camera.php";
    NSMutableString *path = [[NSMutableString alloc] init];
    [path appendFormat:@"%@%@?eventID=del.camera", serverUrl, fileName];

    NSDictionary *params = @{@"secretKey":self.secretKey,@"id":UID};
    
    [HttpTool postWithPath:path params:params timeout:10 success:^(id obj) {
        result(YES,nil);
    } failure:^(NSInteger code, NSString *err_msg) {
        NSLog(@"deleteCamera error =%@",err_msg);
        if (err_msg == nil)
        {
            result(NO,nil);
        }
        else
        {
            result(NO,err_msg);
        }
    }];

}
@end
