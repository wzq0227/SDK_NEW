//
//  APModeConfigShowWiFiListVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/9/25.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "APModeConfigShowWiFiListVC.h"
#import "Masonry.h"

@interface APModeConfigShowWiFiListVC ()<UITableViewDataSource,UITableViewDelegate>

@end

@implementation APModeConfigShowWiFiListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
}

- (void)configUI{
    [self configNavigationBar];
    
    [self configTableView];
    
    [self configView];
}

- (void)configNavigationBar{
    self.title = DPLocalizedString(@"");
}

- (void)configTableView{
    self.wifiListTableView.delegate = self;
    self.wifiListTableView.dataSource = self;
}

- (void)configView{
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);;
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _wifiListInfo.totalcount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WifiInfoN info = _wifiListInfo.plist[indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
    label.textAlignment = NSTextAlignmentLeft;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17];
    label.text = [NSString stringWithUTF8String:info.wifiSsid] ;
    
    [cell addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(cell);
        make.leading.equalTo(cell).offset(15);
    }];
    
    int level = ((info.signalLevel+10)/30)%4;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 10, 30, 30)];
    imageView.image        =  [UIImage imageNamed:[NSString stringWithFormat:@"WiFiSignal_Level_%d.png",level]];
    [cell addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(cell);
        make.trailing.equalTo(cell).offset(-15);
        make.height.mas_equalTo(15);
        make.width.equalTo(imageView.mas_height);
    }];
    
    return cell;
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.5;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.5;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
