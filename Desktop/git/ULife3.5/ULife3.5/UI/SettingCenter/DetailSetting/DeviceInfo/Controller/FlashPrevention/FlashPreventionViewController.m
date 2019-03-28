//
//  FlashPreventionViewController.m
//  ULife3.5
//
//  Created by zhuochuncai on 12/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "FlashPreventionViewController.h"
#import "BaseCommand.h"
#import "NetSDK.h"
#import "FlashPreventionTableViewCell.h"


@interface FlashPreventionViewController ()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong)NetSDK *netSDK;
@property(nonatomic,strong)CMD_Device_NTSC_PAL *ntscData;
@property(nonatomic,strong)NTSCSettingResultBlock resultBlock;
@end

@implementation FlashPreventionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureTableView];
    [self configUI];
}

#pragma mark== <UI>
- (void)configUI{
    self.title = DPLocalizedString(@"Setting_DeviceInfo");
    self.view.backgroundColor = BACKCOLOR(238,238,238,1);
}

- (void)configureTableView{
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FlashPreventionTableViewCell" bundle:nil] forCellReuseIdentifier:@"FlashPreventionTableViewCell"];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView.scrollEnabled = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

#pragma mark ==<TableViewDelegate>

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 2;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
 
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    FlashPreventionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FlashPreventionTableViewCell" forIndexPath:indexPath];
    switch (indexPath.row) {
        case 0:
        {
            cell.titleLabel.text   = @"60HZ";
            [cell.selectImage setImage:[UIImage imageNamed:_hz==60?@"deleteBtnHeighLight":@"deleteBtnNormal"]];
            break;
        }
           
        case 1:
        {
            cell.titleLabel.text   = @"50HZ";
            [cell.selectImage setImage:[UIImage imageNamed:_hz==50?@"deleteBtnHeighLight":@"deleteBtnNormal"]];
            break;
        }
            
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self sendNTSCSettingRequestWithValue:indexPath.row==0?60:50];
}

#pragma mark -回调
-(void)didFinishSettingNTSCWithCallback:(NTSCSettingResultBlock)resultBlock{
 
    _resultBlock = resultBlock;
}

- (void)sendNTSCSettingRequestWithValue:(int)value{
    _netSDK = [NetSDK sharedInstance];
    CMD_SetDevice_NTSC_PALReq *req = [CMD_SetDevice_NTSC_PALReq new];
    req.Hz = value;
    __weak typeof(self) weakSelf = self;
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    [_netSDK net_sendBypassRequestWithUID:_model.DeviceId requestData:[req requestCMDData] timeout:5000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            weakSelf.ntscData = [CMD_Device_NTSC_PAL yy_modelWithDictionary:dict];
            weakSelf.hz = value;
            if (weakSelf.resultBlock) {
                weakSelf.resultBlock(value);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }
        [weakSelf dealWithOperationResultWithResult:result];
    }];

}


#pragma mark== <Network>

- (void)dealWithOperationResultWithResult:(int)result{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (result!=0) {
            [self.tableView reloadData];
            [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
        }else{
            [SVProgressHUD dismiss];
        }
    });
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
