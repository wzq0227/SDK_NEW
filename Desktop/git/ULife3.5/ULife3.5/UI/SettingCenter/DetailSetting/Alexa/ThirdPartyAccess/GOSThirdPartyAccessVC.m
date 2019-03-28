//
//  GOSThirdPartyAccessVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/6/22.
//  Copyright © 2018 GosCam. All rights reserved.
//

#import "GOSThirdPartyAccessVC.h"

#import "ThirdPartyAccessTableViewCell.h"

#define MCellIdentifier (@"ThirdPartyAccessTableViewCell")

@interface ThirdPartyModel:NSObject

@property (nonatomic, assign)  AccessThirdPartySupport support;

@property (nonatomic, strong)  NSString *imageName;

@property (nonatomic, strong)  NSString *btnTitleName;

@property (nonatomic, strong)  NSString *btnActionURLStr;

@property (nonatomic, strong)  NSString *settingGuideURLStr;

@end



@implementation ThirdPartyModel
@end


@interface GOSThirdPartyAccessVC ()
<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong)  NSMutableArray <ThirdPartyModel*>*supportModelArray;

@property (nonatomic, strong)  UITableView *tableView;

@end

@implementation GOSThirdPartyAccessVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configView];
}

- (void)configView{
    
    self.title = MLocalizedString(Setting_Alexa);
    
    [self configTableView];
}

- (void)configTableView{
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.tableView.scrollEnabled = NO;
    self.tableView.backgroundColor = mCustomBgColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:MCellIdentifier bundle:nil] forCellReuseIdentifier:MCellIdentifier];
}


#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return self.supportModelArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    ThirdPartyAccessTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MCellIdentifier forIndexPath:indexPath];
    
    ThirdPartyModel *model = self.supportModelArray[indexPath.section];
    
    cell.backgroundColor = mCustomBgColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    
    cell.iconImgView.image = [UIImage imageNamed:model.imageName ];
    
    //540*530
    //370*150 alexa
    //500*130 google
    
    CGFloat leftConstraintV = (model.support==AccessThirdPartySupport_GoogleHome?75:145)/2*SCREEN_WIDTH_RATIO;
    CGFloat topConstraintV = (model.support==AccessThirdPartySupport_GoogleHome ? 72 : 54)/2*SCREEN_WIDTH_RATIO;
    CGFloat bottomConstraintV = (model.support==AccessThirdPartySupport_GoogleHome ? 136 :142)/2*SCREEN_WIDTH_RATIO;

    [cell.iconImgView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(leftConstraintV);
        make.centerX.mas_equalTo(cell);
        make.top.mas_equalTo(topConstraintV);
        make.bottom.mas_equalTo(-bottomConstraintV);
    }];
    
    [cell.settingGuideBtn setTitle:MLocalizedString(ThirdParty_SettingGuide) forState:0];
    [cell.jumpToThirdPartyBtn setTitle:DPLocalizedString(model.btnTitleName) forState:0];
    
    [cell.settingGuideBtn setTitleColor:myColor forState:0];
    [cell.jumpToThirdPartyBtn setTitleColor:UIColor.whiteColor forState:0] ;


    cell.settingGuideBtn.tag = 100+indexPath.section;
    [cell.settingGuideBtn addTarget:self action:@selector(settingGuideBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.jumpToThirdPartyBtn.backgroundColor = myColor;
    cell.jumpToThirdPartyBtn.layer.cornerRadius = cell.jumpToThirdPartyBtn.height/2;
    
    cell.jumpToThirdPartyBtn.tag = 100+indexPath.section;
    [cell.jumpToThirdPartyBtn addTarget:self action:@selector(jumpToThirdPartyBtnAction:) forControlEvents:UIControlEventTouchUpInside];

    
    return cell;
}

- (void)settingGuideBtnAction:(UIButton*)btn{
    int section = btn.tag - 100;
    
    if (section >= self.supportModelArray.count) {
        return;
    }
    ThirdPartyModel *model = self.supportModelArray[ section ];
    
    NSURL *url = [NSURL URLWithString: model.settingGuideURLStr];
    if ([[UIApplication sharedApplication]canOpenURL:url]) {
        [[UIApplication sharedApplication]openURL:url];
    }
}

- (void)jumpToThirdPartyBtnAction:(UIButton*)btn{
    
    int section = btn.tag - 100;
    
    if (section >= self.supportModelArray.count) {
        return;
    }
    ThirdPartyModel *model = self.supportModelArray[ section ];
    
    NSURL *url = [NSURL URLWithString: model.btnActionURLStr];
    if ([[UIApplication sharedApplication]canOpenURL:url]) {
        [[UIApplication sharedApplication]openURL:url];
    }
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat rowHeight = SCREEN_WIDTH_RATIO*535/2;
    return rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}


- (NSMutableArray *)supportModelArray{
    if (!_supportModelArray) {
        _supportModelArray = [NSMutableArray arrayWithCapacity:1];
        
        if ( (_thirdPartySupport &0x2) == AccessThirdPartySupport_Show || (_thirdPartySupport &0x1) == AccessThirdPartySupport_Echo){
            
            ThirdPartyModel *model = [ThirdPartyModel new];
            
            model.support = AccessThirdPartySupport_Echo | AccessThirdPartySupport_Show;
            model.imageName = @"ThirdParty_Alexa";
            model.btnTitleName = MLocalizedString(ThirdParty_Btn_Alexa_Title);
            model.btnActionURLStr = @"https://skills-store.amazon.com/deeplink/dp/B07D74ZW4W?deviceType=app&share&refSuffix=ss_copy";
            model.settingGuideURLStr = @"http://ulifecam.com/userguide";
            
            [_supportModelArray addObject: model];
        }
       
        if ( (_thirdPartySupport & 0x4 ) == AccessThirdPartySupport_GoogleHome ) {
            
            ThirdPartyModel *model = [ThirdPartyModel new];
            
            model.support = AccessThirdPartySupport_GoogleHome;
            model.imageName = @"ThirdParty_GoogleHome";
            model.btnTitleName = MLocalizedString(ThirdParty_Btn_GoogleHome_Title);;
            model.btnActionURLStr = @"https://skills-store.amazon.com/deeplink/dp/B07D74ZW4W?deviceType=app&share&refSuffix=ss_copy";
            model.settingGuideURLStr = @"http://ulifecam.com/userguide";

            [_supportModelArray addObject: model];
        }
    }
    return _supportModelArray;
}

@end
