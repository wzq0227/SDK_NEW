//
//  CSOrderDetailDeviceBottomView.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/24.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "CSOrderDetailDeviceBottomView.h"

#define kCellIdentifier (@"PurchasedPackagesCellIdentifier")

@interface CSOrderDetailDeviceBottomView()
<UITableViewDataSource,UITableViewDelegate>
{
}

@property (strong, nonatomic)  UITableView *tableView;

@property (strong, nonatomic)  SelectCellCallbackBlock selectCallback;

@end

@implementation PurchasedPackageInfo
@end

@implementation CSOrderDetailDeviceBottomView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//        [self configTableView];
    }
    return self;
}


- (void)selectCellCallback:(SelectCellCallbackBlock)aCallbackBlock{
    self.selectCallback = aCallbackBlock;
    
    [self configTableView];
}

- (void)setPurchasedPackages:(NSArray<PurchasedPackageInfo *> *)purchasedPackages{
    NSLog(@"___________________________setPurchasedPackages");
    _purchasedPackages = purchasedPackages;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)configTableView{
    
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStyleGrouped];
    
    self.backgroundColor = _tableView.backgroundColor = [UIColor whiteColor];

    _tableView.delegate =self;
    _tableView.dataSource = self;
    _tableView.tableHeaderView.backgroundColor = [UIColor clearColor] ;
    
    [self addSubview: _tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self);
        make.top.equalTo(self).mas_offset(20);
    }];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.purchasedPackages.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellIdentifier];
    }
    bool smallScreenIphone = SCREEN_WIDTH<321;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:smallScreenIphone?13:15];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    
    cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:smallScreenIphone?11:12];
    cell.detailTextLabel.numberOfLines = 0;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.purchasedPackages[indexPath.row].dataLife;
    cell.detailTextLabel.text = self.purchasedPackages[indexPath.row].validTime;
    
    return cell;
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    !_selectCallback?:_selectCallback(indexPath.row);
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return _purchasedPackages.count<=0?@"":DPLocalizedString(@"CSOrder_PurchasedPackages");
}

@end
