//
//  MySqlite.m
//  Custom Ulife
//
//  Created by yuanx on 13-11-14.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import "MySqlite.h"

@interface MySqlite ()
{
	
}



@end

@implementation MySqlite
//@synthesize database = _database;

-(id)initWithSqliteName:(NSString*)name
{
    if (self = [super init])
    {
        [self openDatabase:name];
    }
    return self;
}

-(void)dealloc
{
    [self closeDatabase];
}

-(BOOL)openDatabase:(NSString*)name
{
	if (_database)
	{
		return YES;
	}
    
	BOOL iRet = NO;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:name];//获取路径
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL find = [fileManager fileExistsAtPath:path];
	//NSLog(@"documentsDirectory %@", documentsDirectory);
	
    //找到数据库文件mydb.sqlite
    if (find) //数据库文件存在
	{
        NSLog(@"sqlite:Database [ulife_local]  is exist.");
		iRet = YES;
    }
	else//数据库文件不存在
	{
		NSLog(@"sqlite:Error: database [ulife_local] is not exist. create one.");
		if(sqlite3_open([[documentsDirectory stringByAppendingPathComponent:name] UTF8String],&_database)!=SQLITE_OK)
		{
			NSLog(@"sqlite:Error in Database!");
			iRet = NO;
			sqlite3_close(_database);
			_database = nil;
		}
	}
	//打开数据库  如果没有则会创建一个新的数据库
	
	if(iRet == YES)
	{
		if(sqlite3_open([path UTF8String], &_database) != SQLITE_OK)
		{
			sqlite3_close(_database);
			_database = nil;
			NSLog(@"sqlite:Error: open ulife_local database file failed.");
			iRet = NO;
		}
		else
		{
			NSLog(@"sqlite:open ulife_local database file success.");
			iRet = YES;
		}
	}
    
    return iRet;
}

-(BOOL)closeDatabase
{
	if (_database)
	{
		if(sqlite3_close(_database) == SQLITE_OK)
		{
			NSLog(@"sqlite: close database success.");
			return YES;
		}
		else
		{
			NSLog(@"sqlite: close database error.");
			return NO;
		}
	}
	return YES;
}

-(BOOL)isTableExist:(char*)tblName
{
	char sql[300];
	sprintf(sql, "SELECT count(*) FROM sqlite_master WHERE tbl_name = \"%s\"", tblName);
	
	NSLog(@"sql:%s", sql);
	sqlite3_stmt *statement = nil;
	int ret = 0;
    
    if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK)
	{
		NSLog(@"sqlite:Error: failed to select table cam_list exsit or not.");
    }
	else
	{
		//查询结果集中一条一条的遍历所有的记录，这里的数字对应的是列值。
		while (sqlite3_step(statement) == SQLITE_ROW)
		{
			const char* a = (const char*)sqlite3_column_text(statement, 0);
			ret = atoi(a);
			break;
		}
		sqlite3_finalize(statement);
	}
    
	if (ret > 0)
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

-(BOOL)sqlRunCmd:(char*)sqlCmd
{
	BOOL iRet = NO;
    sqlite3_stmt *statement;
	NSLog(@"sql:%s", sqlCmd);
    
    if(sqlite3_prepare_v2(_database, sqlCmd, -1, &statement, nil) != SQLITE_OK)
	{
        NSLog(@"sqlite:命令未成功执行");
        iRet = NO;
    }
	else
	{
		int success = sqlite3_step(statement);
		sqlite3_finalize(statement);
		if (success != SQLITE_DONE)
		{
			NSLog(@"sqlite:执行失败");
			iRet = NO;
		}
		else
		{
			iRet = YES;
		}
	}
    
    return iRet;
}


@end
