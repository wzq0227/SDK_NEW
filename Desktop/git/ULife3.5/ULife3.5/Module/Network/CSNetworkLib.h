//
//  CSNetworkLib.h
//  ULife3.5
//
//  Created by Goscam on 2017/10/10.
//  Copyright © 2017年 GosCam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYModel.h"


//云存储订阅列表每个记录信息
@interface CSOrderItemInfo:NSObject
//orderNo id timeStamp count payTime orderCount
@property (assign, nonatomic)  NSString *status;                //套餐状态
@property (strong, nonatomic)  NSString *deviceId;              //设备ID号
@property (strong, nonatomic)  NSString *planId;                //套餐ID
@property (strong, nonatomic)  NSString *planName;              //套餐名称
@property (strong, nonatomic)  NSString *enable;                //套餐启用
@property (strong, nonatomic)  NSString *renewEnable;           //套餐续费
@property (strong, nonatomic)  NSString *dataLife;              //数据保存时间
@property (strong, nonatomic)  NSString *serviceLife;           //套餐有效期

@property (strong, nonatomic) NSString *startTime;                //服务生效时间
@property (strong, nonatomic) NSString *preinvalidTime;                //服务有效截止时间
@property (strong, nonatomic) NSString *dataExpiredTime;             //服务有效截止时间
@property (strong, nonatomic) NSString *switchEnable;              //1可用  0 禁用
@property (strong, nonatomic) NSString *createUser;              //套餐创建用户
@property (strong, nonatomic) NSString *createTime;            //套餐创建时间
@end



//"planId":"55",
//"planName":"7天月套餐",
//"planDesc":"数据保存7天，服务可持续使用30天",
//"enable":"1",
//"renewEnable":"1",
//"dataLife":"7",
//"serviceLife":"30",
//"originalPrice":"1"
//"price":"0.01",
//"createTime":"20170831160400",
//"modifyTime":"null"

@interface CSPackageInfo:NSObject
@property (strong, nonatomic)  NSString *planId;                //套餐ID
@property (strong, nonatomic)  NSString *planName;              //套餐名称
@property (strong, nonatomic)  NSString *planDesc;              //套餐描述
@property (strong, nonatomic)  NSString *enable;                //套餐启用
@property (strong, nonatomic)  NSString *renewEnable;           //套餐续费
@property (strong, nonatomic)  NSString *dataLife;              //数据保存时间
@property (strong, nonatomic)  NSString *serviceLife;           //套餐有效期
@property (strong, nonatomic)  NSString *originalPrice;         //套餐原价格
@property (strong, nonatomic)  NSString *price;                 //套餐价格
@property (strong, nonatomic)  NSString *createTime;            //套餐创建时间
@property (strong, nonatomic)  NSString *modifyTime;            //套餐修改时间
@end



@interface CSRequestBaseObject:NSObject

- (NSArray *) allPropertyNames;

- (SEL) creatGetterWithPropertyName: (NSString *) propertyName;

- (NSString *)requestParamStr;

@end;


@interface CSQueryOrderListReq: CSRequestBaseObject
@property (strong, nonatomic)  NSString *token;                    //登录验证
@property (strong, nonatomic)  NSString *username;                 //用户名
@end

@interface CSQueryOrderListResp: NSObject
@property (strong, nonatomic)  NSString *code;                     //错误码
@property (strong, nonatomic)  NSArray <CSOrderItemInfo*>*data;    //ItemList
@end

@interface CSCreateOrderReq: CSRequestBaseObject
@property (strong, nonatomic)  NSString *device_id;                //套餐设备ID号
@property (strong, nonatomic)  NSString *plan_id;                  //套餐ID号
@property (strong, nonatomic)  NSString *count;                    //套餐订购数量
@property (strong, nonatomic)  NSString *total_price;              //订单总价格
@property (strong, nonatomic)  NSString *token;                    //登录验证
@property (strong, nonatomic)  NSString *username;                 //用户名
@end


@interface CSCreateOrderResp:NSObject
@property (strong, nonatomic)  NSString *orderNo;                //订单号
@property (strong, nonatomic)  NSString *userId;                  //用户ID
@property (strong, nonatomic)  NSString *devId;                    //设备ID号
@property (assign, nonatomic)  int  planId;                   //套餐ID
@property (assign, nonatomic)  int  orderCount;                    //订购数量
@property (strong, nonatomic)  NSString *totalPrice;              //订单总价格
@property (assign, nonatomic)  int status;                      //套餐状态
//0 待支付
//1 已支付
//2 主动取消
//4 超时关闭

@property (strong, nonatomic)  NSString *createTime;            //订单创建时间
@end


//MARK: 查询可用的免费套餐
@interface CSQueryFreePackageReq: CSRequestBaseObject
@property (strong, nonatomic)  NSString *device_id;                //套餐设备ID号
@property (strong, nonatomic)  NSString *token;                    //登录验证
@property (strong, nonatomic)  NSString *username;                 //用户名
@end


@interface CSQueryFreePackageResp:NSObject
@property (strong, nonatomic)  NSString *planId;                //套餐ID
@property (strong, nonatomic)  NSString *planName;              //套餐名称
@property (strong, nonatomic)  NSString *alwaysWriteEnable;     //
@property (strong, nonatomic)  NSString *planDesc;              //套餐描述
@property (strong, nonatomic)  NSString *enable;                //套餐启用
@property (strong, nonatomic)  NSString *renewEnable;           //套餐续费
@property (strong, nonatomic)  NSString *freeFlag;              //免费标志
@property (strong, nonatomic)  NSString *dataLife;              //数据保存时间
@property (strong, nonatomic)  NSString *serviceLife;           //套餐有效期
@property (strong, nonatomic)  NSString *price;                 //套餐价格
@property (strong, nonatomic)  NSString *createTime;            //套餐创建时间
@property (strong, nonatomic)  NSString *deleteEnable;          //删除
@end

//MARK: 创建免费套餐
@interface CSCreateFreePackageReq: CSRequestBaseObject
@property (strong, nonatomic)  NSString *device_id;                //套餐设备ID号
@property (strong, nonatomic)  NSString *token;                    //登录验证
@property (strong, nonatomic)  NSString *username;                 //用户名
@property (strong, nonatomic)  NSString *plan_id;                //套餐ID
@end

@interface CSCreateFreePackageResp:NSObject
@property (strong, nonatomic)  NSString *orderNo;                //订单号
@property (strong, nonatomic)  NSString *userId;                  //用户ID
@property (strong, nonatomic)  NSString *devId;                    //设备ID号
@property (assign, nonatomic)  NSString *planId;                   //套餐ID
@property (assign, nonatomic)  NSString *orderCount;                    //订购数量
@property (strong, nonatomic)  NSString *totalPrice;              //订单总价格
@property (assign, nonatomic)  NSString *status;                      //套餐状态
@property (strong, nonatomic)  NSString *createTime;            //套餐创建时间
@end


//MARK: 支付免费套餐
@interface CSPayFreePackageReq: CSRequestBaseObject
@property (strong, nonatomic)  NSString *order_no;                //套餐设备ID号
@property (strong, nonatomic)  NSString *token;                    //登录验证
@property (strong, nonatomic)  NSString *username;                 //用户名
@end


/**
 套餐状态
 - CSServiceStatusExpired: 服务已过期
 - CSServiceStatusInUse: 正常使用中
 - CSServiceStatusUnbind：已解绑
 - CSServiceStatusForbidden: 服务被禁用
 */
typedef NS_ENUM(int, CSServiceStatus) {
    CSServiceStatusExpired =0,
    CSServiceStatusInUse = 1,
    CSServiceStatusUnused,
    CSServiceStatusUnbind =7,
    CSServiceStatusForbidden = 9,
};

@interface CSQueryCurServiceResp:NSObject
@property (strong, nonatomic) NSString        *orderNo;         //订单号
@property (strong, nonatomic) NSString        *deviceId;        //设备ID号
@property (strong, nonatomic) NSString        *id;              //记录ID
@property (assign, nonatomic) int             planId;           //套餐ID
@property (strong, nonatomic) NSString        *planName;        //套餐名
@property (assign, nonatomic) CSServiceStatus status;           //套餐状态
@property (assign, nonatomic) int             dateLife;         //数据保存时长
@property (assign, nonatomic) int             serviceLife;      //服务有效时长
@property (strong, nonatomic) NSString        *startTime;       //服务生效时间
@property (strong, nonatomic) NSString        *preinvalidTime;  //服务有效截止时间
@property (strong, nonatomic) NSString        *switchEnable;    //1可用  0 禁用
@end

@interface CSAliPayCheckReq: CSRequestBaseObject
@property (strong, nonatomic)  NSString *memo;
@property (strong, nonatomic)  NSString *resultStatus;
@property (strong, nonatomic)  NSString *username;                 //用户名
@property (strong, nonatomic)  NSString *token;
//@property (strong, nonatomic)  NSString *code;
//@property (strong, nonatomic)  NSString *msg;
//@property (strong, nonatomic)  NSString *app_id;
//@property (strong, nonatomic)  NSString *out_trade_no;
//@property (strong, nonatomic)  NSString *total_amount;
//@property (strong, nonatomic)  NSString *trade_no;
//@property (strong, nonatomic)  NSString *seller_id;
//@property (strong, nonatomic)  NSString *charset;
//@property (strong, nonatomic)  NSString *timestamp;
//@property (strong, nonatomic)  NSString *sign;
//@property (strong, nonatomic)  NSString *sign_type;

@end



typedef void(^RequestResultBlock)(int result, NSData *data);


@interface CSNetworkLib : NSObject<NSURLSessionDelegate>

+(instancetype)sharedInstance;


- (void)requestWithURLStr:(NSString *)urlStr method:(NSString *)method result:(RequestResultBlock)result;


@end
