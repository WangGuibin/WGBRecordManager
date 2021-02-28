//
//  WGBRecordManager.m
//  WGBRecordManager
//
//  Created by 王贵彬 on 2021/2/20.
//

#import "WGBRecordManager.h"
#import <ReplayKit/ReplayKit.h>

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
    [RPScreenRecorder sharedRecorder].microphoneEnabled = self.isMicrophoneEnabled;
    [[RPScreenRecorder sharedRecorder] startRecordingWithHandler:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingStartCallbackWithError:)]) {
                [self.delegate screenRecordingStartCallbackWithError:error];
            }
        });
    }];
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
            [[NSFileManager defaultManager] copyItemAtPath:videoURL.path toPath:filePath error:nil];
            if (self.delegate && [self.delegate respondsToSelector:@selector(screenRecordingStopCallbackWithFilePath:error:)]) {
                [self.delegate screenRecordingStopCallbackWithFilePath:filePath error:error];
            }
        }];
     }
   }
}

@end
