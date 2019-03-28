//
//  VideoView.m
//  goscamapp
//
//  Created by goscam_sz on 17/4/20.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "VideoView.h"

@implementation VideoView

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

-(NSMutableArray *)DevListArr
{
    if (_DevListArr==nil) {
        _DevListArr=[[NSMutableArray alloc]init];
    }
    return _DevListArr;
}



-(void)awakeFromNib
{
    [super awakeFromNib];
    self.myVideoListTabbleView.separatorStyle= UITableViewCellSeparatorStyleNone;
    self.myVideoListTabbleView.delegate=self;
    self.myVideoListTabbleView.dataSource=self;
    [self.myVideoListTabbleView registerNib:[UINib nibWithNibName:@"VideoListTableViewCell" bundle:nil ] forCellReuseIdentifier:@"cell"];
    self.getDeviceListSocket = [QQIGetDeviceListSocket shareInstanceUpListand:@"120.24.219.86" andPort:@"9900"];
    self.getDeviceListSocket.delegate = self;
    [self setUI];
}



-(void)setUI
{
    [self.FristBtn setTitle:@"添加摄像头" forState:UIControlStateNormal];
    [self.FristBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.FristBtn setBackgroundColor:myColor];
    self.FristBtn.adjustsImageWhenHighlighted = NO;
    [self.FristBtn addTarget:self action:@selector(pushToAdDevice) forControlEvents:UIControlEventTouchUpInside];
    
    [self.SecondBtn setTitle:@"体验视频" forState:UIControlStateNormal];
    [self.SecondBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.SecondBtn setBackgroundColor:myColor];
    [self.SecondBtn addTarget:self action:@selector(tapAction) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc]initWithTarget:self     action:@selector(tapAction)];
    //配置属性
    //轻拍次数
    tap.numberOfTapsRequired =1;
    //轻拍手指个数
    tap.numberOfTouchesRequired =1;
    //讲手势添加到指定的视图上
    [self.tapView addGestureRecognizer:tap];
    self.tapView.backgroundColor=myColor;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    _myVideoListCell=[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    _myVideoListCell.selectionStyle=UITableViewCellSelectionStyleNone;
    
    
    VideoModel *md = _DevListArr[indexPath.row];
    [_myVideoListCell freshen:md];

    return _myVideoListCell;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _DevListArr.count;
}



-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float a = 230 *  [UIScreen mainScreen].bounds.size.width /375.0 ;

    return a;
}


      - (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(startPushToPlayVideoView:deviceName:)])
    {
        [self.delegate startPushToPlayVideoView:@"SMEV2AEL9F2NRZPM111A"
                                     deviceName:@"客厅"];
    }
}


-(void)pushToAdDevice
{
    NSLog(@"添加摄像头");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(startPushToAdDevice)])
    {
        [self.delegate startPushToAdDevice];
    }
}



-(void)tapAction
{
    NSLog(@"体验视频代理");
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(startPushExperienceVideoView)])
    {
        [self.delegate startPushExperienceVideoView];
    }
}



- (IBAction)Delete:(id)sender {
    
    NSLog(@"删除体验视频");
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        self.hight.constant=0;
        self.SecondWith.constant=0;
        self.deleteWith.constant=0;
    });
}



-(void)loadListArr:(NSMutableArray *)arr
{
    self.DevListArr=[[NSMutableArray alloc]initWithArray:arr];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.myVideoListTabbleView reloadData];
        
    });
    
}
@end
