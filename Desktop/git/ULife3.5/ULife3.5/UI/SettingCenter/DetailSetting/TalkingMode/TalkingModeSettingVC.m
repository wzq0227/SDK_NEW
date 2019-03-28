//
//  TalkingModeSettingVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/6/14.
//  Copyright © 2018 GosCam. All rights reserved.
//

#import "TalkingModeSettingVC.h"

#define MTalkingModeSettingCell (@"MTalkingModeSettingCell")

@interface TalkingModeSettingVC ()
<UITableViewDelegate,UITableViewDataSource>
{
    
}

@property (nonatomic, strong)  UITableView *tableView;

@property (nonatomic, strong)  NSMutableArray<UIImageView*> *selectedImgViews;

@end

@implementation TalkingModeSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self configUI];

    [self configModel];

}

- (void)configUI{
    [self configNavigationBar];
    
    [self configView];
    
    [self configTableView];
}

- (void)configModel{
    
}

- (void)configNavigationBar{
    self.title = DPLocalizedString(@"Setting_TalkingMode");
}



- (void)configView{
    UIColor *customGrayColor = BACKCOLOR(238,238,238,1);
    self.view.backgroundColor = customGrayColor;
}

- (void)configTableView{
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStyleGrouped];
    _tableView.delegate =self;
    _tableView.dataSource = self;
    _tableView.scrollEnabled = NO;

    
    [self.view addSubview: _tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:MTalkingModeSettingCell];
}



#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MTalkingModeSettingCell forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MTalkingModeSettingCell];
    }
    
    /* plist字段不存在情况下： 支持全双工能力集 默认全双工 */
    NSString *talkingModeStr = [mUserDefaults stringForKey:[@"TalkingMode_" stringByAppendingString:self.deviceID]]?:@"FullDuplex";
    BOOL cellSelected = false;

    if (indexPath.section == 0) {//半双工
        cell.textLabel.text = MLocalizedString(Setting_TalkingMode_HalfDuplex);
        cell.imageView.image = [UIImage imageNamed:@"Setting_CameraMicrophone"];
        cellSelected = [talkingModeStr isEqualToString:@"HalfDuplex"];
    }else{//全双工
        cell.textLabel.text = MLocalizedString(Setting_TalkingMode_FullDuplex);
        cell.imageView.image = [UIImage imageNamed:@"Setting_TalkingMode"];
        cellSelected = [talkingModeStr isEqualToString:@"FullDuplex"];
    }
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    if (self.selectedImgViews.count < 2) {
        
        UIImage *selectImage = [UIImage imageNamed: cellSelected?@"Setting_Temp_Selected": @"Setting_Temp_Deselected"];
        UIImageView *selectImgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)];
        selectImgView.image = selectImage;
        
        [cell.contentView addSubview: selectImgView];
        [selectImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(cell.contentView);
            make.trailing.equalTo(cell.contentView).mas_offset(-15);
            make.width.height.mas_equalTo(20);
        }];
        
        [self.selectedImgViews addObject: selectImgView];
    }else{
        UIImage *selectImage = [UIImage imageNamed: cellSelected?@"Setting_Temp_Selected": @"Setting_Temp_Deselected"];
        self.selectedImgViews[indexPath.section].image = selectImage;
    }
    
    return cell;
}



- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 70)];
    NSString *titleStr = nil;
    if (section == 0) {
        titleStr = MLocalizedString(Setting_TalkingMode_HalfDuplex_Tip);
    }else{
        titleStr = MLocalizedString(Setting_TalkingMode_FullDuplex_Tip);
    }
    UILabel *label = [self titleLabelForString: titleStr];
    [view addSubview: label];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(5);
        make.leading.mas_equalTo(15);
        make.trailing.mas_offset(-15);
//        make.bottom.mas_equalTo(-5);
    }];
    
    return view ;
}

- (UILabel *)titleLabelForString:(NSString*)str{
    UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 60)];
    
    [tempLabel sizeToFit];
    tempLabel.text                      = str;
    tempLabel.numberOfLines             = 4;
    tempLabel.adjustsFontSizeToFitWidth = YES;
    tempLabel.textAlignment             = NSTextAlignmentLeft;
    tempLabel.textColor                 = [UIColor lightGrayColor];
    tempLabel.font                      = [UIFont systemFontOfSize: 13 ];
    
    return tempLabel;
}

//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
//    NSString *titleStr = nil;
//    if (section == 0) {
//        titleStr = MLocalizedString(Setting_TalkingMode_HalfDuplex_Tip);
//    }else{
//        titleStr = MLocalizedString(Setting_TalkingMode_FullDuplex_Tip);
//    }
//    return titleStr;
//
//}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *talkingModeStr = (indexPath.section == 0) ? @"HalfDuplex":@"FullDuplex";
    [mUserDefaults setObject:talkingModeStr forKey:[@"TalkingMode_" stringByAppendingString:self.deviceID]];
    [mUserDefaults synchronize];
    
    [self.tableView reloadData];
}


- (NSMutableArray*)selectedImgViews{
    if (!_selectedImgViews) {
        _selectedImgViews = [NSMutableArray arrayWithCapacity:1];
    }
    return _selectedImgViews;
}

@end
