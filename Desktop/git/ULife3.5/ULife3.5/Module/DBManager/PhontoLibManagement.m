//
//  PhontoLibManagement.m
//  WiFi
//
//  Created by shenyuanluo on 2017/6/17.
//  Copyright © 2017年 goscam_sz. All rights reserved.
//

#import "PhontoLibManagement.h"

@implementation PhontoLibManagement

+ (instancetype)shareManager
{
    static PhontoLibManagement *g_photoLibManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        if (nil == g_photoLibManager)
        {
            g_photoLibManager = [[PhontoLibManagement alloc] init];
        }
    });
    return g_photoLibManager;
}


#pragma mark -- 获取与 APP 同名的自定义相册(如果没有则创建)
- (PHAssetCollection *)getAppNameAssetCollection
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
    // 获取所有自定义相册
    PHFetchResult <PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                                                subtype:PHAssetCollectionSubtypeAlbumRegular
                                     options:nil];
    for (PHAssetCollection *collection in collections)
    {
        // 遍历与 APP 同名的自定义相册
        if ([collection.localizedTitle isEqualToString:appName])
        {
            NSLog(@"找到了与APP同名的自定义相册");
            return collection;
        }
    }
    // 没有找到，需要创建
    NSError *error = nil;
    __block NSString *createID = nil; //用来获取创建好的相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        
        //发起了创建新相册的请求，并拿到ID，当前并没有创建成功，待创建成功后，通过 ID 来获取创建好的自定义相册
        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:appName];
        createID = request.placeholderForCreatedAssetCollection.localIdentifier;
    }
                                                         error:&error];
    if (error)
    {
//        NSLog(@"创建自定义相册失败");
//        [SVProgressHUD showErrorWithStatus:(@"CreatPhotoAssectFailure")];
        
        return nil;
    }
    else
    {
//        NSLog(@"创建自定义相册成功");
//        [SVProgressHUD showSuccessWithStatus:GDLocalizedString(@"CreatPhotoAssectSuccess")];
        
        //通过 ID 获取创建完成的相册 -- 是一个数组
        return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createID]
                                                                    options:nil].firstObject;
    }
}


#pragma mark --- 保存图片、视频
- (void)saveImage:(NSString *)imagePath
            video:(NSString *)videoPath;
{
    PHAuthorizationStatus lastStatus = [PHPhotoLibrary authorizationStatus];
    __weak typeof(self)weakSelf = self;
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法保存到相册！");
            return ;
        }
        if(PHAuthorizationStatusDenied == status) // 用户拒绝（可能是之前拒绝的，有可能是刚才在系统弹框中选择的拒绝）
        {
            if (lastStatus == PHAuthorizationStatusNotDetermined)
            {
//                [SVProgressHUD showErrorWithStatus:GDLocalizedString(@"SaveFailure")];
                
                return;
            }
//            [SVProgressHUD showInfoWithStatus:GDLocalizedString(@"AccessPhotoLibFailure")];
            
        }
        else if(PHAuthorizationStatusAuthorized == status) // 用户允许访问相册
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [strongSelf saveToCustomAblumWithImage:imagePath
                                                 video:videoPath];
            });
        }
        else if (PHAuthorizationStatusRestricted == status) // 系统原因，无法访问相册
        {
//            [SVProgressHUD showErrorWithStatus:GDLocalizedString(@"CanNotAccessPhotoLib")];
        }
    }];
}


#pragma mark -- 将图片、视频保存到自定义相册中
- (void)saveToCustomAblumWithImage:(NSString *)imagePath
                             video:(NSString *)videoPath
{
    PHFetchResult <PHAsset *>*assets = [self syncSaveImage:imagePath
                                                     video:videoPath];
    if (nil == assets)
    {
//        [SVProgressHUD showErrorWithStatus:GDLocalizedString(@"SaveFailure")];
        return;
    }
    NSError *error = nil;
    __weak typeof(self)weakSelf = self;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法保存图片到自定义相册！");
            return ;
        }
        PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:[strongSelf getAppNameAssetCollection]];
        [collectionChangeRequest insertAssets:assets
                                    atIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
                                                         error:&error];
    if (error)
    {
//        [SVProgressHUD showErrorWithStatus:GDLocalizedString(@"SaveFailure")];
        
        return;
    }
//    [SVProgressHUD showSuccessWithStatus:GDLocalizedString(@"SaveSuccess")];
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:SAVE_MEDIA_SUCCESS_NOTIFY
//                                                        object:videoPath];
}


#pragma mark --  同步方式保存图片到系统的相机胶卷中(返回当前保存成功后相册图片对象集合)
- (PHFetchResult <PHAsset *>*)syncSaveImage:(NSString *)imagePath
                                      video:(NSString *)videoPath
{
    BOOL isSaveVideo = NO;
    if (NO == IS_STRING_EMPTY(videoPath))
    {
        isSaveVideo = YES;
    }
    __block NSString *createdAssetID = nil;
    NSError *error = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        
        if (NO == isSaveVideo)      // 保存图片
        {
            NSURL *url = [NSURL fileURLWithPath:imagePath];
            createdAssetID = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:url].placeholderForCreatedAsset.localIdentifier;
        }
        else            // 保存视频
        {
            NSURL *url = [NSURL fileURLWithPath:videoPath];
            createdAssetID = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url].placeholderForCreatedAsset.localIdentifier;
        }
        
    }
                                                         error:&error];
    if (error)
    {
        NSLog(@"资源保存到相册出错！");
        return nil;
    }
    PHFetchResult <PHAsset *>*assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetID]
                                                                        options:nil];
    return assets;
    
}

#pragma mark -- 获取自定义相册的所有图片
- (void)getCustomAlbumMedia:(GetMediaBlock)mediaBlock
{
    __weak typeof(self)weakSelf = self;
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf)
        {
            NSLog(@"对象丢失，无法获取自定义相册图片！");
            return ;
        }
        if(PHAuthorizationStatusDenied == status) // 用户拒绝
        {
//            [SVProgressHUD showInfoWithStatus:GDLocalizedString(@"AccessPhotoLibFailure")];
            if (mediaBlock)
            {
                mediaBlock(nil);
            }
        }
        else if(PHAuthorizationStatusAuthorized == status) // 用户允许访问相册
        {
            dispatch_async(dispatch_get_main_queue(), ^{
               
                PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:[strongSelf getAppNameAssetCollection]
                                                                      options:nil];
                if (mediaBlock)
                {
                    mediaBlock(assets);
                }
            });
        }
        else if (PHAuthorizationStatusRestricted == status) // 系统原因，无法访问相册
        {
            [SVProgressHUD showErrorWithStatus:@"系统原因，无法访问相册"];
            if (mediaBlock)
            {
                mediaBlock(nil);
            }
        }
    }];
}

@end
