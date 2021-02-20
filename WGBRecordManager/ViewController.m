//
//  ViewController.m
//  WGBRecordManager
//
//  Created by 王贵彬 on 2021/2/20.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>
#import "WGBRecordManager.h"

@interface ViewController ()<WGBRecordLocalVideoManagerDelegate>

@property (nonatomic, strong) UIButton *recordBtn;
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) NSURL *videoURL;
@property (nonatomic, strong) CAEmitterLayer * redpacketLayer;

@property (nonatomic,strong) WGBRecordManager *recordManager;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self redpacketRain];
    [self executeAnimation];
    
    UIView *testView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(100, 150, 100, 100)];
        [view setBackgroundColor:[UIColor purpleColor]];
        view;
    });
    [self.view addSubview:testView];
    
    {
        /*
         这个动画会让直播一直有视频帧
         动画类型不限，只要屏幕是变化的就会有视频帧
         */
        [testView.layer removeAllAnimations];
        CABasicAnimation *rA = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rA.duration = 3.0;
        rA.toValue = [NSNumber numberWithFloat:M_PI * 2];
        rA.repeatCount = MAXFLOAT;
        rA.removedOnCompletion = NO;
        [testView.layer addAnimation:rA forKey:@""];
    }
   
    self.recordBtn = ({
          UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
          [button setFrame:CGRectMake(50, 350, 150, 50)];
          [button setTitle:@"录制⏺" forState:UIControlStateNormal];
          [button setTitle:@"停止⏹" forState:UIControlStateSelected];
          [button addTarget:self action:@selector(clickRecord:) forControlEvents:UIControlEventTouchUpInside];
          button;
      });
    
    [self.view addSubview:self.recordBtn];
    
}


- (void)clickRecord:(UIButton *)sender{
    if (![self.recordManager isCanRecord]) {
        return;
    }
    
    if ([self.recordManager isRecording]) {
        [self.recordManager stopRecord];
    }else{
        [self.recordManager startRecord];
    }
}

- (void)playVideo{
    if (!self.videoURL) {
        return;
    }
    if (self.player.rate) {
        return;
    }

    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:self.videoURL];
    self.player = [AVPlayer playerWithPlayerItem:item];
    AVPlayerViewController *vc = [[AVPlayerViewController alloc] init];
    vc.player = self.player;
    [self.player play];
    vc.showsPlaybackControls = NO;
    vc.view.frame = CGRectMake(0, 500, self.view.bounds.size.width , 300);
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(loopPlayVideo:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)loopPlayVideo:(NSNotification *)note{
    AVPlayerItem *playerItem = note.object;
    [playerItem seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        if (finished) {
            [self.player play];
        }
    }];
}

- (void)saveVideo{
    BOOL isCompatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.videoURL.path);
    if (isCompatible) {
        UISaveVideoAtPathToSavedPhotosAlbum(self.videoURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (!error) {
        NSLog(@"已保存到相册");
    }else{
        NSLog(@"保存相册失败%@",error.localizedDescription);
    }
}


///MARK:-  <PHRecordLocalVideoManagerDelegate>
- (void)screenRecordingStartCallbackWithError:(NSError *)error{
    self.recordBtn.selected = YES;
    NSLog(@"启动录屏 - %@",error.localizedDescription?:@"成功!!");
}

- (void)screenRecordingStopCallbackWithFilePath:(NSString *)filePath
                                          error:(NSError *)error{
    self.recordBtn.selected = NO;
    NSLog(@"filePath >> %@",filePath);
    NSLog(@"结束录屏 - %@",error.localizedDescription?:@"成功!!");
    self.videoURL = [NSURL fileURLWithPath:filePath];
    [self playVideo];
    [self saveVideo];
}

/**
 * 红包雨
 */
- (void)redpacketRain{
    // 1. 设置CAEmitterLayer
    CAEmitterLayer * redpacketLayer = [CAEmitterLayer layer];
    [self.view.layer addSublayer:redpacketLayer];
    self.redpacketLayer = redpacketLayer;
    redpacketLayer.emitterShape = kCAEmitterLayerLine;  // 发射源的形状 是枚举类型
    redpacketLayer.emitterMode = kCAEmitterLayerSurface; // 发射模式 枚举类型
    redpacketLayer.emitterSize = self.view.frame.size; // 发射源的size 决定了发射源的大小
    redpacketLayer.emitterPosition = CGPointMake(self.view.bounds.size.width * 0.5, -10); // 发射源的位置 从天而降
    redpacketLayer.birthRate = 0.f; // 每秒产生的粒子数量的系数
    
    // 2. 配置cell
    CAEmitterCell * rainCell = [CAEmitterCell emitterCell];
    rainCell.contents = (id)[[UIImage imageNamed:@"red_bag"] CGImage];  // 粒子的内容 是CGImageRef类型的
    
    rainCell.birthRate = 8.f;  // 每秒产生的粒子数量
    rainCell.lifetime = 20.f;  // 粒子的生命周期
    
    rainCell.velocity = 10.0f;  // 粒子的速度
    rainCell.yAcceleration = 1000.f; // 粒子再y方向的加速的
    rainCell.scale = 0.5;  // 粒子的缩放比例
    redpacketLayer.emitterCells = @[rainCell];  // 粒子添加到CAEmitterLayer上
}


- (void)executeAnimation{
    [self.redpacketLayer setValue:@1.f forKeyPath:@"birthRate"];
    [self performSelector:@selector(endRedpacketAnimation) withObject:nil afterDelay:3.f];
}

- (void)endRedpacketAnimation{
    [self.redpacketLayer setValue:@0.f forKeyPath:@"birthRate"];
    [self executeAnimation]; //递归调用
}


- (WGBRecordManager *)recordManager{
    if (!_recordManager) {
        _recordManager = [[WGBRecordManager alloc] init];
        _recordManager.delegate = self;
        _recordManager.microphoneEnabled = YES;
    }
    return _recordManager;
}


@end
