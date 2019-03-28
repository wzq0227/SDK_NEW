//
//  util.m
//  Walle
//
//  Created by LiChunxia on 14-7-21.
//  Copyright (c) 2014年 LiChunxia. All rights reserved.
//

#import "util.h"
@implementation util
@synthesize result=_result;

//方法实现

+ (instancetype)sharedInstance
{
    static util * g_util = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nil == g_util)
        {
            g_util = [[util alloc] init];
        }
    });
    
    return g_util;
}

//解析Json数据
-(NSDictionary*)analyseJsonWithResponse:(NSData *)response{
    NSError *error2;
    NSDictionary*dic = [[NSDictionary alloc]init];
    dic = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:&error2];
   // NSDictionary *dic = [response objectFromJSONString];
    //NSLog(@"%d",[dic count]);
    NSString *state=[dic objectForKey:@"state"];
    NSLog(@"state is %@",state);
    NSString *err=[dic objectForKey:@"error"];
    NSLog(@"error is %@",err);
    self->error=err;
    NSString *message=[dic objectForKey:@"message"];
    NSLog(@"message is %@",message);
    
    id res=[dic objectForKey:@"result"];
    NSLog(@"result is %@",res);
    NSLog(@"class is %@",[res class]);
    self.result=res;
    if (res==nil) {
        [SVProgressHUD showErrorWithStatus:@"请求超时"];
    }
    return dic;
}

-(void)saveDataWithValidate:(NSString*)validate andName:(NSString*)name andPassword:(NSString*)userPass
               andSessionid:(NSString *)sessionid andEmail:(NSString *)email
                   andaApns:(NSString *)apns_status andLanguage:(NSString *)language
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:validate forKey:@"validate"];
    [userDefaults setObject:name forKey:LAST_LOGIN_USERNAME];
    [userDefaults setObject:userPass forKey:LAST_LOGIN_PASSWORD];
    [userDefaults setObject:sessionid forKey:@"sessionid"];
    [userDefaults setObject:email forKey:@"email"];
    [userDefaults setObject:apns_status forKey:@"apns_status"];
    [userDefaults setObject:language forKey:@"language"];
    //这里建议同步存储到磁盘中，但是不是必须的
    [userDefaults synchronize];
}

-(NSString*) getApnsstatus
{
//    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
//    NSString *apns_status= [defaults objectForKey:@"apns_status"];
    //根据键值取出validate
    NSString *apns_status=EXTRACT_OBJECT(@"apns_status");
    return apns_status;
}
//读取validate数据
-(NSString*) getValidate
{
//    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
//    NSString *validate= [defaults objectForKey:@"validate"];
    NSString *validate= EXTRACT_OBJECT(@"validate");
    //根据键值取出validate
    return validate;
}

//如果是第二次登录，读取之前登录的用户名
-(NSString*) getUsername
{
    NSString *userName=EXTRACT_OBJECT(LAST_LOGIN_USERNAME);
    return userName;
}

//如果是第二次登录，读取之前登录的密码
-(NSString*) getUserpass
{
    NSString *userPass=EXTRACT_OBJECT(LAST_LOGIN_PASSWORD);
    return userPass;
}

-(void)updateSavePassword:(NSString*)userpass{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:userpass forKey:LAST_LOGIN_PASSWORD];
    //这里建议同步存储到磁盘中，但是不是必须的
    [userDefaults synchronize];
}

-(void)SaveUerInfor:(NSString *)userName andPassWord:(NSString *)userPassWord
{
    [[NSUserDefaults standardUserDefaults] setObject:userName forKey:LAST_LOGIN_USERNAME];
    [[NSUserDefaults standardUserDefaults] setObject:userPassWord forKey:LAST_LOGIN_PASSWORD];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)deletePassword
{
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:LAST_LOGIN_PASSWORD];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)deleteUserInfo
{
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:LAST_LOGIN_USERNAME];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:LAST_LOGIN_PASSWORD];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString*) getEmail
{
    NSString *email=EXTRACT_OBJECT(@"email");
    return email;
}


-(NSString *)getError{
    return  error;
}
-(id)getResult{
    return _result;
}


-(void)updateSaveEmail:(NSString*)email{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:email forKey:@"email"];
    //这里建议同步存储到磁盘中，但是不是必须的
    [userDefaults synchronize];
}



- (NSString*)getLoginLanguage{
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSString *language= [defaults objectForKey:@"language"];
    return language;
}

- (NSString*)getCurrentLanguage
{
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    //NSLog( @"currentLanguage:%@" , currentLanguage);
    if ([currentLanguage rangeOfString:@"zh-Hans"].length) {
        currentLanguage=@"zh-cn";
    }
    return currentLanguage;
}

-(BOOL)getUserInfoState
{
    if (EXTRACT_OBJECT(LAST_LOGIN_USERNAME) && EXTRACT_OBJECT(LAST_LOGIN_PASSWORD)) {
        return YES;
    }
    else{
        return NO;
    }
}


-(int)getLogout
{
    NSNumber *number = EXTRACT_OBJECT(@"logout_state");
    if (number == nil)
    {
        return -2;
    }
    int value = [number intValue];
    return value;
}


-(void)saveLogoutAndIndex:(int)index
{
    NSNumber *number = [NSNumber numberWithInt:index];
    [[NSUserDefaults standardUserDefaults] setObject: number
                                              forKey:@"logout_state"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)deleteLogout
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"logout_state"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


-(void)saveDeviceInfo:(NSString *)uid andDeviceName:(NSString *)Device
{
    [[NSUserDefaults standardUserDefaults] setObject:uid forKey:UID_DEFAULT];
    [[NSUserDefaults standardUserDefaults] setObject:Device forKey:DEVICENAME_DEFAULT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)deleteDeviceInfo
{
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:UID_DEFAULT];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:DEVICENAME_DEFAULT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(NSString *)getDeviceUid
{
    NSString *uid = EXTRACT_OBJECT(UID_DEFAULT);
    return uid;
}




-(NSString *)getDeviceName
{
    NSString *deviceName = EXTRACT_OBJECT(DEVICENAME_DEFAULT);
    return deviceName;
}




-(void)saveRing:(NSString *)uid andFlag:(BOOL)flag
{
    
}
-(BOOL)getRing:(NSString*)uid
{
    NSNumber *number = EXTRACT_OBJECT(@"Ring");
    if (number == nil) {
        return NO;
    }
    int value = [number boolValue];
    return value;
}

-(NSString *)getBundleName
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    // app名称
    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    
    return app_Name;
}
@end
