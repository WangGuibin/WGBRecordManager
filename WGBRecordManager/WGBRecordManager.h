//
//  WGBRecordManager.h
//  WGBRecordManager
//
//  Created by 王贵彬 on 2021/2/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WGBRecordManager;
@protocol WGBRecordLocalVideoManagerDelegate <NSObject>
@optional
- (void)screenRecordingStartCallbackWithError:(NSError *)error;
- (void)screenRecordingStopCallbackWithFilePath:(NSString *)filePath
                                          error:(NSError *)error;
@end

@interface WGBRecordManager : NSObject

///MARK:- 单例 
+ (instancetype)shareManager;

@property (nonatomic,weak) id<WGBRecordLocalVideoManagerDelegate> delegate;
//是否录音 默认NO `- startRecord`之前调用方可生效
@property (nonatomic, getter = isMicrophoneEnabled) BOOL microphoneEnabled;
@property (nonatomic, readonly, getter = isAvailable) BOOL available;
@property (nonatomic, readonly, getter = isRecording) BOOL recording;

- (void)startRecord;
- (void)stopRecord;

@end

NS_ASSUME_NONNULL_END
