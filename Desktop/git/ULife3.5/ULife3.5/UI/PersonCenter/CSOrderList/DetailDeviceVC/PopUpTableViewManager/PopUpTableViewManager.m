//
//  PopUpTableViewManager.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/23.
//  Copyright © 2018年 GosCam. All rights reserved.
//

#import "PopUpTableViewManager.h"
#import "SYDeviceInfo.h"

#define StatusAndNaviBarHeight (SYName_iPhone_X == [SYDeviceInfo syDeviceName] ?80 : 64)
#define kCellIdentifier (@"PopUpTableCellIdentifier")

@interface PopUpTableViewManager()
<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate>

@property (strong, nonatomic)  UITableView *tableView;

@property (strong, nonatomic)  SelectCellCallbackBlock selectCallback;

@property (strong, nonatomic)  ExitSelectingBlock exitBlock;


@end

@implementation PopupTableCellModel
@end

@implementation PopUpTableViewManager

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self configTableView];
        [self addEvents];
    }
    return self;
}

- (void)addEvents{
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exitFunc:)];
    tapGes.delegate = self;
    [self addGestureRecognizer:tapGes];
}

//排除手势事件对TableView点击事件的干扰
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    NSLog(@"______________gestureRecognizer___________:%@",NSStringFromClass( [touch.view class] ));
    return ![NSStringFromClass( [touch.view class] ) isEqualToString:@"UITableViewCellContentView"];
    
//    CGPoint touchP = [touch locationInView:self];
//    CGFloat minX = SCREEN_WIDTH * 0.1;
//    CGFloat maxX = SCREEN_WIDTH * 0.9;
//    CGFloat minY = SCREEN_HEIGHT/2 - 22*(self.devicesArray.count+1);
//    CGFloat maxY = SCREEN_HEIGHT/2 + 22*(self.devicesArray.count+1);
//    return touchP.x < minX || touchP.y < minY || touchP.x > maxX || touchP.y > maxY;
}


- (void)exitFunc:(UITapGestureRecognizer*)tapGes{
    !_exitBlock?:_exitBlock();
}

- (void)exitSelectingCallback:(ExitSelectingBlock)exitCallback{
    _exitBlock = exitCallback;
}

- (void)selectCellCallback:(SelectCellCallbackBlock)aCallbackBlock{
    self.selectCallback = aCallbackBlock;
    
//    [self configTableView];
}

- (void)setDevicesArray:(NSArray<PopupTableCellModel *> *)devicesArray{
    _devicesArray = devicesArray;
    
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.center.equalTo(self);
        make.width.equalTo(self).multipliedBy(0.8);
        make.height.mas_equalTo(44*(self.devicesArray.count+1)+1);
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)configTableView{
    
    self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.5];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStylePlain];
    _tableView.separatorInset = UIEdgeInsetsZero;

    _tableView.delegate =self;
    _tableView.dataSource = self;
    
    [self addSubview: _tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.center.equalTo(self);
        make.width.equalTo(self).multipliedBy(0.8);
        make.height.mas_equalTo(44*(self.devicesArray.count+1)+1);
    }];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.devicesArray.count+1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
    }
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    if (indexPath.row == 0) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = !_tableHeaderStr?DPLocalizedString(@"CSOrder_Transfer_Title"):_tableHeaderStr;
        cell.textLabel.numberOfLines = 0;
        
    }else{
        cell.textLabel.text = self.devicesArray[indexPath.row-1].deviceName;
    }
    
    return cell;
}


- (void)setTableHeaderStr:(NSString *)tableHeaderStr{
    _tableHeaderStr = tableHeaderStr;
}





#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row==0) {
        return;
    }
    !_selectCallback?:_selectCallback(indexPath.row-1);
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.01;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}



@end
