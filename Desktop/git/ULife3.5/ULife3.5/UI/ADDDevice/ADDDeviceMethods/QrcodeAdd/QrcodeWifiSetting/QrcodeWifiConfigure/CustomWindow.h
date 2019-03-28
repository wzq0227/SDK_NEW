//
//  CustomWindow.h
//  UI——update
//
//  Created by goscam_sz on 16/6/30.
//  Copyright © 2016年 goscam_sz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomWindow : UIWindow
{
    
    UIView *superView;
    UIView *backgroundView;
    UIImageView *backgroundImage;
    UIView *contentView;
    BOOL closed;
}

@property (nonatomic,retain) UIView *superView;
@property (nonatomic,retain) UIView *backgroundView;
@property (nonatomic,retain) UIImageView *backgroundImage;
@property (nonatomic,retain) UIView *contentView;

-(CustomWindow *)initWithView:(UIView *)aView;
-(void)show;
-(void)close;

@end
