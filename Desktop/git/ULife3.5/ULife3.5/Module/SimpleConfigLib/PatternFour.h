//
//  PatternFour.h
//  SimpleConfig
//
//  Created by Realsil on 14/11/20.
//  Copyright (c) 2014年 Realtek. All rights reserved.
//

#import "PatternBase.h"
#import "ecc.h"

#define PATTERN_FOUR_DBG        1

@interface PatternFour : PatternBase
{
@private
    unsigned char m_rand[4];
}
@end
