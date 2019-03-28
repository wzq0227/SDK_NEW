//
//  LightDurationFooterView.m
//  ULife3.5
//
//  Created by zhuochuncai on 5/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "LightDurationFooterView.h"
#import "LightDurationWeekdayCell.h"

@interface LightDurationFooterView()<UICollectionViewDelegate,UICollectionViewDataSource>
@property(nonatomic,strong)NSMutableArray *namesArray;
@property(nonatomic,strong)SelectDaysBlock callbackBlock;
@end


@implementation LightDurationFooterView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self configCollectionView];
}

- (void)configCollectionView{
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake((SCREEN_WIDTH-42)/7, self.collectionView.bounds.size.height);
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    
    self.collectionView.collectionViewLayout = flowLayout;
    
    self.collectionView.scrollEnabled = NO;
    self.collectionView.backgroundColor = BACKCOLOR(238,238,238, 1);
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerNib:[UINib nibWithNibName:@"LightDurationWeekdayCell" bundle:nil]  forCellWithReuseIdentifier:@"LightDurationWeekdayCell"];
}


- (void)selectWeekdaysCallback:(SelectDaysBlock)block{
    _callbackBlock = block;
}


#pragma mark == <UICollectionViewDelegate>

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (_callbackBlock) {
        _callbackBlock(indexPath.row);
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 7;
}

-(NSMutableArray*)namesArray{
    if (!_namesArray) {
        _namesArray = [NSMutableArray arrayWithObjects:@"LightDuration_Sun",@"LightDuration_Mon", @"LightDuration_Tue",@"LightDuration_Wed",   @"LightDuration_Thur",@"LightDuration_Fri",@"LightDuration_Sat", nil];
    }
    return _namesArray;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    LightDurationWeekdayCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LightDurationWeekdayCell" forIndexPath:indexPath];
    BOOL isSwitchOn =  (_selectedWeekdays >> indexPath.row) & 1;

    cell.title.text = DPLocalizedString(self.namesArray[indexPath.row]);

    if (isSwitchOn) {
        cell.title.textColor = [UIColor whiteColor];
        cell.backgroundColor = BACKCOLOR(150,69,120, 1); //BACKCOLOR(235,255,248,1);
    }else{
        cell.title.textColor = [UIColor blackColor];
        cell.backgroundColor = BACKCOLOR(238,238,238, 1);
    }
    return cell;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
