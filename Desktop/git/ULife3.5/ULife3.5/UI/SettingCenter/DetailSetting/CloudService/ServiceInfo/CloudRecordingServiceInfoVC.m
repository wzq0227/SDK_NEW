//
//  CloudRecordingServiceInfoVC.m
//  ULife3.5
//
//  Created by Goscam on 2017/9/13.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "CloudRecordingServiceInfoVC.h"
#import "CloudServicePaymentTypeVC.h"
#import "Header.h"
#import "CloudServicePackageInfo.h"
#import "CSNetworkLib.h"
#import "Masonry.h"
#import "SaveDataModel.h"

@interface CloudRecordingServiceInfoVC ()<UITableViewDelegate,UITableViewDataSource>
{
}
@property (strong, nonatomic)   UIColor *storageDaysBtnBorderColor;

@property (assign, nonatomic)  StorageDays selectedStorageDays;

@property (assign, nonatomic)  PackageValidTime selectedPackageValidTimeType;

@property (strong, nonatomic)  CSPackageInfo *packageInfo;

@property (strong, nonatomic)  CSNetworkLib *csNetworkLib;

@property (strong, nonatomic)  NSString *csToken;

@property (strong, nonatomic)  NSMutableArray *serviceTypeArray;
@end

@implementation CloudRecordingServiceInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self configUI];
    
    [self addEvents];

    [self loadPackageTypes];
}

- (void)configUI{
    [self configBtns];
    [self configNaviBar];
    [self configTranslation];
}

- (void)configTranslation{
    [self.annualPaymentBtn setTitle:DPLocalizedString(@"PackageType_Annual") forState:UIControlStateNormal];
    [self.monthlyPaymentBtn setTitle:DPLocalizedString(@"PackageType_Monthly") forState:UIControlStateNormal];
    
    self.packageTypeLabel.text = DPLocalizedString(@"CS_Package_Type");
    self.storageDaysLabel.text = DPLocalizedString(@"CS_Package_StorageDays");

    [self.payBtn setTitle:DPLocalizedString(@"CS_Package_Pay") forState:UIControlStateNormal];
}

- (void)configNaviBar{
    self.navigationItem.titleView = [CommonlyUsedFounctions titleLabelWithStr:DPLocalizedString(@"Setting_CloudService")];
    //    self.title = DPLocalizedString(@"Setting_CloudService");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 40)]];
}



- (void)addEvents{
    [self addButtonClickAction];
}

- (void)addButtonClickAction{
    
    [self.decreaseBtn setTag:301];
    [self.decreaseBtn addTarget:self action:@selector(changePackageNumber:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.increaseBtn setTag:302];
    [self.increaseBtn addTarget:self action:@selector(changePackageNumber:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.monthlyPaymentBtn setTag:201];
    [self.monthlyPaymentBtn addTarget:self action:@selector(changePackageType:) forControlEvents:UIControlEventTouchUpInside];
    [self.annualPaymentBtn setTag:202];
    [self.annualPaymentBtn addTarget:self action:@selector(changePackageType:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.payBtn addTarget:self action:@selector(gotoPaymentVC:) forControlEvents:UIControlEventTouchUpInside];
}

//- (void)configTableView{
//    self.serviceTypeTableView.delegate = self;
//    self.serviceTypeTableView.dataSource = self;
//}
//#pragma mark UITableViewDataSource
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//    return self.serviceTypeArray.count;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
//
//    CSPackageInfo *info = [self.serviceTypeArray objectAtIndex:indexPath.row];
//
//    UITableViewCell *cell = [[UITableViewCell alloc] init];
//
//    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
//    label.textAlignment = NSTextAlignmentCenter;
//    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17];
//    label.text = info.planName;
//
//    [cell addSubview:label];
//    [label mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerY.equalTo(cell);
//        make.leading.equalTo(cell).offset(15);
//    }];
//    return cell;
//}
//
//
//#pragma mark UITableViewDelegate
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return 40;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
//    return 1;
//}
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
//    return 1;
//}
//
//- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    return nil;
//}
//
//- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
//    return nil;
//}
//
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    self.packageInfo = self.serviceTypeArray[indexPath.row];
//}

- (void)gotoPaymentVC:(id)sender{
    if (!_packageInfo) {
        return;
    }
    PackageType type = (PackageType)(3*_selectedPackageValidTimeType+_selectedStorageDays);
    
    CloudServicePaymentTypeVC *vc = [CloudServicePaymentTypeVC new];
    vc.deviceModel                   = _deviceModel;
    vc.packageInfo                = _packageInfo;
    vc.packageName                = [CloudServicePackageInfo packageNameWithPackageType: type];
    vc.packageCount               = _packageNumberBtn.titleLabel.text.intValue;
    vc.packageValidTime           = _selectedPackageValidTimeType;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark 加载套餐ID和价格
- (void)loadPackageTypes{

    self.csToken = [mUserDefaults objectForKey:USER_TOKEN];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api/cloudstore/cloudstore-service/plan?token=%@&username=%@", kCloud_IP,self.csToken,[SaveDataModel getUserName]];
    __weak typeof(self) wSelf = self;
    [[CSNetworkLib sharedInstance] requestWithURLStr:urlStr method:@"POST" result:^(int result, NSData *data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (result == 0) {
            NSArray *tempArray = dict[@"data"];
            for (int i=0; i<tempArray.count; i++) {
                CSPackageInfo *info = [CSPackageInfo yy_modelWithDictionary:tempArray[i]];
                if (!wSelf.serviceTypeArray) {
                    wSelf.serviceTypeArray = [NSMutableArray arrayWithCapacity:1];
                }
                [wSelf.serviceTypeArray addObject:info];
            }
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@",dict[@"message"]] ];
            });
        }
    }];
}

/**
 套餐类型
 */
- (void)changePackageType:(id)sender{
    UIButton *btn = (UIButton*)sender;
    int selectedIndex = btn.tag-201;
    _selectedPackageValidTimeType = selectedIndex;
    
    if (selectedIndex == 0) {
        [self.monthlyPaymentBtn setBackgroundColor:myColor];
        [self.annualPaymentBtn setBackgroundColor:[UIColor clearColor]];
    }else{
        [self.monthlyPaymentBtn setBackgroundColor: [UIColor clearColor] ];
        [self.annualPaymentBtn setBackgroundColor: myColor];
    }
}


/**
 套餐数量
 */
- (void)changePackageNumber:(id)sender{
    UIButton *btn = (UIButton*)sender;
    int number = btn.tag==301?(-1):1;
    
    int packageNum = [self.packageNumberBtn.titleLabel.text intValue] + number;
    if (packageNum < 0) {
        packageNum = 0;
    }
    [self.packageNumberBtn setTitle: [@(packageNum) stringValue] forState:0];
    
}

/**
 选择存储天数3,7,30
 */
- (void)changeStorageDays:(id)sender{
    UIButton *btn = (UIButton*)sender;
    int selectedIndex = btn.tag-100;
    
    for (int i=0; i<self.storageDaysArray.count; i++) {
        UIButton *aBtn = self.storageDaysArray[i];
        UIColor *aColor = [UIColor clearColor];
        if (i==selectedIndex) {
            aColor = myColor;
        }
        [aBtn setBackgroundColor:aColor];
    }
    
    switch (selectedIndex) {
        case 0:
            _selectedStorageDays = StorageDays3;
            break;
        case 1:
            _selectedStorageDays = StorageDays7;
            break;
        case 2:
            _selectedStorageDays = StorageDays30;
            break;
        default:
            break;
    }
    self.packageInfo = self.serviceTypeArray[_selectedStorageDays];
}

- (UIColor*)storageDaysBtnBorderColor{
    if (!_storageDaysBtnBorderColor) {
        _storageDaysBtnBorderColor = BACKCOLOR(127, 127, 127, 1);
    }
    return _storageDaysBtnBorderColor;
}

- (void)configStorageDaysBtn{
    
    for (NSInteger i=0; i<self.storageDaysArray.count; i++) {
        UIButton *btn = self.storageDaysArray[i];
        
        switch (i) {
            case 0:
                [btn setTitle:DPLocalizedString(@"Package_StorageDays3") forState:0];
                break;
                
            case 1:
                [btn setTitle:DPLocalizedString(@"Package_StorageDays7") forState:0];
                break;
                
            case 2:
                [btn setTitle:DPLocalizedString(@"Package_StorageDays30") forState:0];
                break;
            default:
                break;
        }
        
        [btn setTag:(i+100)];
        [btn addTarget:self action:@selector(changeStorageDays:) forControlEvents:UIControlEventTouchUpInside];
        [self configBtnBorderWithBtn:btn];
    }
}

- (void)configBtnBorderWithBtn:(UIButton*)btn{
    btn.layer.borderWidth =1;
    btn.layer.borderColor = self.storageDaysBtnBorderColor.CGColor;
}

- (void)configBtns{
    
    [self configStorageDaysBtn];
    
    [self configBtnBorderWithBtn: self.annualPaymentBtn];
    [self configBtnBorderWithBtn: self.monthlyPaymentBtn];
    
    [self configBtnBorderWithBtn: self.increaseBtn];
    [self configBtnBorderWithBtn: self.decreaseBtn];
    [self configBtnBorderWithBtn: self.packageNumberBtn];
    
    self.payBtn.layer.cornerRadius = 20;
}



@end
