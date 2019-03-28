//
//  MySqliteForLocalCamera.m
//  Custom Ulife
//
//  Created by yuanx on 13-11-14.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import "MySqliteForLocalCamera.h"


#define SQLITE_NAME         "LOCAL_CAMERA"

//
#define CAMERA_INFO_TABLE    "CAMERA_INFO_TABLE"
#define LCT_ID               "cam_id"
#define LCT_ONLINE           "online"
#define LCT_INFO             "info"
#define LCT_CAM_NAME         "cam_name"
#define LCT_BELONG_TO_SSID   "belong_to_ssid"
#define LCT_INPUT_PASSWORD   "input_password"
#define LCT_PASSWORD         "password"
#define LCT_DATE             "search_date"
#define LCT_HOST             "host"
#define LCT_PORT             "port"



@implementation MySqliteForLocalCamera


-(id)init
{
    if (self = [super initWithSqliteName:@SQLITE_NAME])
    {
        [self tableInit];
    }
    return self;
}

+ (MySqliteForLocalCamera *)sharedInstance
{
    static dispatch_once_t onceToken;
    static MySqliteForLocalCamera *sSharedInstance;
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[MySqliteForLocalCamera alloc] init];
    });
    return sSharedInstance;
}

-(BOOL)tableInit
{
    BOOL ret = YES;
    if ([self isTableExist:CAMERA_INFO_TABLE] == NO)
    {
        ret = ret && [self createLocalCameraTable];
    }
    return ret;
}

-(BOOL)createLocalCameraTable
{
	char sql[1024] = {0};
	sprintf(sql, "CREATE  TABLE %s (%s %s PRIMARY KEY, %s %s, %s %s, %s %s, %s %s, %s %s, %s %s, %s %s, %s %s, %s %s)",
			CAMERA_INFO_TABLE,
			LCT_ID,             "TEXT",
			LCT_ONLINE,         "BOOL",
			LCT_INFO,           "BLOB",
			LCT_BELONG_TO_SSID,	"TEXT",
			LCT_PASSWORD,		"TEXT",
            LCT_DATE,           "INTEGER",
            LCT_CAM_NAME,       "TEXT",
			LCT_INPUT_PASSWORD,	"TEXT",
            LCT_HOST,           "TEST",
            LCT_PORT,           "INTEGER"
			);
	NSLog(@"创建数据表: %s", sql);
    return [self sqlRunCmd:sql];
}


-(BOOL)offlineAllCameras
{
//    UPDATE "main"."LOCAL_CAMERA_TABLE" SET "online" = 0 WHERE  "cam_id" = ""
    char sql[1024] = {0};
    sprintf(sql, "UPDATE \"%s\" SET \"%s\" = 0, \"%s\" = \"\" WHERE 1",
            CAMERA_INFO_TABLE,
            LCT_ONLINE,
            LCT_HOST
            );
    return [self sqlRunCmd:sql];
}

-(BOOL)findCameraWithId:(NSString*)camId toExsit:(BOOL*)exsit
{
    if (camId == nil)
    {
        return NO;
    }
    char sql[1024] = {0};
    sprintf(sql, "SELECT * FROM \"%s\" WHERE \"%s\" = \"%s\"",
            CAMERA_INFO_TABLE,
            LCT_ID,
            camId.UTF8String
            );
    sqlite3_stmt *statement;
    BOOL ret = NO;
    int i = sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL);
    if(i == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
		{
			*exsit = YES;
            ret =YES;
            sqlite3_finalize(statement);
            return ret;
		}
    }
    else
    {
        NSLog( @"SaveBody: Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(self.database) );
    }
    // Finalize and close database.
    sqlite3_finalize(statement);
    return ret;
}

-(BOOL)updateInputPassword:(NSString*)inputPwd toCamId:(NSString*)camId
{
    if (inputPwd == nil || camId == nil)
    {
        return NO;
    }
    //UPDATE "CAMERA_INFO_TABLE" SET "input_password" = "admin" WHERE "cam_id" = "3327188800000013"
    char sql[1024] = {0};
    sprintf(sql, "UPDATE \"%s\" SET \"%s\" = \"%s\" WHERE \"%s\" = \"%s\"",
            CAMERA_INFO_TABLE,
            LCT_INPUT_PASSWORD,
            inputPwd.UTF8String,
            LCT_ID,
            camId.UTF8String
            );
    return [self sqlRunCmd:sql];
}

-(BOOL)updateCameraInfo:(DeviceInfo)info belongToSsid:(NSString*)ssid online:(BOOL)online date:(NSDate*)date host:(NSString*)host port:(int)port
{
    char sql[1024] = {0};
    sprintf(sql, "UPDATE \"%s\" SET \"%s\" = \"%s\", \"%s\" = \"%s\", \"%s\" = \"%s\", \"%s\" = \"%d\", \"%s\" = \"%f\", \"%s\" = \"%s\",\"%s\" = \"%d\",  \"%s\" = ?  WHERE \"%s\" = \"%s\"",
            CAMERA_INFO_TABLE,
            LCT_BELONG_TO_SSID,
            ssid.UTF8String,
            LCT_PASSWORD,
            info.szPwd,
            LCT_CAM_NAME,
            info.szDeviceName,
            LCT_ONLINE,
            1,
            LCT_DATE,
            [date timeIntervalSince1970],
            LCT_HOST,
            host == nil ? "":host.UTF8String,
            LCT_PORT,
            port,
            LCT_INFO,
            LCT_ID,
            info.szCamSerial
            );
    sqlite3_stmt *statement;
    BOOL ret = NO;
    int i = sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL);
    if(i == SQLITE_OK)
    {
        sqlite3_bind_blob(statement, 1, &info, sizeof(DeviceInfo), SQLITE_TRANSIENT);
        sqlite3_step(statement);
        ret = YES;
    }
    else
    {
        NSLog( @"SaveBody: Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(self.database) );
    }
    
    // Finalize and close database.
    sqlite3_finalize(statement);
    return ret;
}

-(BOOL)updateCameraInfo:(DeviceInfo)info belongToSsid:(NSString*)ssid online:(BOOL)online date:(NSDate*)date
{
    char sql[1024] = {0};
    sprintf(sql, "UPDATE \"%s\" SET \"%s\" = \"%s\", \"%s\" = \"%s\", \"%s\" = \"%s\", \"%s\" = \"%d\", \"%s\" = \"%f\", \"%s\" = ?  WHERE \"%s\" = \"%s\"",
            CAMERA_INFO_TABLE,
            LCT_BELONG_TO_SSID,
            ssid.UTF8String,
            LCT_PASSWORD,
            info.szPwd,
            LCT_CAM_NAME,
            info.szDeviceName,
            LCT_ONLINE,
            1,
            LCT_DATE,
            [date timeIntervalSince1970],
            LCT_INFO,
            LCT_ID,
            info.szCamSerial
            );
    sqlite3_stmt *statement;
    BOOL ret = NO;
    int i = sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL);
    if(i == SQLITE_OK)
    {
        sqlite3_bind_blob(statement, 1, &info, sizeof(DeviceInfo), SQLITE_TRANSIENT);
        sqlite3_step(statement);
        ret = YES;
    }
    else
    {
        NSLog( @"SaveBody: Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(self.database) );
    }
    
    // Finalize and close database.
    sqlite3_finalize(statement);
    return ret;
}

-(BOOL)insertCameraInfo:(DeviceInfo)info belongToSsid:(NSString*)ssid online:(BOOL)online date:(NSDate*)date host:(NSString*)host port:(int)port
{
    //INSERT INTO "main"."LOCAL_CAMERA_TABLE" ("cam_id","online","info","belong_to_ssid","saved_password","search_date") VALUES (?1,?2,?3,?4,?5,?6)
    int length = 1024;
    char *sql = malloc(length);
    memset(sql, 0, length);
    sprintf(sql, "INSERT INTO \"main\".\"%s\" (\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\", \"%s\",\"%s\", \"%s\") \
            VALUES (\"%s\",%d, ?, \"%s\",\"%s\",%f, \"%s\",\"%s\", \"%d\")",
            CAMERA_INFO_TABLE,
            LCT_ID,
            LCT_ONLINE,
            LCT_INFO,
            LCT_BELONG_TO_SSID,
            LCT_PASSWORD,
            LCT_DATE,
            LCT_CAM_NAME,
            LCT_HOST,
            LCT_PORT,
            info.szCamSerial,
            online,
            ssid == nil ? "":ssid.UTF8String,
            info.szPwd,
            [date timeIntervalSince1970],
            info.szDeviceName,
            host == nil ? "" : host.UTF8String,
            port
            );
    
    sqlite3_stmt *statement;
    BOOL ret = NO;
    int i = sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL);
    if(i == SQLITE_OK)
    {
        sqlite3_bind_blob(statement, 1, &info, sizeof(DeviceInfo), SQLITE_TRANSIENT);
        sqlite3_step(statement);
        ret = YES;
    }
    else
    {
        NSLog( @"SaveBody: Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(self.database) );
    }
    
    // Finalize and close database.
    sqlite3_finalize(statement);
    return ret;
}


-(BOOL)insertCameraInfo:(DeviceInfo)info belongToSsid:(NSString*)ssid online:(BOOL)online date:(NSDate*)date
{
    //INSERT INTO "main"."LOCAL_CAMERA_TABLE" ("cam_id","online","info","belong_to_ssid","saved_password","search_date") VALUES (?1,?2,?3,?4,?5,?6)
    int length = 1024;
    char *sql = malloc(length);
    memset(sql, 0, length);
    sprintf(sql, "INSERT INTO \"main\".\"%s\" (\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\", \"%s\") \
            VALUES (\"%s\",%d, ?, \"%s\",\"%s\",%f, \"%s\")",
            CAMERA_INFO_TABLE,
            LCT_ID,
            LCT_ONLINE,
            LCT_INFO,
            LCT_BELONG_TO_SSID,
            LCT_PASSWORD,
            LCT_DATE,
            LCT_CAM_NAME,
            info.szCamSerial,
            online,
            ssid == nil ? "":ssid.UTF8String,
            info.szPwd,
            [date timeIntervalSince1970],
            info.szDeviceName
            );
    
    sqlite3_stmt *statement;
    BOOL ret = NO;
    int i = sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL);
    if(i == SQLITE_OK)
    {
        sqlite3_bind_blob(statement, 1, &info, sizeof(DeviceInfo), SQLITE_TRANSIENT);
        sqlite3_step(statement);
        ret = YES;
    }
    else
    {
        NSLog( @"SaveBody: Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(self.database) );
    }
  
    // Finalize and close database.
    sqlite3_finalize(statement);
    return ret;
}

-(BOOL)deleteCameraWithId:(char*)camId
{
    //DELETE  FROM "LOCAL_CAMERA_TABLE" WHERE "cam_id" = "3320188800001161"
    char sql[1024] = {0};
    sprintf(sql, "DELETE  FROM \"%s\" WHERE \"%s\" = \"%s\"",
            CAMERA_INFO_TABLE,
            LCT_ID,
            camId
            );
    return [self sqlRunCmd:sql];
}

-(BOOL)selectAllCameraIdToArray:(NSMutableArray*)camArray
{
    [camArray removeAllObjects];
    //SELECT "cam_id" FROM "LOCAL_CAMERA_TABLE"
    char sql[1024] = {0};
    sprintf(sql, "SELECT \"%s\" FROM \"%s\"",
            LCT_ID,
            CAMERA_INFO_TABLE
            );
    
	sqlite3_stmt *statement = nil;

	if (sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSLog(@"sqlite:执行失败");

		return NO;
    }
	else
	{
		//查询结果集中一条一条的遍历所有的记录，这里的数字对应的是列值。
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			char* a = (char*)sqlite3_column_text(statement, 0);
			[camArray addObject:[[NSString alloc] initWithFormat:@"%s", a]];
		}
		sqlite3_finalize(statement);
		return YES;
	}
}

-(BOOL)selectCameraBasicInfoWithId:(NSString*)camId toInfo:(NSMutableDictionary*)info
{
    //SELECT "cam_id", "online", "belong_to_ssid", "saved_password", "search_date" FROM "LOCAL_CAMERA_TABLE" WHERE "cam_id" = "3320188800001161"
    
    char sql[1024] = {0};
    sprintf(sql, "SELECT \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\" FROM \"%s\" WHERE \"%s\" = \"%s\"",
            LCT_ONLINE,
            LCT_BELONG_TO_SSID,
            LCT_PASSWORD,
            LCT_INPUT_PASSWORD,
            LCT_DATE,
            LCT_CAM_NAME,
            LCT_HOST,
            LCT_PORT,
            CAMERA_INFO_TABLE,
            LCT_ID,
            [camId UTF8String]
            );
    
	sqlite3_stmt *statement = nil;
    
	if (sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSLog(@"sqlite:执行失败");
		return NO;
    }
	else
	{
		//查询结果集中一条一条的遍历所有的记录，这里的数字对应的是列值。
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			BOOL online = sqlite3_column_int(statement, 0);
			char* ssid = (char*)sqlite3_column_text(statement, 1);
			char* password = (char*)sqlite3_column_text(statement, 2);
			char* inputPwd = (char*)sqlite3_column_text(statement, 3);
			double date = sqlite3_column_double(statement, 4);
			char* name = (char*)sqlite3_column_text(statement, 5);
            char* host = (char*)sqlite3_column_text(statement, 6);
            int port = sqlite3_column_int(statement, 7);
            if (info == nil)
            {
                info = [[NSMutableDictionary alloc] init];
            }
            [info setObject:[[NSString alloc] initWithFormat:@"%d", online] forKey:@LCT_ONLINE];
            [info setObject:[[NSString alloc] initWithFormat:@"%s", ssid] forKey:@LCT_BELONG_TO_SSID];
            [info setObject:[[NSString alloc] initWithFormat:@"%s", inputPwd] forKey:@LCT_INPUT_PASSWORD];
            [info setObject:[[NSString alloc] initWithFormat:@"%s", password] forKey:@LCT_PASSWORD];
            [info setObject:[[NSString alloc] initWithFormat:@"%f", date] forKey:@LCT_DATE];
            NSString *nStr =[[NSString alloc] initWithCString:name encoding:NSUTF8StringEncoding];
            if (nStr!=nil) {
                [info setObject:nStr forKey:@LCT_CAM_NAME];
            }
            [info setObject:[[NSString alloc] initWithFormat:@"%s", host] forKey:@LCT_HOST];
            [info setObject:[[NSString alloc] initWithFormat:@"%d", port] forKey:@LCT_PORT];
            break;
		}
		sqlite3_finalize(statement);
		return YES;
	}
}

-(BOOL)selectCameraInfoWithId:(NSString *)camId toInfo:(DeviceInfo *)info
{
    char sql[1024] = {0};
    sprintf(sql, "SELECT \"%s\" FROM \"%s\" WHERE \"%s\" = \"%s\"",
            LCT_INFO,
            CAMERA_INFO_TABLE,
            LCT_ID,
            camId.UTF8String
            );
    sqlite3_stmt *compliedStatement;
    if(sqlite3_prepare(self.database, sql, -1, &compliedStatement, NULL) == SQLITE_OK)
    {
        while (sqlite3_step(compliedStatement)==SQLITE_ROW)
        {
            int bytes = sqlite3_column_bytes(compliedStatement, 0);
            const void *value = sqlite3_column_blob(compliedStatement, 0);
            if( value != NULL && bytes != 0 )
            {
                memcpy(info, value, sizeof(DeviceInfo));
                
                return YES;
            }
        }
    }
    sqlite3_finalize(compliedStatement);
    return NO;
}

@end
