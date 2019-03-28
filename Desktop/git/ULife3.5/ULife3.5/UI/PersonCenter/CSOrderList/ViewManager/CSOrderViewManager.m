//
//  CSOrderViewManager.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "CSOrderViewManager.h"
#import "CSOrderDeviceListCell.h"

#define kCellIdentifier (@"CSOrderDeviceListCell")

@interface CSOrderViewManager()
<UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic)  UITableView *tableView;

@property (strong, nonatomic)  SelectCellCallbackBlock selectCallback;
@end

@implementation CSOrderViewManager

- (void)selectCellCallback:(SelectCellCallbackBlock)aCallbackBlock{
    self.selectCallback = aCallbackBlock;
    
    [self configTableView];
}

- (void)setDevicesArray:(NSArray<CSOrderDeviceListCellModel *> *)devicesArray{
    _devicesArray = devicesArray;
    [self.tableView reloadData];
}

- (void)configTableView{
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStyleGrouped];
    
    _tableView.delegate =self;
    _tableView.dataSource = self;
    [_tableView registerClass:[CSOrderDeviceListCell class] forCellReuseIdentifier:kCellIdentifier];
    
    [self addSubview: _tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).mas_offset(0);
        make.leading.trailing.equalTo(self);
        make.bottom.equalTo(self);
    }];
    
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.devicesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CSOrderDeviceListCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.cellModel = self.devicesArray[indexPath.row];
    return cell;
}



#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.selectCallback) {
        self.selectCallback(indexPath.row);
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 90;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 6;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1;
}


@end
