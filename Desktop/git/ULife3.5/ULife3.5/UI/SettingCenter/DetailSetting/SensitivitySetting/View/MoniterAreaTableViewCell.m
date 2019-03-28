//
//  MoniterAreaTableViewCell.m
//  ULife3.5
//
//  Created by zhuochuncai on 4/6/17.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import "MoniterAreaTableViewCell.h"
#import "MoniterAreaCollectionViewCell.h"

@interface MoniterAreaTableViewCell()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
    
}
@property(nonatomic,strong)SelectAreaBlock selectAreaBlock;
@end

@implementation MoniterAreaTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    [self configCollectionView];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)selectMoniterAreaCallback:(SelectAreaBlock)block{
    _selectAreaBlock = block;
}

//适配iOS11
- (UIEdgeInsets)layoutMargins {
    [super layoutMargins];
    return UIEdgeInsetsMake(0, 0, 0, 0);
}


- (void)configCollectionView{

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    float collectionWidth = 0;
    float collectionHeight = 0;
    
    float mScreenWidth = SCREEN_WIDTH;
    if (mScreenWidth > 375.1) {
        collectionWidth = (SCREEN_WIDTH*340/375)+0.64;
        collectionHeight = collectionWidth*9/16;//-1.5
        self.collectionWidthToSuperConstraint.constant = 0.64;
    }else if( mScreenWidth > 320.1){
        collectionWidth = (SCREEN_WIDTH*340/375);
        collectionHeight = collectionWidth*9/16;
    }else{
        collectionWidth = (SCREEN_WIDTH*340/375)-0.5;
        collectionHeight = collectionWidth*9/16+0.5;
    }
    
    flowLayout.itemSize = CGSizeMake( (collectionWidth/4), (collectionHeight/4) ); //(32,18)
    
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"MoniterAreaCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"MoniterAreaCollectionViewCell"];
    
    self.collectionView.collectionViewLayout = flowLayout;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
}

#pragma mark == <UICollectionViewDelegate>

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (_selectAreaBlock) {
        _selectAreaBlock(indexPath.row);
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 4*4;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    MoniterAreaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MoniterAreaCollectionViewCell" forIndexPath:indexPath];
    BOOL isSelected = (self.selectedArea >> indexPath.row)&1;
    
    if (!isSelected) {
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView.alpha = 1;
        for (UIView *view in cell.borderArray) {
            view.backgroundColor = [UIColor redColor];
        }
    }else{
        cell.backgroundColor = BACKCOLOR(97, 181, 55, 0.5);//[UIColor colorWithWhite:0.f alpha:0.6];
        for (UIView *view in cell.borderArray) {
            view.backgroundColor = [UIColor blueColor];
        }
    }
    return cell;
}

@end
