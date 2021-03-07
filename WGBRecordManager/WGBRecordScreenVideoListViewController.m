
#import "WGBRecordScreenVideoListViewController.h"
#import <AVKit/AVKit.h>


@interface WGBRecordScreenVideoListCell : UITableViewCell

@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UILabel *fileNameLabel;
@property (nonatomic, strong) UILabel *fileSizeLabel;

@end

@implementation WGBRecordScreenVideoListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.thumbnailImageView = [[UIImageView alloc] init];
        self.thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.thumbnailImageView];
        
        self.fileNameLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.font = [UIFont boldSystemFontOfSize:14];
            label;
        });
        [self.contentView addSubview:self.fileNameLabel];
        
        self.fileSizeLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.font = [UIFont systemFontOfSize:12];
            label;
        });
        [self.contentView addSubview:self.fileSizeLabel];

        self.thumbnailImageView.frame = CGRectMake(5, 5, 70 , 70);
        CGFloat textWidth = UIScreen.mainScreen.bounds.size.width - 90;
        self.fileNameLabel.frame = CGRectMake(80, 10,textWidth, 21);
        self.fileSizeLabel.frame = CGRectMake(80, 40,textWidth, 21);
    }
    return self;
}


@end


@interface WGBRecordScreenVideoListViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) NSMutableArray *videoFilePaths;

@end

@implementation WGBRecordScreenVideoListViewController

///MARK:- 获取文件日期
id getVideoDate(NSString *dirPath,NSString *path){
    NSString *filePath = [dirPath stringByAppendingPathComponent:path];
    NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return [info objectForKey:NSFileCreationDate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:[self videoDir] error:nil];
    //按创建文件时间倒序
    files = [files sortedArrayUsingComparator:^NSComparisonResult(NSString *path1,NSString *path2) {
        id firstDate = getVideoDate([self videoDir], path1);
        id secondDate = getVideoDate([self videoDir], path2);
        return [secondDate compare: firstDate];
    }];
    self.videoFilePaths = [files mutableCopy];
    [self.tableView reloadData];
    self.tipsLabel.frame = self.tableView.bounds;
    self.tipsLabel.hidden = self.videoFilePaths.count;
}

- (NSString *)videoDir{
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dirPath = [documentDirectory stringByAppendingPathComponent:@"record_screen_video"];
    return dirPath;
}

- (CGFloat)fileSize:(NSURL *)path{
   NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path.path error:nil];
    NSInteger fileSize =  [[attributes valueForKey:NSFileSize] integerValue];
    return fileSize/1024.00/1024.00;
}

//获取视频封面
- (UIImage*)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
  AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
  NSParameterAssert(asset);
  AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
  assetImageGenerator.appliesPreferredTrackTransform = YES;
  assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
   
  CGImageRef thumbnailImageRef = NULL;
  CFTimeInterval thumbnailImageTime = time;
  NSError *thumbnailImageGenerationError = nil;
  thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&thumbnailImageGenerationError];
  if(!thumbnailImageRef)
      NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
  UIImage*thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage: thumbnailImageRef] : nil;
    CGImageRelease(thumbnailImageRef);
    return thumbnailImage;
}

///MARK:- 播放视频
- (AVPlayerViewController *)playVideoWithFilePath:(NSString *)filePath{
    NSURL *url = [NSURL fileURLWithPath:filePath];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] init];
    playerVC.player = player;
    [player play];
    return playerVC;
}

///MARK:- UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videoFilePaths.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WGBRecordScreenVideoListCell *cell = [tableView dequeueReusableCellWithIdentifier: NSStringFromClass([WGBRecordScreenVideoListCell class])];
    if (!cell) {
        cell = [[WGBRecordScreenVideoListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:  NSStringFromClass([WGBRecordScreenVideoListCell class])];
    }
    
    NSString *path = self.videoFilePaths[indexPath.row];
    NSURL *videoURL = [NSURL fileURLWithPath: [[self videoDir] stringByAppendingPathComponent:path]];
    cell.thumbnailImageView.image = [self thumbnailImageForVideo:videoURL atTime:1.0f];
    cell.fileNameLabel.text = [path lastPathComponent];
    CGFloat fileSize = [self fileSize:videoURL];
    AVURLAsset * asset = [AVURLAsset assetWithURL:videoURL];
    CMTime time = [asset duration];
    NSInteger seconds = ceil(time.value/time.timescale);
    NSInteger sec = seconds %60;
    if (seconds < 60) {
        cell.fileSizeLabel.text = [NSString stringWithFormat:@"%.2fMB\t%ld秒",fileSize,sec];
    }else{
        NSInteger minute = ceil(seconds /60);
        cell.fileSizeLabel.text = [NSString stringWithFormat:@"%.2fMB \t%ld分%ld秒",fileSize,minute,sec];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *path = self.videoFilePaths[indexPath.row];
    AVPlayerViewController *playerVC = [self playVideoWithFilePath:[[self videoDir] stringByAppendingPathComponent:path]];
    [self presentViewController:playerVC animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteVideoFileWithIndexPath:indexPath];
    }
}

///MARK:- 删除视频
- (void)deleteVideoFileWithIndexPath:(NSIndexPath *)indexPath{
    NSString *path = self.videoFilePaths[indexPath.row];
    NSString *filePath = [[self videoDir] stringByAppendingPathComponent:path];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    [self.videoFilePaths removeObject:path];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationNone)];
    if (self.videoFilePaths.count == 0) {
        [self.tableView reloadData];
        self.tipsLabel.hidden = NO;
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point{
    NSString *path = self.videoFilePaths[indexPath.row];
    NSString *filePath = [[self videoDir] stringByAppendingPathComponent:path];

    UIAction *open = [UIAction actionWithTitle:@"快速查看" image:[UIImage systemImageNamed:@"eye.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [self presentViewController:[self playVideoWithFilePath:filePath] animated:YES completion:nil];
    }];
    
    UIAction *share = [UIAction actionWithTitle:@"分享" image:[UIImage systemImageNamed:@"square.and.arrow.up.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        NSURL *urlToShare = [NSURL fileURLWithPath:filePath];
        //分享视频
        NSArray *activityItems = @[urlToShare];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [self presentViewController:activityVC animated:YES completion:nil];
    }];
    
    UIAction *delete = [UIAction actionWithTitle:@"删除" image:[UIImage systemImageNamed:@"trash.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [self deleteVideoFileWithIndexPath:indexPath];
    }];
    delete.attributes = UIMenuElementAttributesDestructive;
    NSArray *items = @[open,share,delete];

    return [UIContextMenuConfiguration configurationWithIdentifier:filePath previewProvider:^UIViewController * _Nullable{
        AVPlayerViewController *playerVC = [self playVideoWithFilePath:filePath];
        playerVC.preferredContentSize = CGSizeMake(280, 500);
        return playerVC;
    } actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        return [UIMenu menuWithTitle:@"操作" children:items];
    }];
}


- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator{
    [animator addCompletion:^{
        NSString *filePath = (NSString *)configuration.identifier;
        [self presentViewController:[self playVideoWithFilePath:filePath] animated:YES completion:nil];
    }];
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.rowHeight = 80;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.tableHeaderView = [UIView new];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width , 64)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [self.view addSubview: _tableView];
    }
    return _tableView;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.textColor = [UIColor blackColor];
        _tipsLabel.font = [UIFont systemFontOfSize:15];
        _tipsLabel.text = @"暂无视频文件";
        [self.tableView addSubview:_tipsLabel];
    }
    return  _tipsLabel;
}

@end
