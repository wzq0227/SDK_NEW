//
//  SubDevInfoVC.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/9.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "SubDevInfoVC.h"
#import "Masonry.h"

@interface SubDevInfoVC ()
<UITableViewDelegate,UITableViewDataSource>
{
    
}

@property (strong, nonatomic)  UITableView *tableView;

@end

@implementation SubDevInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configUI];
    
    [self configModel];
    
    [self addActions];
}

- (void)configUI{
    [self configNavigationBar];
    
    [self configButtons];
    
    [self configView];
}

- (void)configModel{
}

- (void)configNavigationBar{
    self.title = DPLocalizedString(@"APAdd_APMode");
}

- (void)configButtons{
   
}

- (void)configView{
    UIColor *customGrayColor = BACKCOLOR(238,238,238,1);
    self.view.backgroundColor = customGrayColor;
}

- (void)configTableView{
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)addActions{
    
//    [_nextBtn addTarget:self action:@selector(nextBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(changeWifi)
//                                                 name:CHANGE_WIFI_BACK
//                                               object:nil];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger numRows = 0;
    switch (section) {
        case 0:
        {
            numRows = 1;
            break;
        }
        case 1:
        {
            numRows = 2;
            break;
        }
        case 2:
        {
            numRows = 2;
            break;
        }
        case 3:
        {
            numRows = 1;
            break;
        }
        default:
            break;
    }
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    NSInteger headerHeight = 8;
    switch (section) {
        case 0:
        {
            headerHeight = 20;
            break;
        }
        case 1:
        {
            headerHeight = 8;
            break;
        }
        case 2:
        {
            headerHeight = 20;
            break;
        }
        case 3:
        {
            headerHeight = 40;
            break;
        }
        default:
            break;
    }
    return headerHeight;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    switch (section) {
        case 0:
            return DPLocalizedString(@"DevInfo_DevName");
        case 1:
            return @" ";
        case 2:
            return DPLocalizedString(@"DevInfo_CameraInfo");
        case 3:
            return @" ";
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}


@end
