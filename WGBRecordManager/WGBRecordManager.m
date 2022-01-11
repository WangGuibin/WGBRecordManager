//
//  WGBRecordManager.m
//  WGBRecordManager
//
//  Created by 王贵彬 on 2021/2/20.
//

#import "WGBRecordManager.h"
#import <ReplayKit/ReplayKit.h>
#import <Photos/Photos.h>

@implementation WGBRecordManager

+ (instancetype)shareManager{
    static WGBRecordManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[WGBRecordManager alloc] init];
    });
    return _manager;
}

- (BOOL)isAvailable{
    return [RPScreenRecorder sharedRecorder].available;
}
- (BOOL)isRecording{
    return [RPScreenRecorder sharedRecorder].isRecording;
}

- (void)startRecord{
    if (![self isAvailable]) {
        return;
    }
    if (!self.savePath) {
        NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *dirPath = [documentDirectory stringByAppendingPathComponent:@"record_screen_video"];
        self.savePath = dirPath;
    }

    [RPScreenRecorder sharedRecorder].microphoneEnabled = self.isMicrophoneEnabled;
    [[RPScreenRecorder sharedRecorder] startRecordingWithHandler:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingStartCallbackWithError:)]) {
                [self.delegate screenRecordingStartCallbackWithError:error];
            }
        });
    }];
}

- (void)setSavePath:(NSString *)savePath{
    if (![[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:savePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    _savePath = savePath;
}

/// 当前视频文件路径
- (NSString *)videoFilePath{
    NSDateFormatter *dateformat = [NSDateFormatter new];
    [dateformat setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
    NSString *fileName = [NSString stringWithFormat:@"record_screen_%@.mp4",[dateformat stringFromDate:[NSDate date]]];
    return [self.savePath stringByAppendingPathComponent:fileName];;
}


///MARK:- 停止录制统一回调
- (void)callBackDelegateStopScreenRecordWithFilePath:(NSString *_Nullable)filePath
                                               error:(NSError *)error{
    if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingStopCallbackWithFilePath:error:)]) {
        [self.delegate screenRecordingStopCallbackWithFilePath:filePath error:error];
    }
}


- (void)stopRecord{
    RPScreenRecorder *record = [RPScreenRecorder sharedRecorder];
    if ([record isRecording]) {
        NSDateFormatter *dateformat = [NSDateFormatter new];
        [dateformat setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
        //文件名
        NSString *fileName = [NSString stringWithFormat:@"record_screen_%@.mp4",[dateformat stringFromDate:[NSDate date]]];
        NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *dirPath = [documentDirectory stringByAppendingPathComponent:@"record_screen_video"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *filePath = [dirPath stringByAppendingPathComponent:fileName];

    if (@available(iOS 14.0, *)) {
        [record stopRecordingWithOutputURL:[NSURL fileURLWithPath:filePath] completionHandler:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingStopCallbackWithFilePath:error:)]) {
                    [self.delegate screenRecordingStopCallbackWithFilePath:filePath error:error];
                }
            });
        }];
    }else{
        [record stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            NSURL *videoURL = [[previewViewController valueForKeyPath:@"movieURL"] copy];
            if (error) {
                [self callBackDelegateStopScreenRecordWithFilePath:nil error:error];
            }else{
                //保存相册 ==> 取出相册最新视频 ==> 拷贝到沙盒
                // 直接操作没有权限 必须先保存到相册去取
                BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([videoURL path]);
                if (compatible){
                    UISaveVideoAtPathToSavedPhotosAlbum([videoURL path], self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
                }
            }

        }];
     }
   }
}


//保存视频完成之后的回调
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    //录屏成功&&保存失败才会走这, 录屏失败应该在上层抛出异常
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
    PHAsset *phasset = [assetsFetchResults lastObject];
    if (phasset) {
        if (phasset.mediaType == PHAssetMediaTypeVideo) {
            //是视频文件
            NSString *filePath = [self videoFilePath];
            PHImageManager *manager = [PHImageManager defaultManager];
            [manager requestAVAssetForVideo:phasset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                AVURLAsset *urlAsset = (AVURLAsset *)asset;
                NSURL *videoURL = urlAsset.URL;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSFileManager defaultManager] copyItemAtPath:videoURL.path toPath:filePath error:nil];
                    [self callBackDelegateStopScreenRecordWithFilePath:filePath error:error];
                });
            }];
        }else{
            [self callBackDelegateStopScreenRecordWithFilePath:nil error:error];
        }
    }else{
        [self callBackDelegateStopScreenRecordWithFilePath:nil error:error];
    }
}

@end
