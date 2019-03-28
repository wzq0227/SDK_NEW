//
//  BabyMusicSettingViewController.m
//  ULife3.5
//
//  Created by AnDong on 2017/8/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "BabyMusicSettingViewController.h"
#import "BabyMusicCell.h"
#import "SimpleAudioPlayer.h"
#import "BaseCommand.h"
#import "NetSDK.h"
#import "UISettingManagement.h"

@interface BabyMusicSettingViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong)NSArray *musicArray;

@property (nonatomic,strong)UITableView *tableView;

@property (nonatomic,strong)UIButton *rightNavButton;

@property (nonatomic,assign)NSUInteger selectIndex;

@property (nonatomic,strong)SimpleAudioPlayer *audioPlayer;

//原始设置
@property (nonatomic,assign)NSUInteger originalIndex;

@end

@implementation BabyMusicSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _selectIndex = 0;
    _originalIndex = 0;
    [self setupUI];
    //获取当前设置摇篮曲数据
    [self getData];

}

- (void)getData{
    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    CMD_GetBabyMusicReq *req = [[CMD_GetBabyMusicReq alloc]init];
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceID requestData:[req yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        UISettingModel *model = [[UISettingManagement sharedInstance] getSettingModel:weakSelf.deviceID];
        int index;
        if (model.ability_babyMusic == 1) {
            index = 13;
        }
        else if (model.ability_babyMusic == 2){
            index = 19;
        }
        else{
            index = 7;
        }
        
        //默认是13
        if (result == 0) {
            int num = [dict[@"alarm_ring_no"] intValue];
            if (num > 0) {
                num = num - index;
                _selectIndex = num;
                _originalIndex = num;
                dispatch_async_on_main_queue(^{
                    [SVProgressHUD dismiss];
                    [self.tableView reloadData];
                });
            }
        }
        else{
            dispatch_async_on_main_queue(^{
                [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Get_data_failed")];
            });
          
        }
        
    }];
}


- (void)viewWillDisappear:(BOOL)animated{
    [self.audioPlayer stop];
}

- (void)setupUI{
    self.title = DPLocalizedString(@"Setting_BabyMusic");
    self.view.backgroundColor = [UIColor whiteColor];
    [self configNavItem];
    [self.view addSubview:self.tableView];
}

- (void)configNavItem{
    UIImage *image = [UIImage imageNamed:@"addev_back"];
    EnlargeClickButton *button = [EnlargeClickButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 70, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 50);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(navBack)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    leftBarButtonItem.style = UIBarButtonItemStylePlain;
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    
    UIButton* doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    doneButton.frame = CGRectMake(0.0, 0.0, 75, 40);
    doneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [doneButton setTitle:DPLocalizedString(@"Setting_Done") forState:UIControlStateNormal];
    [doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(finishSetting) forControlEvents:UIControlEventTouchUpInside];
    doneButton.exclusiveTouch = YES;
    UIBarButtonItem *infotemporaryBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
    infotemporaryBarButtonItem.style = UIBarButtonItemStylePlain;
    self.rightNavButton = doneButton;
    self.navigationItem.rightBarButtonItem=infotemporaryBarButtonItem;
}


- (void)navBack{
    if (_originalIndex != _selectIndex) {
        //发生了设置更改弹窗
        UIAlertController *alertView = [UIAlertController alertControllerWithTitle:nil
                             message:DPLocalizedString(@"Setting_Save_title")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Save_YES")
                                                              style:UIAlertActionStyleDestructive
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                [self finishSetting];
                                                            }];
        
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:DPLocalizedString(@"Setting_Cancel")
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 [self.navigationController popViewControllerAnimated:YES];
                                                             }];
        [alertView addAction:confirmAction];
        [alertView addAction:cancelAction];
        [self presentViewController:alertView
                           animated:YES
                         completion:nil];
        
    }else{
        //直接返回
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 6;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    BabyMusicCell *cell = [[BabyMusicCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    if(indexPath.row == _selectIndex){
        cell.rightImgView.image = [UIImage imageNamed:@"deleteBtnHeighLight"];
    }
    else{
        cell.rightImgView.image = [UIImage imageNamed:@"deleteBtnNormal"];
    }
    cell.myTitleLabel.text = self.musicArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    _selectIndex = indexPath.row;
    [tableView reloadData];
    [self switchPlayMusic];
}


- (void)switchPlayMusic{
    NSString *path = [[NSBundle mainBundle] pathForResource:self.musicArray[_selectIndex] ofType:@"aac"];
    if (_audioPlayer) {
        [_audioPlayer stop];
    }
    //开始播放
    self.audioPlayer = [self.audioPlayer initWithAudio:path];
}


#pragma mark - Event Handle


//完成设置
- (void)finishSetting{

    [SVProgressHUD showWithStatus:DPLocalizedString(@"loading")];
    
    CMD_SetBabyMusicReq *req = [[CMD_SetBabyMusicReq alloc]init];
    
    NSInteger index = 0;
    
     UISettingModel *model = [[UISettingManagement sharedInstance] getSettingModel:self.deviceID];
    
    if (model.ability_babyMusic == 1) {
        index = 13;
    }
    else if (model.ability_babyMusic == 2){
        index = 19;
    }
    else{
        index = 7;
    }
    
    
    req.alarm_ring_no = (int)(_selectIndex + index);
    
    [[NetSDK sharedInstance] net_sendBypassRequestWithUID:self.deviceID requestData:[req yy_modelToJSONObject] timeout:8000 responseBlock:^(int result, NSDictionary *dict) {
        if (result == 0) {
            [SVProgressHUD showSuccessWithStatus:DPLocalizedString(@"Operation_Succeeded")];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
        else{
            dispatch_async_on_main_queue(^{
              [SVProgressHUD showErrorWithStatus:DPLocalizedString(@"Operation_Failed")];
            });
        }
    }];
    
}


#pragma mark - getter

- (SimpleAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        _audioPlayer = [[SimpleAudioPlayer alloc] init];
    }
    return _audioPlayer;
}


- (NSArray *)musicArray{
    if (!_musicArray) {
        
        //获取能力集
        
        UISettingModel *model = [[UISettingManagement sharedInstance] getSettingModel:self.deviceID];
        
        if (model.ability_babyMusic == 1) {
          _musicArray = @[@"twinklepiano",@"Little Mozart",@"Relax",@"birds_sream_nature_forest_loop",@"Brahms Lullaby",@"Bedtime Lullaby"];
        }
        else{
            _musicArray = @[@"I_dont_want_to_miss_a_thing",@"Holiday",@"Jolene",@"Rain",@"Waves",@"Pink_noise"];
        }
        
        
        
    }
    return _musicArray;
}


- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

@end
