//
//  DeviceNameSettingViewController.m
//  ULife3.5
//
//  Created by zhuochuncai on 12/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "DeviceNameSettingViewController.h"
#import "Masonry.h"

@interface DeviceNameSettingViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)NSArray *deviceNameArray;
@property(nonatomic,strong)ChangeNameBlock changeNameBlock;
@property(nonatomic,strong)UITextField *editNameTxtField;
@end

@implementation DeviceNameSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configUI];
    [self configureTableView];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark== <UI>
- (void)configUI{
    self.title = DPLocalizedString(@"DevInfo_DevName");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
    [self configNavigationItem];
}

- (void)configNavigationItem{
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame     = CGRectMake(0, 0, 60, 40);
    [doneBtn setTitle:DPLocalizedString(@"Setting_Done") forState:0];
    [doneBtn addTarget:self action:@selector(doneBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneBtn];

}

- (void)doneBtnClicked:(id)sender{
    
    NSString *name = [_editNameTxtField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (name.length <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"ADDDevice_Name_unull")];
        });
        return;
    }
    
    if (_changeNameBlock) {
        _changeNameBlock(self.editNameTxtField.text);
    }
}

- (void)configureTableView{
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DefaultNameTableViewCell"];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView.scrollEnabled = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}



-(NSArray*)deviceNameArray{
    if (!_deviceNameArray) {
        _deviceNameArray = [NSArray arrayWithObjects:@"DeviceName_Default_LivingRoom",@"DeviceName_Default_Bedroom", @"DeviceName_Default_BabysRoom",@"DeviceName_Default_Gate",@"DeviceName_Default_Garage",@"DeviceName_Default_Office",nil];
    }
    return _deviceNameArray;
}


#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return section==0?1:self.deviceNameArray.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 35;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return DPLocalizedString(@"DeviceName_CurrentName");
        case 1:
            return DPLocalizedString(@"DeviceName_DefaultName");
    }
    return nil;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultNameTableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultNameTableViewCell"];
    }
    
    if (indexPath.section == 0) {
        self.editNameTxtField = [[UITextField alloc]initWithFrame:CGRectMake(15, 10, 200, 30)];
        self.editNameTxtField.text = _subDevName?: _model.DeviceName;
        self.editNameTxtField.textAlignment = NSTextAlignmentLeft;
        
        [cell addSubview:self.editNameTxtField];
        [self.editNameTxtField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(cell);
            make.leading.equalTo(cell).offset(15);
            make.trailing.equalTo(cell).offset(-15);
        }];
    }else{
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 120, 30)];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:17];
        label.text = DPLocalizedString(self.deviceNameArray[indexPath.row]);
        
        [cell addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(cell);
            make.leading.equalTo(cell).offset(15);
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 1) {
        
        if (_changeNameBlock) {
            _changeNameBlock(DPLocalizedString(self.deviceNameArray[indexPath.row]));
        }
    }
}

- (void)didChangeDevNameCallback:(ChangeNameBlock)block{
    _changeNameBlock  = block;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
