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

@implementation ViewController{
    NSUInteger _count;
    NSArray<UIView*> *_balls;
    NSArray<UIView*> *_anchors;
    NSArray<CAShapeLayer*>*_lines;
    UIDynamicAnimator *_animator;
    UIPushBehavior *_pushBehavior;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self redpacketRain];
    [self startBallsEnter];
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
    if (![self.recordManager isAvailable]) {
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


- (UIColor *)randomGradientLayerColor{
    CGFloat hue = (arc4random()%256/256.0);
    CGFloat saturation = (arc4random()%128/256.0 + 0.5);
    CGFloat brightness = (arc4random()%128/256.0 + 0.5);
    UIColor *ranColor = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1.0];
    return ranColor;
}

///MARK:- 物理小球代码
- (void)startBallsEnter{
    _count = 5;
    [self createBallsAndAnchors];
    [self createLines];
    [self createDynamicBehaviors];
}

- (void)createBallsAndAnchors {
    NSMutableArray *ballsArray  = [NSMutableArray array];
    NSMutableArray *anchorsArray  = [NSMutableArray array];
    CGFloat ballSize = CGRectGetWidth(self.view.bounds)/(3.0*_count);
    for (int i = 0; i < _count; i++) {
        UIView *ball = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ballSize-1, ballSize-1)];
        ball.backgroundColor = [self randomGradientLayerColor];
        ball.layer.cornerRadius = (ballSize-1)/2.0;
        CGFloat x = CGRectGetWidth(self.view.bounds)/3.0+ballSize/2+i*ballSize;
        CGFloat y = CGRectGetHeight(self.view.bounds)/3.0;
        ball.center = CGPointMake(x, y);
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
        [ball addGestureRecognizer:panGesture];
        [ball addObserver:self forKeyPath:@"center" options:NSKeyValueObservingOptionNew context:Nil];
        [ballsArray addObject:ball];
        [self.view addSubview:ball];
        
        UIView *anchor = [self createAnchorForBall:ball];
        [anchorsArray addObject:anchor];
        [self.view addSubview:anchor];
    }
    _balls = ballsArray;
    _anchors = anchorsArray;
}

- (UIView *)createAnchorForBall:(UIView *)ball {
    UIView *anchor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    anchor.layer.cornerRadius = 5;
    anchor.backgroundColor = [UIColor blackColor];
    anchor.center = CGPointMake(ball.center.x, ball.center.y-CGRectGetHeight(self.view.bounds)/3);
    return anchor;
}

- (void)createLines {
    NSMutableArray *linesArray  = [NSMutableArray array];
    for (int i = 0; i < _count; i++) {
        CAShapeLayer *subLayer = [[CAShapeLayer alloc] init];
        [self.view.layer addSublayer:subLayer];
        [linesArray addObject:subLayer];
    }
    _lines = linesArray;
}

- (void)panGesture:(UIPanGestureRecognizer *)recoginizer {
    if (recoginizer.state == UIGestureRecognizerStateBegan){
        if (_pushBehavior) {
            [_animator removeBehavior:_pushBehavior];
        }
        _pushBehavior = [[UIPushBehavior alloc] initWithItems:@[recoginizer.view] mode:UIPushBehaviorModeContinuous];
        [_animator addBehavior:_pushBehavior];
    } else if (recoginizer.state == UIGestureRecognizerStateChanged) {
        _pushBehavior.pushDirection = CGVectorMake([recoginizer translationInView:self.view].x/10.f, 0);
    } else if (recoginizer.state == UIGestureRecognizerStateEnded||
               recoginizer.state == UIGestureRecognizerStateCancelled||
               recoginizer.state == UIGestureRecognizerStateFailed) {
        [_animator removeBehavior:_pushBehavior];
        _pushBehavior = nil;
    }
}

#pragma mark - LoadDynamicBehaviors

- (void)createDynamicBehaviors {
    UIDynamicBehavior *behavior = [[UIDynamicBehavior alloc] init];
    [self createAttachBehaviorForBalls:behavior];
    [behavior addChildBehavior:[self createGravityBehaviorForObjects:_balls]];
    [behavior addChildBehavior:[self createCollisionBehaviorForObjects:_balls]];
    [behavior addChildBehavior:[self createItemBehavior]];
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    [_animator addBehavior:behavior];
}

- (void)createAttachBehaviorForBalls:(UIDynamicBehavior *)behavior {
    for (int i = 0; i <_count; i++) {
        UIDynamicBehavior *attachmentBehavior = [self createAttachmentBehaviorForBallBearing:[_balls objectAtIndex:i] toAnchor:[_anchors objectAtIndex:i]];
        [behavior addChildBehavior:attachmentBehavior];
    }
}

- (UIDynamicBehavior *)createAttachmentBehaviorForBallBearing:(id<UIDynamicItem>)ballBearing toAnchor:(id<UIDynamicItem>)anchor {
    UIAttachmentBehavior *behavior = [[UIAttachmentBehavior alloc] initWithItem:ballBearing
                                                               attachedToAnchor:[anchor center]];
    return behavior;
}

- (UIDynamicBehavior *)createGravityBehaviorForObjects:(NSArray *)objects {
    UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:objects];
    gravity.magnitude = 10;//重力加速度
    return gravity;
}

- (UIDynamicBehavior *)createCollisionBehaviorForObjects:(NSArray *)objects {
    return [[UICollisionBehavior alloc] initWithItems:objects];
}

- (UIDynamicItemBehavior *)createItemBehavior {
    UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:_balls];
    itemBehavior.elasticity = 1.0;
    itemBehavior.allowsRotation = NO;
    itemBehavior.resistance = 0.0;//阻力
    itemBehavior.angularResistance = 0.0;//阻力
    return itemBehavior;
}

#pragma mark - LayoutSublayer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self layoutSublayer];
}

- (void)layoutSublayer {
    for (int i = 0; i < _balls.count; i++) {
        UIView *ball = [_balls objectAtIndex:i];
        CAShapeLayer *subLayer = [_lines objectAtIndex:i];
        
        CGPoint anchorCenter = [[_anchors objectAtIndex:[_balls indexOfObject:ball]] center];
        CGPoint ballCenter = [ball center];
        
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path moveToPoint:anchorCenter];
        [path addLineToPoint:ballCenter];
        
        [subLayer removeFromSuperlayer];
        subLayer.path = path.CGPath;
        subLayer.lineWidth = 1;
        subLayer.strokeColor = [UIColor lightGrayColor].CGColor;//线的颜色
        CGPathRef bound = CGPathCreateCopyByStrokingPath(subLayer.path, nil, subLayer.lineWidth, kCGLineCapButt, kCGLineJoinMiter, subLayer.miterLimit);
        subLayer.bounds = CGPathGetBoundingBox(bound);
        subLayer.position = CGPointMake((anchorCenter.x+ballCenter.x)/2, (anchorCenter.y+ballCenter.y)/2);
        CGPathRelease(bound);
        [self.view.layer addSublayer:subLayer];
    }
    
}

- (void)dealloc {
    for (UIView *ball in _balls) {
        [ball removeObserver:self forKeyPath:@"center"];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (WGBRecordManager *)recordManager{
    if (!_recordManager) {
        _recordManager = [WGBRecordManager shareManager];
        _recordManager.delegate = self;
        _recordManager.microphoneEnabled = YES;
    }
    return _recordManager;
}


@end
