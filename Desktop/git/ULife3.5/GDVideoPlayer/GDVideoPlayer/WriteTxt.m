//
//  WriteTxt.m
//  Ulife
//
//  Created by Lasia on 12-9-21.
//
//

#import "WriteTxt.h"

@implementation WriteTxt



-(BOOL)startRecordFileName:(NSString*)fileName type:(NSString*)typeName removeOldOne:(BOOL)remove
{
	if (m_recordVideo == NO)
	{
		audioPath = [self audioFilePathWithFileName:[NSString stringWithFormat:@"%@.%@", fileName, typeName]];
		NSLog(@"audio path 1:%@", audioPath);
		NSFileManager* fileManager = [NSFileManager defaultManager];
		NSError* err = nil;
		if ([fileManager fileExistsAtPath:audioPath])
		{
			if (remove)
			{
				if (![fileManager removeItemAtPath:audioPath error:&err])
				{
					NSLog(@"err:%@", err);
					return NO;
				}
			}
		}
		else
		{
			if (![fileManager createFileAtPath:audioPath contents:nil attributes:nil])
			{
				return NO;
			}
		}
		
		int len = [audioPath length];
		char *filePath = (char*)malloc(sizeof(char) * (len + 1));
		[audioPath getCString:filePath maxLength:len + 1 encoding:[NSString defaultCStringEncoding]];
		//NSLog(@"%s",filePath);
		
		if(m_fpFile != NULL)
		{
			fclose(m_fpFile);
			m_fpFile = NULL;
		}
		
		m_fpFile = fopen(filePath, "a+");//wt
		if(m_fpFile == NULL)
		{
			NSLog(@"Create file failed %s m_recordPath: %@", filePath, audioPath);
			free(filePath);
			filePath = nil;
			m_recordVideo = NO;
			return NO;
		}
		free(filePath);
		filePath = nil;
		m_recordVideo = YES;
		NSLog(@"1,m_recordVideo %d", m_recordVideo);
		
		return YES;
	}
	else
	{
		return NO;
	}
}


-(void)stopRecord
{
	if (m_recordVideo != NO)
	{
		m_recordVideo = NO;
		NSLog(@"XXXXXXXXXXXXm_recordVideo = NO; %d", m_recordVideo);
		usleep(20000);
		if(m_fpFile != NULL)
		{
			fclose(m_fpFile);
			m_fpFile = NULL;
		}
		nRecordFoundIFrame = 0;
	}
}


-(void)saveData:(void*)buffer withLength:(int)frameLength
{
	
	if (!m_recordVideo)
	{
		return;
	}
	NSLog(@"saveData:(char*)buffer withLength:(int)frameLength");
    int ret = fwrite(buffer,frameLength,1,m_fpFile);
    if(ret < 0)
    {
        NSLog(@"write filed");
    }
}


-(NSString*)audioFilePathWithFileName:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString* audioName = [NSString stringWithFormat:fileName];
	return [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
}


@end
