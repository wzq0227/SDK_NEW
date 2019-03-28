//
//  MySqlite.h
//  Custom Ulife
//
//  Created by yuanx on 13-11-14.
//  Copyright (c) 2013年 yuanx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface MySqlite : NSObject
{
    
}
@property(nonatomic, assign)sqlite3* database;

-(id)initWithSqliteName:(NSString*)name;
-(BOOL)isTableExist:(char*)tblName;
-(BOOL)sqlRunCmd:(char*)sqlCmd;


@end
