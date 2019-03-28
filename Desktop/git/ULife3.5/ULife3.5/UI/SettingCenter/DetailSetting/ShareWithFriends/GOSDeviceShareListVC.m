//
//  GOSDeviceShareListVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/5/18.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "GOSDeviceShareListVC.h"
#import "AddDeviceManager.h"
#import "SaveDataModel.h"

#import "NetSDK.h"
#import "CBSCommand.h"
#import "UIColor+YYAdd.h"


@interface GOSDeviceShareListCell:UITableViewCell

@property (nonatomic, strong)  UILabel *accountLabel;

@property (nonatomic, strong)  UIButton *cancelShareBtn;

@end

@implementation GOSDeviceShareListCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self addSubViews];
        [self makeConstraints];
    }
    return self;
}

- (void)addSubViews{
    [self addSubview: self.cancelShareBtn];
    [self addSubview: self.accountLabel];
}

- (void)makeConstraints{
    [self.cancelShareBtn mas_makeConstraints:^(MASConstraintMaker *make) {

        make.centerY.equalTo(self);
        make.trailing.equalTo(self).mas_offset(-15);
        make.height.mas_equalTo(34);
        make.width.mas_equalTo(110);
    }];
    
    
    [self.accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self);
        make.leading.equalTo(self).mas_offset(15);
        make.trailing.equalTo(self.cancelShareBtn.mas_leading).mas_offset(-2);
    }];
}


- (UIButton*)cancelShareBtn{
    if (!_cancelShareBtn) {
        _cancelShareBtn = [UIButton new];
        _cancelShareBtn.backgroundColor = UIColorFromRGBA(240,133,25,1);
        _cancelShareBtn.layer.cornerRadius = 17;
        _cancelShareBtn.titleLabel.numberOfLines = 2;
        _cancelShareBtn.titleLabel.font = [UIFont systemFontOfSize: SCREEN_WIDTH>320?15:13];//
        _cancelShareBtn.titleLabel.adjustsFontSizeToFitWidth = YES;

        [_cancelShareBtn setTitle:MLocalizedString(DevShare_StopSharing) forState:0];
//        [_cancelShareBtn addTarget:self action:@selector(cancelShareBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelShareBtn;
}

- (UILabel*)accountLabel{
    if (!_accountLabel) {
        _accountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 30)];
        _accountLabel.adjustsFontSizeToFitWidth = YES;
        _accountLabel.font = [UIFont systemFontOfSize: SCREEN_WIDTH>320?16:13];
        _accountLabel.numberOfLines = 2;
    }
    return _accountLabel;
}

@end


@interface GOSDeviceShareListVC ()
<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>
{
    
}

//设备分享给了哪些用户
@property (strong, nonatomic) NSMutableArray *shareList;

@property (strong, nonatomic)  UIButton *confirmBtn;

@property (strong, nonatomic)  UITextField *usernameTxt;

@property (strong, nonatomic)  UITableView *tableView;
// CBS_GetDeviceShareListResponse *devShareListResp;


@end


#define kCellId  @"GOSDeviceShareListCell"

@implementation GOSDeviceShareListVC




- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
    [self configUI];
    
    [self loadShareList];
}

- (void)configUI{
    
    [self configNavi];
    
    [self addSubViews];
    [self makeConstraints];
    
    [self configTableView];
}

- (void)configNavi{
    self.title = MLocalizedString(Setting_ShareWithFriends);
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)addSubViews{
    [self.view addSubview: self.confirmBtn];
    [self.view addSubview: self.usernameTxt];
}

- (void)viewWillAppear:(BOOL)animated{
    
    [self addNotifications];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [self removeNotifications];
}

- (void)makeConstraints{
    
    [self.usernameTxt mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).mas_offset(30);
        make.centerX.equalTo(self.view);
        make.left.equalTo(self.view).mas_offset(15);
        make.height.mas_equalTo(50);
    }];
    
    [self.confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameTxt.mas_bottom).mas_offset(50);
        make.centerX.equalTo(self.view);
        make.left.equalTo(self.view).mas_offset(15);
        make.height.mas_equalTo(44);
    }];
}



- (void)configTableView{
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStyleGrouped];
    [_tableView registerClass:[GOSDeviceShareListCell class] forCellReuseIdentifier:kCellId];
    _tableView.delegate =self;
    _tableView.dataSource = self;
    _tableView.hidden = YES;
    _tableView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview: _tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.confirmBtn.mas_bottom).mas_offset(50);
        make.bottom.leading.trailing.equalTo(self.view);
    }];
}


#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int rowsCnt = (int)self.shareList.count;
    tableView.hidden = rowsCnt==0;
    return rowsCnt;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    GOSDeviceShareListCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId forIndexPath:indexPath];
    
    cell.accountLabel.text = [@"ID:" stringByAppendingString:self.shareList[indexPath.row]] ;
   
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.cancelShareBtn.tag = indexPath.row;
    [cell.cancelShareBtn addTarget:self action:@selector(cancelShareBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return MLocalizedString(DevShare_Title_SharedUsers);
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}

//TxtDelegate
- (void)addNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textValueChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)removeNotifications{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)textValueChanged:(id)sender{
    
    self.confirmBtn.userInteractionEnabled = self.usernameTxt.text.length > 0 ;
    self.confirmBtn.alpha = self.usernameTxt.text.length>0 ? 1: 0.5;
}

//MARK:- Events
- (void)confirmBtnClicked:(id)sender{
    
    __block bool shareExist = NO;
    [self.shareList enumerateObjectsUsingBlock:^(NSString   * _Nonnull  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isEqualToString:_usernameTxt.text]) {
            shareExist = YES;
            *stop=YES;
        }
    }];
    
    if (shareExist) {
        [SVProgressHUD showInfoWithStatus:MLocalizedString(ADDDevice_Already_Added)];
        return;
    }
    
    [self addShareWithUserName:_usernameTxt.text];
}

- (void)cancelShareBtnClicked:(UIButton*)sender{
    int index = (int)sender.tag;
    NSString *removedUserName = self.shareList[index];
    
    [self removeShareWithUserName:removedUserName];
}

- (void)loadShareList{
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    BodyGetDeviceShareListRequest *body = [BodyGetDeviceShareListRequest new];
    CBS_GetDeviceShareListRequest *req = [CBS_GetDeviceShareListRequest new];
    
    body.DeviceId = self.devId;
//    body.UserName = [SaveDataModel getUserName];
    req.Body = body;
    
    __weak typeof(self) wSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        
        if(result == 0){
            CBS_GetDeviceShareListResponse *resp = [CBS_GetDeviceShareListResponse yy_modelWithDictionary:dict];
            wSelf.shareList = [resp.Body.UserList mutableCopy];
            
            dispatch_async_on_main_queue(^{
                [wSelf.tableView reloadData];
            });
        }
        [GOSUIManager showGetOperationResult:result];
    }];
}



- (void)addShareWithUserName:(NSString*)userName{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    //shareDevice
    
    __weak typeof(self) wSelf = self;
    [AddDeviceManager shareDevice:_devModel toOthers:userName result:^(ShareDevToOthersResult result) {
        if (result == 0) {
            [wSelf.shareList  addObject:userName];
            dispatch_async(dispatch_get_main_queue(), ^{
                wSelf.usernameTxt.text = @"";
                [wSelf.usernameTxt resignFirstResponder];
                [wSelf.tableView reloadData];
            });
        }
    }];
}



//后面再加 移除分享的设备的推送
- (void)removeShareWithUserName:(NSString*)userName{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [SVProgressHUD showWithStatus:@"Loading..."];
    });
    
    BodyUnbindRequest *body = [BodyUnbindRequest new];
    CBS_UnbindRequest *req  = [CBS_UnbindRequest new];
    body.DeviceId           = self.devId;
    body.UserName           = userName;
    body.DeviceOwner        = 0;
    req.Body = body;
    
    __weak typeof(self) weakSelf = self;
    [[NetSDK sharedInstance] net_sendCBSRequestMsgType:req.MessageType bodyData:[body yy_modelToJSONObject] timeout:12000 responseBlock:^(int result, NSDictionary *dict) {
        
        if (result ==0 ) {
            
            [self.shareList  removeObject:userName];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        [GOSUIManager showSetOperationResult:result];
    }];
}



- (void)setDevModel:(DeviceDataModel *)devModel{
    _devModel = devModel;
    _devId = _devModel.DeviceId;
}

//MARK:- getters
- (UIButton*)confirmBtn{
    if (!_confirmBtn) {
        _confirmBtn = [UIButton new];
        _confirmBtn.backgroundColor = myColor;
        _confirmBtn.layer.cornerRadius = 22;
        _confirmBtn.alpha = 0.5;
        _confirmBtn.userInteractionEnabled = NO;
        
        [_confirmBtn setTitle:MLocalizedString(Title_Confirm) forState:0];
        [_confirmBtn setTitleColor:[UIColor whiteColor] forState:0];
        
        [_confirmBtn addTarget:self action:@selector(confirmBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmBtn;
}


- (UITextField*)usernameTxt{
    if (!_usernameTxt) {
        _usernameTxt = [UITextField new];
        _usernameTxt.delegate = self;
        _usernameTxt.backgroundColor = [UIColor whiteColor];
        _usernameTxt.placeholder = MLocalizedString(DevShare_InputUserName);
        _usernameTxt.borderStyle = UITextBorderStyleRoundedRect;
        //_usernameTxt.hidden = YES;
    }
    return _usernameTxt;
}

@end
