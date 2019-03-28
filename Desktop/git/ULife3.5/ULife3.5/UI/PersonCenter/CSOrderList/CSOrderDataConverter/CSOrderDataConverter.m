//
//  CSOrderDataConverter.m
//  ULife3.5
//
//  Created by Goscam on 2018/4/26.
//  Copyright © 2018年 GosCam. All rights reserved.
//

//将服务端传过来的数据传化为UI层显示所需要的数据

#import "CSOrderDataConverter.h"
#import "DeviceDataModel.h"
#import "SaveDataModel.h"
#import "CommonlyUsedFounctions.h"
#import "DeviceManagement.h"
#import "MediaManager.h"

@implementation CSOrderDataConverter

+ (NSArray<CSOrderDeviceListCellModel*> *)csOrderDeviceListFromCSDataArray:(NSArray<CSOrderItemInfo*>*)dataArray
                                                    withForceUnbindDevList:(NSArray<ForceUnbindDevModel*>*)forceUnbindDevList{
    
    NSMutableArray<CSOrderDeviceListCellModel*> *tempArray = [NSMutableArray arrayWithCapacity:1];
    
    for (NSDictionary *tempDict in dataArray) {
        CSOrderItemInfo *info = [CSOrderItemInfo yy_modelWithDictionary:tempDict];
        CSOrderDeviceListCellModel *cellModel = [self cellModelFromCSOrderItemInfo:info ];
        
        if(cellModel.orderStatus == CSOrderStatusUnbind && forceUnbindDevList.count >0 ){
            for (ForceUnbindDevModel *devModel in forceUnbindDevList) {
                if ([devModel.DevId isEqualToString: cellModel.devId ]) {
                    cellModel.devName = [cellModel.devName stringByReplacingOccurrencesOfString:MLocalizedString(CSOrder_Unbind_OldCamera) withString:devModel.DevName];
                    break;
                }
            }
        }
        [tempArray addObject: cellModel];
    }
    //添加未开通云存储的
    for (DeviceDataModel *devModel in [[DeviceManagement sharedInstance] deviceListArray]) {
        
        bool hasPurchasedCS = NO;
        for (CSOrderDeviceListCellModel *cellModel in tempArray) {
            if ([devModel.DeviceId isEqualToString:cellModel.devId]) {
                hasPurchasedCS = YES;
                break;
            }
        }
        //过滤分享设备，以及不支持云存储的（门铃全部支持）&& devModel.hasCloudPlay
        if (!hasPurchasedCS && devModel.DeviceOwner!=GosDeviceShare ) {
            [tempArray addObject:[self cellModelFromDevModel:devModel ]];
        }
    }
    //Sort
    [tempArray sortUsingComparator:^NSComparisonResult(CSOrderDeviceListCellModel* obj1, CSOrderDeviceListCellModel* obj2) {
        return obj1.orderStatus - obj2.orderStatus;
    }];
    return tempArray;
}

//未开通云存储Cell对应的model
+ (CSOrderDeviceListCellModel *)cellModelFromDevModel:(DeviceDataModel*)devModel{
    CSOrderDeviceListCellModel *cellModel = [CSOrderDeviceListCellModel new];
    cellModel.devId = devModel.DeviceId;
    NSString *devID = devModel.DeviceId;
    cellModel.imagePath = [[MediaManager shareManager] mediaPathWithDevId:devID.length<=20?devID:[devID substringFromIndex:8]
                                                                 fileName:nil
                                                                mediaType:GosMediaCover
                                                               deviceType:GosDeviceIPC
                                                                 position:PositionMain];
    cellModel.packageType = @" ";
    cellModel.orderStatus = CSOrderStatusUnpurchased;
    cellModel.validTime = MLocalizedString(CSOrder_NoOrderRecord);
    
    cellModel.devName = [NSString stringWithFormat:@"%@",devModel.DeviceName];
    return cellModel;
}

//其他Cell对应的model
+ (CSOrderDeviceListCellModel *)cellModelFromCSOrderItemInfo:(CSOrderItemInfo*)info{
    CSOrderDeviceListCellModel *cellModel = [CSOrderDeviceListCellModel new];
    cellModel.devId = info.deviceId;
    cellModel.imagePath = [[MediaManager shareManager] mediaPathWithDevId:info.deviceId.length<=20?info.deviceId:[info.deviceId substringFromIndex:8]
                                                                 fileName:nil
                                                                mediaType:GosMediaCover
                                                               deviceType:GosDeviceIPC
                                                                 position:PositionMain];
    
    CSServiceStatus csStatus = info.status.intValue;
    
    cellModel.orderStatus = [self csOrderStatusFromCSStatus:csStatus];
    cellModel.packageType = cellModel.orderStatus== CSOrderStatusExpired ?@" ":[info.dataLife stringByAppendingString:MLocalizedString(CSOrder_CS_Days)];
    cellModel.devName = cellModel.orderStatus == CSOrderStatusUnbind?MLocalizedString(CSOrder_Unbind_DevName):@" ";
    
    cellModel.validTime = cellModel.orderStatus== CSOrderStatusExpired?MLocalizedString(PackageStateExpired):[NSString stringWithFormat:@"%@：%@",MLocalizedString(CSOrder_ValidityPeriod),[CommonlyUsedFounctions convertedValidTimeWithSartTime:info.startTime endTime:info.preinvalidTime]];
    
    for (DeviceDataModel *devModel in [[DeviceManagement sharedInstance] deviceListArray]) {
        if ([devModel.DeviceId isEqualToString:cellModel.devId]) {
            cellModel.devName = [NSString stringWithFormat:@"%@",devModel.DeviceName];
            break;
        }
    }
    //没有找到设备名的，强制转为7 已移除
    if ([cellModel.devName isEqualToString:@" "]) {
        cellModel.devName = MLocalizedString(CSOrder_Unbind_DevName);
        cellModel.orderStatus = CSOrderStatusUnbind;
    }
    
    return cellModel;
}

+ (CSOrderStatus)csOrderStatusFromCSStatus:(CSServiceStatus)serviceStatus{
    switch (serviceStatus) {
        case CSServiceStatusExpired:
            return CSOrderStatusExpired;
        
        case CSServiceStatusUnused:
        case CSServiceStatusInUse:
            return CSOrderStatusInUse;
        case CSServiceStatusUnbind:
            return CSOrderStatusUnbind;
            
        case CSServiceStatusForbidden:
            break;
    }
    return CSOrderStatusUnpurchased;
}

@end
