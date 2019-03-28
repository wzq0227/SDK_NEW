//
//  SensorDB.m
//  Ulife2.0
//
//  Created by goscam on 15/12/22.
//  Copyright © 2015年 goscam_sz. All rights reserved.
//

#import "UserDB.h"
#import "SaveDataModel.h"

/*
  ------------------------------------ t_ULifeUser (用户表) ------------------------------------
 description：根据‘email’来过滤不同的用户
 ____________________________________________________________________________________________
 |    序号    |   账号    |   密码    |       邮箱      |     手机     |    QQ 号    |   微信号   |
 |-----------|----------|----------|-----------------|-------------|------------|-----------|
 |  integer  |  string  |  string  |      string     |    string   |   string   |  string   |
 |-----------|----------|----------|-----------------|-------------|------------|-----------|
 | serialNum |  account | password |      email      |  phoneNum   |     QQ     |   weChat  |
 |-----------|----------|----------|-----------------|-------------|------------|-----------|
 |    001    | ZhangSan |  123456  | ZhangSan@qq.com | 152****3658 | 1234567890 | weixin001 |
 |-----------|----------|----------|-----------------|-------------|------------|-----------|
 
 */


/*
 ------------------------------------ t_ULifeDeviceTable (设备表) ------------------------------------
 description：根据‘email’来过滤不同用户的设备列表，避免‘用户表’的‘account’不唯一性。
 
 ________________________________________________________________________________________________________________________________
 |     序号   |       邮箱       |       设备ID       |  取流名称   |     取流名称     |   昵称   | 所属域id |   设备类型   |  拥有者标识  |
 |-----------|-----------------|-------------------|------------|----------------|----------|---------|------------|------------|
 |  integer  |      string     |        string     |   string   |      string    | string   | string  |  integer   |  integer   |
 |-----------|-----------------|-------------------|------------|----------------|----------|---------|------------|------------|
 | serialNum |      email      |     deviceId      | streamName | streamPassword | nickName | areaId  | deviceType | deviceOwer |
 |-----------|-----------------|-------------------|------------|----------------|----------|---------|------------|------------|
 |    001    | ZhangSan@qq.com | T21B******AY4111A |   admin    |   goscam123    | bedroom  |  10009  |      1     |     1      |
 |-----------|-----------------|-------------------|------------|----------------|----------|---------|------------|------------|
 
 */


/*
 ------------------------------------ t_ULifePushMessageTable (推送信息表) ------------------------------------
 description：根据‘email’来过滤不同用户的设备列表，根据‘deviceId’来过滤不同设备的推送消息。
 
 _________________________________________________________________________________________________________________
 |    序号    |      邮箱        |      设备ID       |      推送路径    |       推送时间        | 推送类型  |   已读标识  |
 |-----------|-----------------|------------------|-----------------|---------------------|----------|-----------|
 |  integer  |      string     |      string      |      string     |       string        | integer  |  integer  |
 |-----------|-----------------|------------------|-----------------|---------------------|----------|-----------|
 | serialNum |      email      |     deviceId     |      pushUrl    |      pushTime       | pushType | readState |
 |-----------|-----------------|------------------|-----------------|---------------------|----------|-----------|
 |    001    | ZhangSan@qq.com | T21B******AY4111 | http://push.com | 2017-06-06 16:28:36 |    pir   |     0     |
 |-----------|-----------------|------------------|-----------------|---------------------|----------|-----------|
 
 */


#define USER_TABLE_NAME @"t_ULifeUser"                  // | serialNum | account | password | email | phoneNum | QQ | weChat |
#define DEVICE_TABLE_NAME @"t_ULifeDeviceTable"         // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
#define PUSH_MSG_TABLE_NAME @"t_ULifePushMessageTable"  // | serialNum | email | deviceId | pushUrl | pushTime | pushType | readState |
#define ULIFE_DATABASE_NAME @"ULifeData.sqlite"

#define COLUMN_SUBDEVICE (@"subDeviceID")

@interface UserDB()

@property (nonatomic, copy) NSString *userTable;
@property (nonatomic, copy) NSString *deviceTable;
@property (nonatomic, copy) NSString *pushMessageTable;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end


@implementation UserDB


+ (UserDB *)sharedInstance
{
    static UserDB *g_UserDBInstance = nil;
    static dispatch_once_t token;
    if(nil == g_UserDBInstance)
    {
        dispatch_once(&token,^{
            
            g_UserDBInstance = [[UserDB alloc] init];
        });
    }
    return g_UserDBInstance;
}


- (instancetype)init
{
    if (self = [super init])
    {
        self.userTable        = USER_TABLE_NAME;
        self.deviceTable      = DEVICE_TABLE_NAME;
        self.pushMessageTable = PUSH_MSG_TABLE_NAME;
        NSString *document    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                     NSUserDomainMask,
                                                                     YES) lastObject];
        NSString *fileName    = [document stringByAppendingPathComponent:ULIFE_DATABASE_NAME];
        self.databaseQueue    = [FMDatabaseQueue databaseQueueWithPath:fileName];
        
        [self initUserTable];
        [self initDeviceTable];
        [self pushMessageDBInit];
        
        [self addSubDeviceColumnToPushMsgTable];
    }
    return self;
}

- (void)addSubDeviceColumnToPushMsgTable{
    __block BOOL isInsert = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL columnExist = [db columnExists:COLUMN_SUBDEVICE inTableWithName:self.pushMessageTable];
        
        if (!columnExist) {
            
            BOOL successflag = [db executeUpdateWithFormat:@"ALTER TABLE t_ULifePushMessageTable ADD COLUMN subDeviceID TEXT DEFAULT '0'"];
            
            
            if (NO == successflag)
            {
                NSLog(@"添加subDeviceID列失败");
                *rollback = YES;
            }
            else
            {
                NSLog(@"添加subDeviceID列成功");
                isInsert = YES;
            }
        }
        
    }];
}

#pragma mark - 初始化表
#pragma mark -- 判断表是否存在
- (BOOL)isExistTable:(NSString *)tableName
{
    if (IS_STRING_EMPTY(tableName))
    {
        NSLog(@"无法查询表示法存在，tableName = nil");
        return NO;
    }
    NSString *checkExistTableSql = [NSString stringWithFormat:@"select count(*) as countNum from sqlite_master where type = 'table' and name = '%@'", tableName];
    __block BOOL isExist = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *resultSet = [db executeQuery:checkExistTableSql];
        while ([resultSet next])
        {
            NSInteger count = [resultSet intForColumn:@"countNum"];
            if (0 == count)
            {
                isExist = NO;
            }
            else
            {
                isExist = YES;
            }
            [resultSet close];
            return ;
        }
    }];
    
    return isExist;
}


#pragma mark -- 创建表
- (BOOL)createTableWithSql:(NSString *)createTableSql
{
    if (IS_STRING_EMPTY(createTableSql))
    {
        NSLog(@"无法查询表示法存在，tableName = nil");
        return NO;
    }
    __block BOOL isCreateSuccess = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        
        BOOL result = [db executeUpdate:createTableSql];
        if (YES == result)
        {
            NSLog(@"创建表成功!");
            isCreateSuccess = YES;
            return ;
        }
        NSLog(@"创建表失败！");
    }];
    return isCreateSuccess;
}


#pragma mark -- 初始化用户表
- (BOOL)initUserTable
{
    if (YES == [self isExistTable:self.userTable])
    {
        return YES;
    }
//    |  integer  |  string  |  string  |      string     |    string   |   string   |  string   |
//    |-----------|----------|----------|-----------------|-------------|------------|-----------|
//    | serialNum |  account | password |      email      |  phoneNum   |     QQ     |   weChat  |
    NSString *createTableSql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (serialNum INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT, password TEXT NOT NULL, email TEXT NOT NULL, phoneNum TEXT, QQ TEXT, weChat TEXT);", self.userTable];
  
    return [self createTableWithSql:createTableSql];
}


#pragma mark -- 初始化设备表
-(BOOL)initDeviceTable
{
    if (YES == [self isExistTable:self.deviceTable])
    {
        return YES;
    }
//    |  integer  |      string     |        string     |   string   |      string    | string   | string  |  integer   |  integer   |
//    |-----------|-----------------|-------------------|------------|----------------|----------|---------|------------|------------|
//    | serialNum |      email      |     deviceId      | streamName | streamPassword | nickName | areaId  | deviceType | deviceOwer |
    NSString *createTableSql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (serialNum INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT NOT NULL, deviceId TEXT NOT NULL, streamName TEXT, streamPassword TEXT, nickName TEXT, areaId TEXT, deviceType INTEGER, deviceOwer INTEGER);", self.deviceTable];
    
    return [self createTableWithSql:createTableSql];
}


#pragma mark -- 初始化推送信息表
-(BOOL)pushMessageDBInit
{
    if (YES == [self isExistTable:self.pushMessageTable])
    {
        return YES;
    }
//    |  integer  |      string     |      string      |      string     |       string        | integer  |  integer  |
//    |-----------|-----------------|------------------|-----------------|---------------------|----------|-----------|
//    | serialNum |      email      |     deviceId     |      pushUrl    |      pushTime       | pushType | readState |
    NSString *createTableSql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (serialNum INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT NOT NULL, deviceId TEXT NOT NULL, pushUrl TEXT, pushTime TEXT, pushType INTEGER, readState INTEGER);", self.pushMessageTable];
    
    return [self createTableWithSql:createTableSql];
}


#pragma mark - 用户管理
#pragma mark -- 增
- (BOOL)insertUserModel:(UserModel *)userModel
{
    if (!userModel)
    {
        NSLog(@"无法插入新用户数据 model，userModel = nil");
        return NO;
    }
    __block BOOL isInsert = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        // | serialNum | account | password | email | phoneNum | QQ | weChat |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifeUser WHERE email = %@", [self getCurrentEmail]];
        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (YES == isExist)
        {
            NSLog(@"数据库已存在该用户！");
            isInsert = YES;
            return ;
        }
        BOOL successflag = [db executeUpdateWithFormat:@"INSERT INTO t_ULifeUser (account, password, email, phoneNum, QQ, weChat) VALUES (%@, %@, %@, %@, %@, %@)", userModel.account, userModel.password, userModel.email, userModel.phoneNum, userModel.QQ, userModel.weChat];
        
//        BOOL successflag = [db executeUpdate:@"INSERT INTO t_ULifeUser (account, password, email, phoneNum, QQ, weChat) VALUES (?,?,?,?,?,?)", userModel.account, userModel.password, [self getCurrentEmail], userModel.phoneNum, userModel.QQ, userModel.weChat];
        if (NO == successflag)
        {
            NSLog(@"插入新用户失败！");
            *rollback = YES;
        }
        else
        {
            NSLog(@"插入新用户成功！");
            isInsert = YES;
        }
    }];
    return isInsert;
}


#pragma mark -- 删
- (BOOL)deleteUserModel:(UserModel *)userModel
{
    if (!userModel)
    {
        NSLog(@"无法删除用户数据 model，userModel = nil");
        return NO;
    }
    __block BOOL isDelete = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        // | serialNum | account | password | email | phoneNum | QQ | weChat |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifeUser WHERE email = %@", [self getCurrentEmail]];
        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (NO == isExist)
        {
            NSLog(@"数据库不存在该用户！");
            isDelete = YES;
            return ;
        }
        BOOL successflag = [db executeUpdateWithFormat:@"DELETE FROM t_ULifeUser WHERE email = %@", [self getCurrentEmail]];
        if (!successflag)
        {
            NSLog(@"删除用户失败！");
            *rollback = YES;
        }
        else
        {
            NSLog(@"删除用户成功！");
            isDelete = YES;
        }
    }];
    return isDelete;
}


#pragma mark -- 修改用户密码
- (BOOL)updateUserPassword:(UserModel *)userModel
{
    if (!userModel)
    {
        NSLog(@"无法修改用户密码，userModel = nil");
        return NO;
    }
    __block BOOL isUpdate = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        //  | serialNum | account | password | email | phoneNum | QQ | weChat |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifeUser WHERE email = %@", [self getCurrentEmail]];
        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (YES == isExist)
        {
            BOOL successflag = [db executeUpdateWithFormat:@"UPDATE t_ULifeUser SET password = %@ WHERE email = %@", userModel.password, [self getCurrentEmail]];
            if (!successflag)
            {
                NSLog(@"修改用户密码失败！");
                *rollback = YES;
            }
            else
            {
                NSLog(@"修改用户密码成功！");
                isUpdate = YES;
            }
        }
    }];
    return isUpdate;
}


#pragma mark -- 返回当前登录的 ‘邮箱’
- (NSString *)getCurrentEmail
{
    NSString *email = [SaveDataModel getUserName];
    return email;
}


#pragma mark - 设备管理
#pragma mark -- 增
- (BOOL)insertDeviceModel:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法插入新设备数据 model，userModel = nil");
        return NO;
    }
    __block BOOL isInsert = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifeDeviceTable WHERE email = %@ AND deviceId = %@", [self getCurrentEmail], deviceModel.DeviceId];
        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (YES == isExist)
        {
            NSLog(@"数据库已存在该设备，deviceId = %@", deviceModel.DeviceId);
            isInsert = YES;
            return ;
        }
        BOOL successflag = [db executeUpdateWithFormat:@"INSERT INTO t_ULifeDeviceTable (email, deviceId, streamName, streamPassword, nickName,  areaId, deviceType, deviceOwer) VALUES (%@, %@, %@, %@, %@, %@, %d, %d)", [self getCurrentEmail], deviceModel.DeviceId, deviceModel.StreamUser, deviceModel.StreamPassword, deviceModel.DeviceName, deviceModel.AreaId, deviceModel.DeviceType, deviceModel.DeviceOwner];
        if (NO == successflag)
        {
            NSLog(@"插入新设备失败，deviceId = %@", deviceModel.DeviceId);
            *rollback = YES;
        }
        else
        {
            NSLog(@"插入新设备成功，deviceId = %@", deviceModel.DeviceId);
            isInsert = YES;
        }
    }];
    return isInsert;
}


#pragma mark -- 删
- (BOOL)deleteDeviceModel:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法删除设备数据 model，deviceModel = nil");
        return NO;
    }
    __block BOOL isDelete = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifeDeviceTable WHERE email = %@ AND deviceId = %@", [self getCurrentEmail], deviceModel.DeviceId];
        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (NO == isExist)
        {
            isDelete = YES;
            return ;
        }
        BOOL successflag = [db executeUpdateWithFormat:@"DELETE FROM t_ULifeDeviceTable WHERE email = %@ AND deviceId = %@", [self getCurrentEmail], deviceModel.DeviceId];
        if (!successflag)
        {
            NSLog(@"删除设备失败，deviceId = %@", deviceModel.DeviceId);
            *rollback = YES;
        }
        else
        {
            NSLog(@"删除设备成功，deviceId = %@", deviceModel.DeviceId);
            isDelete = YES;
        }
    }];
    return isDelete;
}


#pragma mark -- 修改设备 昵称
- (BOOL)updataDeviceNikeName:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法修改设备昵称，deviceModel = nil");
        return NO;
    }
    __block BOOL isUpdate = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifeDeviceTable WHERE email = %@ AND deviceId = %@", [self getCurrentEmail], deviceModel.DeviceId];
        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (YES == isExist)
        {
            BOOL successflag = [db executeUpdateWithFormat:@"UPDATE t_ULifeDeviceTable SET nickName = %@ WHERE email = %@ AND deviceId = %@", deviceModel.DeviceName, [self getCurrentEmail], deviceModel.DeviceId];
            if (NO == successflag)
            {
                NSLog(@"修改设备昵称失败，deviceId = %@", deviceModel.DeviceId);
                *rollback = YES;
            }
            else
            {
                NSLog(@"修改设备昵称成功，deviceId = %@", deviceModel.DeviceId);
                isUpdate = YES;
            }
        }
    }];
    return isUpdate;
}


#pragma mark -- 修改设备取流密码
- (BOOL)updataDevicePassWord:(DeviceDataModel *)deviceModel
{
    if (!deviceModel)
    {
        NSLog(@"无法修改设备昵称，deviceModel = nil");
        return NO;
    }
    __block BOOL isUpdate = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifeDeviceTable WHERE email = %@ AND deviceId = %@", [self getCurrentEmail], deviceModel.DeviceId];
        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (YES == isExist)
        {
            BOOL successflag = [db executeUpdateWithFormat:@"UPDATE t_ULifeDeviceTable SET streamPassword = %@ WHERE email = %@ AND deviceId = %@", deviceModel.StreamPassword, [self getCurrentEmail], deviceModel.DeviceId];
            if (NO == successflag)
            {
                NSLog(@"修改设备取流密码失败，deviceId = %@", deviceModel.DeviceId);
                *rollback = YES;
            }
            else
            {
                NSLog(@"修改设备取流密码成功，deviceId = %@", deviceModel.DeviceId);
                isUpdate = YES;
            }
        }
    }];
    return isUpdate;
}


#pragma mark -- 获取设备列表
- (NSMutableArray *)deviceListArray
{
    NSMutableArray <DeviceDataModel *>*devArray = [NSMutableArray arrayWithCapacity:0];
    
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifeDeviceTable WHERE email = %@", [self getCurrentEmail]];
        while (resultSet.next)
        {
            DeviceDataModel *tempModel = [[DeviceDataModel alloc] init];
            tempModel.DeviceId         = [resultSet stringForColumn:@"deviceId"];
            tempModel.DeviceName       = [resultSet stringForColumn:@"nickName"];
            tempModel.StreamUser       = [resultSet stringForColumn:@"streamName"];
            tempModel.StreamPassword   = [resultSet stringForColumn:@"streamPassword"];
            tempModel.AreaId           = [resultSet stringForColumn:@"areaId"];
            tempModel.DeviceType       = [resultSet intForColumn:@"deviceType"];
            tempModel.DeviceOwner      = [resultSet intForColumn:@"deviceOwer"];
            tempModel.Status           = GosDeviceStatusOffLine;
            [devArray addObject:tempModel];
        }
        [resultSet close];
    }];
    return devArray;
}


#pragma mark -- 移除所有设备
- (BOOL)removeAllDevice
{
    __block BOOL isDelete = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
        BOOL successflag = [db executeUpdateWithFormat:@"DELETE FROM t_ULifeDeviceTable WHERE email = %@", [self getCurrentEmail]];
        if (!successflag)
        {
            NSLog(@"删除所有设备失败，email = %@", [self getCurrentEmail]);
            *rollback = YES;
        }
        else
        {
            NSLog(@"删除所有设备成功，email = %@", [self getCurrentEmail]);
            isDelete = YES;
        }
    }];
    return isDelete;
}


#pragma mark - 推送消息
#pragma mark -- 增

- (void)removePushMsgsOfSubDevice:(NSString*)subID inDevice:(NSString*)deviceId{
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        
        BOOL successflag = [db executeUpdateWithFormat:@"DELETE FROM t_ULifePushMessageTable WHERE email = %@ AND deviceId = %@ AND subDeviceID = %@ ", [self getCurrentEmail], deviceId, subID];
        //        BOOL successflag = [db executeUpdateWithFormat:@"DELETE FROM t_ULifePushMessageTable WHERE serialNum = %d", pushMsgModel.serialNum];
        if (!successflag)
        {
            NSLog(@"*****************删除子设备推送消息失败！");
            *rollback = YES;
        }
        else
        {
            NSLog(@"*****************删除子设备推送消息成功！");
        }
    }];
}


- (BOOL)insertPushMessageModel:(PushMessageModel *)pushMsgModel
{
    if (!pushMsgModel)
    {
        NSLog(@"无法插入新推送消息数据 model，userModel = nil");
        return NO;
    }
    __block BOOL isInsert = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL columnExist = [db columnExists:COLUMN_SUBDEVICE inTableWithName:self.pushMessageTable];
        NSString *sqlStr = nil;
        BOOL successflag = false;
        // | serialNum | email | deviceId | pushUrl | pushTime | pushType | readState |

        if ( !columnExist  ) { // || [mUserDefaults integerForKey:IsBetaVersion]
            
            successflag = [db executeUpdateWithFormat:@"INSERT INTO t_ULifePushMessageTable (email, deviceId, pushUrl, pushTime, pushType, readState) VALUES (%@, %@, %@, %@, %d, %d)", pushMsgModel.email, pushMsgModel.deviceId, pushMsgModel.pushUrl, pushMsgModel.pushTime, pushMsgModel.apnsMsgType, pushMsgModel.apnsMsgReadState];
//            sqlStr = [NSString stringWithFormat:@"INSERT INTO t_ULifePushMessageTable (email, deviceId, pushUrl, pushTime, pushType, readState) VALUES (%@, %@, %@, %@, %d, %d)", pushMsgModel.email, pushMsgModel.deviceId, pushMsgModel.pushUrl, pushMsgModel.pushTime, pushMsgModel.apnsMsgType, pushMsgModel.apnsMsgReadState];
        }else{
            successflag = [db executeUpdateWithFormat:@"INSERT INTO t_ULifePushMessageTable (email, deviceId, pushUrl, pushTime, pushType, readState, subDeviceID) VALUES (%@, %@, %@, %@, %d, %d, %@)", pushMsgModel.email, pushMsgModel.deviceId, pushMsgModel.pushUrl, pushMsgModel.pushTime, pushMsgModel.apnsMsgType, pushMsgModel.apnsMsgReadState, pushMsgModel.subDeviceID];

        }
        

        if (NO == successflag)
        {
            NSLog(@"插入新推送消息失败！");
            *rollback = YES;
        }
        else
        {
            NSLog(@"插入新推送消息成功！");
            isInsert = YES;
        }
    }];
    return isInsert;
}


#pragma mark -- 删
- (BOOL)deletePushMessageModel:(PushMessageModel *)pushMsgModel
{
    if (!pushMsgModel)
    {
        NSLog(@"无法删除推送消息 pushMsgModel = nil");
        return NO;
    }
    __block BOOL isDelete = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback){
        
        // | serialNum | email | deviceId | pushUrl | pushTime | pushType | readState |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifePushMessageTable WHERE email = %@ AND deviceId = %@ AND pushUrl = %@ AND pushTime = %@", pushMsgModel.email, pushMsgModel.deviceId, pushMsgModel.pushUrl, pushMsgModel.pushTime];

        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (NO == isExist)
        {
            isDelete = YES;
            return ;
        }
        BOOL successflag = [db executeUpdateWithFormat:@"DELETE FROM t_ULifePushMessageTable WHERE email = %@ AND deviceId = %@ AND pushUrl = %@ AND pushTime = %@", pushMsgModel.email, pushMsgModel.deviceId, pushMsgModel.pushUrl, pushMsgModel.pushTime];
//        BOOL successflag = [db executeUpdateWithFormat:@"DELETE FROM t_ULifePushMessageTable WHERE serialNum = %d", pushMsgModel.serialNum];
        if (!successflag)
        {
            NSLog(@"删除推送消息失败！");
            *rollback = YES;
        }
        else
        {
            NSLog(@"删除推送消息成功！");
            isDelete = YES;
        }
    }];
    
    return isDelete;
}


#pragma mark -- 修改推送信息读状态
-(BOOL)updatePushMsgReadState:(PushMessageModel *)pushMsgModel
{
    if (!pushMsgModel)
    {
        NSLog(@"无法修改推送 model ，pushMsgModel = nil");
        return NO;
    }
    __block BOOL isUpdate = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        // | serialNum | email | deviceId | pushUrl | pushTime | pushType | readState |
        BOOL isExist = NO;
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifePushMessageTable WHERE email = %@ AND deviceId = %@ AND pushUrl = %@ AND pushTime = %@", pushMsgModel.email, pushMsgModel.deviceId, pushMsgModel.pushUrl, pushMsgModel.pushTime];

        while ([resultSet next])
        {
            isExist = YES;
            break;
        }
        [resultSet close];
        
        if (YES == isExist)
        {
            BOOL successflag = [db executeUpdateWithFormat:@"UPDATE t_ULifePushMessageTable SET readState = %ld WHERE email = %@ AND deviceId = %@ AND pushUrl = %@ AND pushTime = %@", pushMsgModel.apnsMsgReadState, pushMsgModel.email, pushMsgModel.deviceId, pushMsgModel.pushUrl, pushMsgModel.pushTime];
            if (NO == successflag)
            {
                *rollback = YES;
                return;
            }
            else
            {
                isUpdate = YES;
            }
            NSLog(@"updatePushMsgReadState:%d",db.changes);
        }
    }];
    return isUpdate;
}


#pragma mark -- 获取所有推送消息
- (NSMutableArray <PushMessageModel *>*)pushMessageArray
{
    NSMutableArray <PushMessageModel *>*ssArray= [NSMutableArray arrayWithCapacity:0];
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
         // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
         // | serialNum | email | deviceId | pushUrl | pushTime | pushType | readState |

        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifePushMessageTable, t_ULifeDeviceTable WHERE t_ULifePushMessageTable.deviceId=t_ULifeDeviceTable.deviceId AND t_ULifePushMessageTable.email=t_ULifeDeviceTable.email AND t_ULifePushMessageTable.email = %@", [self getCurrentEmail]];
        
        while (resultSet.next)
        {
            @autoreleasepool
            {
                PushMessageModel *model = [[PushMessageModel alloc]init];
//                NSLog(@"serialNum---%ld",[[resultSet stringForColumn:@"serialNum"] integerValue]);
                
                model.serialNum         = [[resultSet stringForColumn:@"serialNum"] integerValue];
                model.email             = [resultSet stringForColumn:@"email"];
                model.deviceId          = [resultSet stringForColumn:@"deviceId"];
                
                //这里取最新的推送名称
                model.deviceName        = [resultSet stringForColumn:@"nickName"];
                model.pushUrl           = [resultSet stringForColumn:@"pushUrl"];
                model.pushTime          = [resultSet stringForColumn:@"pushTime"];
                model.apnsMsgType       = [resultSet intForColumn:@"pushType"];
                model.apnsMsgReadState  = [resultSet intForColumn:@"readState"];
                model.subDeviceID       = [resultSet stringForColumn:@"subDeviceID"];
                
                [ssArray insertObject:model atIndex:0];
            }
        }
        [resultSet close];
    }];
    return ssArray;
}



#pragma mark -- 根据设备 ID 获取设备的所有推送
- (NSMutableArray <PushMessageModel *>*)pushMsgArrayWidthDevId:(NSString *)deviceId
{
    if (!deviceId || 0 >= deviceId.length)
    {
        return nil;
    }
    NSMutableArray <PushMessageModel *>*ssArray= [NSMutableArray arrayWithCapacity:0];
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        // | serialNum | email | deviceId | streamName | streamPassword | nickName| areaId | deviceType | deviceOwer |
        // | serialNum | email | deviceId | pushUrl | pushTime | pushType | readState |

        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * FROM t_ULifePushMessageTable, t_ULifeDeviceTable WHERE t_ULifePushMessageTable.deviceId=t_ULifeDeviceTable.deviceId AND t_ULifePushMessageTable.email=t_ULifeDeviceTable.email AND t_ULifePushMessageTable.email = %@ AND t_ULifePushMessageTable.deviceId = %@", [self getCurrentEmail], deviceId];
        
        while (resultSet.next)
        {
            @autoreleasepool
            {
                PushMessageModel *model = [[PushMessageModel alloc]init];
//                NSLog(@"serialNum---%ld",[[resultSet stringForColumn:@"serialNum"] integerValue]);
                
                model.serialNum         = [[resultSet stringForColumn:@"serialNum"] integerValue];
                model.email             = [resultSet stringForColumn:@"email"];
                model.deviceId          = [resultSet stringForColumn:@"deviceId"];
                model.deviceName        = [resultSet stringForColumn:@"nickName"];
                model.pushUrl           = [resultSet stringForColumn:@"pushUrl"];
                model.pushTime          = [resultSet stringForColumn:@"pushTime"];
                model.apnsMsgType       = [resultSet intForColumn:@"pushType"];
                model.apnsMsgReadState  = [resultSet intForColumn:@"readState"];
                model.subDeviceID       = [resultSet stringForColumn:@"subDeviceID"];

                [ssArray insertObject:model atIndex:0];
            }
        }
        [resultSet close];
    }];
    return ssArray;
}


#pragma mark -- 删除所有表
- (void)deleteAllTable
{
    NSString *sqlUser    = [NSString stringWithFormat:@"delete from %@", self.userTable];
    NSString *sqlDevice  = [NSString stringWithFormat:@"delete from %@", self.deviceTable];
    NSString *sqlPushMsg = [NSString stringWithFormat:@"delete from %@", self.pushMessageTable];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        
        [db executeUpdate:sqlUser];
        NSLog(@"deleteAllItem:%d",db.changes);
    }];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        
        [db executeUpdate:sqlDevice];
        NSLog(@"deleteAllItem:%d",db.changes);
    }];
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        
        [db executeUpdate:sqlPushMsg];
        NSLog(@"deleteAllItem:%d",db.changes);
    }];
}


#pragma mark -- 关闭数据库
-(void)closeDB
{
    NSLog(@"closeDB");
    if ([self.databaseQueue openFlags])
    {
        [self.databaseQueue close];
    }
}

@end
