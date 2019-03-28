//
//  WriteTxt.h
//  Ulife
//
//  Created by Lasia on 12-9-21.
//
//

#import <Foundation/Foundation.h>

@interface WriteTxt : NSObject
{
	BOOL            m_recordVideo;
    NSString*       m_recordPath;
    FILE*           m_fpFile;
    int             nRecordFoundIFrame;
	NSString*		audioPath;
}


-(BOOL)startRecordFileName:(NSString*)fileName type:(NSString*)typeName removeOldOne:(BOOL)remove;

-(void)stopRecord;

-(void)saveData:(char*)buffer withLength:(int)frameLength;

-(NSString*)audioFilePathWithFileName:(NSString*)fileName;

@end
