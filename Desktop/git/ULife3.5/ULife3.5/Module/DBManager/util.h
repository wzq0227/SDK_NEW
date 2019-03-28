//
//  util.h
//  Walle
//
//  Created by LiChunxia on 14-7-21.
//  Copyright (c) 2014年 LiChunxia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface util : NSObject
{
    id  _result;
    NSString* error;
}
+ (id) sharedInstance;
@property(atomic,strong) id result;
@property(nonatomic,assign)BOOL IsDirectlylogin;

-(NSDictionary*)analyseJsonWithResponse:(NSData *)response;
-(void)saveDataWithValidate:(NSString*)validate andName:(NSString*)name andPassword:(NSString*)userPass
               andSessionid:(NSString *)sessionid andEmail:(NSString *)email
                   andaApns:(NSString *)apns_status andLanguage:(NSString *)language;

-(NSString*) getApnsstatus;
-(NSString*) getValidate;
-(NSString *)getError;
-(id)getResult;

#pragma 用户本地保存
-(void)SaveUerInfor:(NSString *)userName andPassWord: (NSString *)userPassWord;
-(BOOL)getUserInfoState;
-(void)updateSavePassword:(NSString*)userpass;
-(void)deleteUserInfo;
-(void)deletePassword;
-(NSString*) getUsername;
-(NSString*) getUserpass;
-(NSString*) getEmail;
-(void)updateSaveEmail:(NSString*)email;

#pragma 注销操作
-(void)saveLogoutAndIndex:(int)index;
-(int )getLogout;
-(void)deleteLogout;


- (NSString*)getCurrentLanguage;
- (NSString*)getLoginLanguage;

#pragma 临时保存uid
-(void)saveDeviceInfo:(NSString *)uid andDeviceName:(NSString *)Device;
-(void)deleteDeviceInfo;
-(NSString *)getDeviceUid;
-(NSString *)getDeviceName;

#pragma 铃声
-(void)saveRing:(NSString *)uid andFlag:(BOOL)flag;
-(BOOL)getRing:(NSString*)uid;
-(NSString *)getBundleName;
@end
