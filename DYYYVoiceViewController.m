#import "DYYYVoiceViewController.h"
#import "DYYYAudioManager.h"
#import "DYYYUtils.h"
#import <AVFoundation/AVFoundation.h> 
#import <objc/runtime.h>

// 新增 UIDocumentPickerDelegate 协议以支持文件导入
@interface DYYYVoiceViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIDocumentPickerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *originalDataList;
@property (nonatomic, strong) NSArray<NSDictionary *> *dataList;

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *tableHeaderView; 
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UITextField *searchField;

@property (nonatomic, strong) NSString *playingPath;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *durationCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *rawDurationCache;
@property (nonatomic, strong) NSTimer *playbackTimer;

@property (nonatomic, assign) BOOL isEditMode;
@property (nonatomic, strong) NSMutableSet<NSString *> *selectedPaths;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *deleteSelectedBtn;
@end

@implementation DYYYVoiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0]; 
    self.selectedPaths = [NSMutableSet set];
    self.durationCache = [NSMutableDictionary dictionary]; 
    self.rawDurationCache = [NSMutableDictionary dictionary]; 
    
    [self setupHeaderView];
    [self setupTableView];
    [self setupBottomBar];
    [self loadData];
}

- (void)setupHeaderView {
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    self.headerView.backgroundColor = [UIColor whiteColor];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 20)];
    titleLabel.text = self.subPath.length > 0 ? [self.subPath lastPathComponent] : @"音频助手";
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.headerView addSubview:titleLabel];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(15, 15, 30, 30);
    [closeBtn setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    closeBtn.tintColor = [UIColor blackColor];
    [closeBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:closeBtn];
    
    // 依次排列：编辑、导入、新建文件夹
    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    editBtn.frame = CGRectMake(self.view.bounds.size.width - 130, 15, 30, 30);
    [editBtn setImage:[UIImage systemImageNamed:@"checkmark.circle"] forState:UIControlStateNormal];
    editBtn.tintColor = [UIColor blackColor];
    [editBtn addTarget:self action:@selector(editTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:editBtn];
    
    // 新增：导入音频按钮
    UIButton *importBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    importBtn.frame = CGRectMake(self.view.bounds.size.width - 90, 15, 30, 30);
    [importBtn setImage:[UIImage systemImageNamed:@"square.and.arrow.down"] forState:UIControlStateNormal];
    importBtn.tintColor = [UIColor blackColor];
    [importBtn addTarget:self action:@selector(importAudioTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:importBtn];
    
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    addBtn.frame = CGRectMake(self.view.bounds.size.width - 50, 15, 30, 30);
    [addBtn setImage:[UIImage systemImageNamed:@"plus.circle"] forState:UIControlStateNormal];
    addBtn.tintColor = [UIColor blackColor];
    [addBtn addTarget:self action:@selector(addFolderTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView addSubview:addBtn];
    
    [self.view addSubview:self.headerView];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 60, self.view.bounds.size.width, self.view.bounds.size.height - 60) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0); 
    
    self.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 110)];
    
    self.searchField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, self.view.bounds.size.width - 30, 40)];
    self.searchField.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.92 alpha:1.0];
    self.searchField.layer.cornerRadius = 10;
    self.searchField.placeholder = @" 搜索声音文件";
    self.searchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchField.delegate = self;
    
    UIImageView *searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    searchIcon.image = [UIImage systemImageNamed:@"magnifyingglass"];
    searchIcon.tintColor = [UIColor grayColor];
    searchIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.searchField.leftView = searchIcon;
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    
    [self.searchField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.tableHeaderView addSubview:self.searchField];
    
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, self.view.bounds.size.width - 40, 40)];
    self.infoLabel.numberOfLines = 2;
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.font = [UIFont systemFontOfSize:12];
    self.infoLabel.textColor = [UIColor grayColor];
    [self.tableHeaderView addSubview:self.infoLabel];
    
    self.tableView.tableHeaderView = self.tableHeaderView;
    [self.view addSubview:self.tableView];
}

- (void)setupBottomBar {
    CGFloat safeBottom = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 60 + safeBottom)];
    self.bottomBar.backgroundColor = [UIColor whiteColor];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0.5)];
    line.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self.bottomBar addSubview:line];
    
    self.deleteSelectedBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteSelectedBtn.frame = CGRectMake(0, 10, self.view.bounds.size.width, 40);
    [self.deleteSelectedBtn setTitle:@"删除所选 (0)" forState:UIControlStateNormal];
    [self.deleteSelectedBtn setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    self.deleteSelectedBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.deleteSelectedBtn addTarget:self action:@selector(deleteSelectedTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.bottomBar addSubview:self.deleteSelectedBtn];
    [self.view addSubview:self.bottomBar];
}

- (void)loadData {
    self.originalDataList = [[DYYYAudioManager sharedManager] getContentsAtSubPath:self.subPath];
    self.dataList = self.originalDataList;
    [self updateHeaderInfo];
    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSDictionary *dict in self.originalDataList) {
            if (![dict[@"type"] isEqualToString:@"folder"]) {
                NSString *path = dict[@"path"];
                if (path && !self.durationCache[path]) {
                    NSURL *url = [NSURL fileURLWithPath:path];
                    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
                    CMTime time = asset.duration;
                    double seconds = CMTimeGetSeconds(time);
                    if (!isnan(seconds) && seconds > 0) {
                        NSString *durationStr;
                        if (seconds < 60) {
                            durationStr = [NSString stringWithFormat:@"%.1fs", seconds];
                        } else {
                            int m = (int)(seconds / 60);
                            int s = (int)seconds % 60;
                            durationStr = [NSString stringWithFormat:@"%dm %ds", m, s];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.durationCache[path] = durationStr;
                            self.rawDurationCache[path] = @(seconds);
                        });
                    }
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

- (void)updateHeaderInfo {
    unsigned long long totalSize = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSDictionary *dict in self.dataList) {
        if (![dict[@"type"] isEqualToString:@"folder"]) {
            NSString *filePath = dict[@"path"];
            if (filePath && [fm fileExistsAtPath:filePath]) {
                NSDictionary *attrs = [fm attributesOfItemAtPath:filePath error:nil];
                if (attrs) {
                    totalSize += [attrs fileSize];
                }
            }
        }
    }
    
    NSString *sizeStr = [DYYYUtils formattedSize:totalSize]; 
    if (self.dataList.count == 0) {
        self.infoLabel.text = @"暂无文件\n点顶栏「+」可新建文件夹";
    } else {
        self.infoLabel.text = [NSString stringWithFormat:@"共 %lu 个文件 · 总大小 %@", (unsigned long)self.dataList.count, sizeStr];
    }
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSString *searchText = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (searchText.length == 0) {
        self.dataList = self.originalDataList;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchText];
        self.dataList = [self.originalDataList filteredArrayUsingPredicate:predicate];
    }
    [self updateHeaderInfo];
    [self.tableView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.playbackTimer invalidate];
    self.playbackTimer = nil;
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        [[DYYYAudioManager sharedManager] stopPlaying];
    }
}

#pragma mark - Actions

- (void)closeTapped {
    [self.playbackTimer invalidate];
    self.playbackTimer = nil;
    [[DYYYAudioManager sharedManager] stopPlaying];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addFolderTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"新建文件夹" message:@"请输入文件夹名称" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:nil];
    
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"创建" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = alert.textFields.firstObject.text;
        if (name.length > 0) {
            BOOL success = [[DYYYAudioManager sharedManager] createFolderNamed:name atSubPath:self.subPath];
            if (success) {
                [self loadData];
                [DYYYUtils showToast:@"创建成功"];
            } else {
                [DYYYUtils showToast:@"创建失败或已存在"];
            }
        }
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:confirm];
    [self presentViewController:alert animated:YES completion:nil];
}

// 新增：获取当前工作目录的安全方法
- (NSString *)getCurrentFolderPath {
    if (self.originalDataList.count > 0) {
        return [self.originalDataList.firstObject[@"path"] stringByDeletingLastPathComponent];
    } else {
        // 空目录时临时创建一个文件夹获取路径后删除
        [[DYYYAudioManager sharedManager] createFolderNamed:@"DYYY_TMP_DIR" atSubPath:self.subPath];
        NSArray *tempList = [[DYYYAudioManager sharedManager] getContentsAtSubPath:self.subPath];
        NSString *folderPath = nil;
        for (NSDictionary *dict in tempList) {
            if ([dict[@"name"] isEqualToString:@"DYYY_TMP_DIR"]) {
                folderPath = [dict[@"path"] stringByDeletingLastPathComponent];
                [[DYYYAudioManager sharedManager] deleteItemAtPath:dict[@"path"]];
                break;
            }
        }
        return folderPath;
    }
}

// 新增：点击导入音频
- (void)importAudioTapped {
    // 允许导入所有音频类型
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.audio"] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

// 新增：文件选择器回调处理
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *fileURL = urls.firstObject;
    if (!fileURL) return;
    
    NSString *currentFolderPath = [self getCurrentFolderPath];
    if (currentFolderPath) {
        NSString *fileName = [fileURL lastPathComponent];
        NSString *destinationPath = [currentFolderPath stringByAppendingPathComponent:fileName];
        NSFileManager *fm = [NSFileManager defaultManager];
        
        if ([fm fileExistsAtPath:destinationPath]) {
            [DYYYUtils showToast:@"文件已存在！"];
            return;
        }
        
        NSError *error = nil;
        [fm copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destinationPath] error:&error];
        if (!error) {
            [self loadData];
            [DYYYUtils showToast:@"导入音频成功"];
        } else {
            [DYYYUtils showToast:@"导入失败，请重试"];
        }
    } else {
        [DYYYUtils showToast:@"无法获取当前目录"];
    }
}

- (void)editTapped:(UIButton *)sender {
    self.isEditMode = !self.isEditMode;
    [self.selectedPaths removeAllObjects];
    [self updateBottomBarState];
    [self.tableView reloadData];
}

- (void)updateBottomBarState {
    [self.deleteSelectedBtn setTitle:[NSString stringWithFormat:@"删除所选 (%lu)", (unsigned long)self.selectedPaths.count] forState:UIControlStateNormal];
    
    CGFloat safeBottom = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    [UIView animateWithDuration:0.3 animations:^{
        if (self.isEditMode) {
            self.bottomBar.frame = CGRectMake(0, self.view.bounds.size.height - 60 - safeBottom, self.view.bounds.size.width, 60 + safeBottom);
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 75 + safeBottom, 0);
        } else {
            self.bottomBar.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 60 + safeBottom);
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
        }
    }];
}

- (void)deleteSelectedTapped {
    if (self.selectedPaths.count == 0) return;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:[NSString stringWithFormat:@"确定要删除选中的 %lu 个项目吗？", (unsigned long)self.selectedPaths.count] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        for (NSString *path in self.selectedPaths) {
            [[DYYYAudioManager sharedManager] deleteItemAtPath:path];
        }
        [self.selectedPaths removeAllObjects];
        self.isEditMode = NO;
        [self updateBottomBarState];
        [self loadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)pauseDouyinVideoInViewController:(UIViewController *)vc {
    SEL pauseSel = NSSelectorFromString(@"pause");
    if ([vc respondsToSelector:pauseSel]) {
        IMP imp = [vc methodForSelector:pauseSel];
        void (*func)(id, SEL) = (void *)imp;
        func(vc, pauseSel);
    }
    for (UIViewController *child in vc.childViewControllers) {
        [self pauseDouyinVideoInViewController:child];
    }
}

- (void)autoResetPlayState {
    self.playingPath = nil;
    [self.tableView reloadData];
}

- (void)playTapped:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    if (!indexPath || indexPath.row >= self.dataList.count) return;
    
    NSDictionary *item = self.dataList[indexPath.row];
    NSString *path = item[@"path"];
    
    [self.playbackTimer invalidate];
    self.playbackTimer = nil;
    
    if ([self.playingPath isEqualToString:path]) {
        [[DYYYAudioManager sharedManager] stopPlaying];
        self.playingPath = nil; 
    } else {
        self.playingPath = path;
        UIViewController *rootVC = UIApplication.sharedApplication.keyWindow.rootViewController;
        if (rootVC) [self pauseDouyinVideoInViewController:rootVC];
        
        [[DYYYAudioManager sharedManager] playAudioNamed:item[@"name"]]; 
        
        NSTimeInterval duration = [self.rawDurationCache[path] doubleValue];
        if (duration > 0) {
            self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:(duration + 0.1) target:self selector:@selector(autoResetPlayState) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:self.playbackTimer forMode:NSRunLoopCommonModes];
        }
    }
    
    [self.tableView reloadData];
}

- (void)sendTapped:(UIButton *)sender {
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    if (!indexPath || indexPath.row >= self.dataList.count) return;
    
    NSDictionary *item = self.dataList[indexPath.row];
    NSString *path = item[@"path"];
    
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"DYYY_PendingReplacePath"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DYYY_IsArmed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"音频装填成功！" 
                                                                   message:@"请返回【评论区】或【私信框】\n长按麦克风录音 1 秒即可自动发送该音频！" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TableView Delegate & DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"DYYYVoiceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIImageView *selectIcon = [[UIImageView alloc] initWithFrame:CGRectMake(15, 30, 20, 20)];
        selectIcon.tag = 106;
        selectIcon.contentMode = UIViewContentModeScaleAspectFit;
        [cell.contentView addSubview:selectIcon];
        
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(15, 5, self.view.bounds.size.width - 30, 70)];
        bgView.backgroundColor = [UIColor whiteColor];
        bgView.layer.cornerRadius = 12;
        bgView.tag = 100;
        [cell.contentView addSubview:bgView];
        
        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 20, 30, 30)];
        iconView.tag = 101;
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        [bgView addSubview:iconView];
        
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.tag = 102;
        titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [bgView addSubview:titleLabel];
        
        UILabel *subLabel = [[UILabel alloc] init];
        subLabel.tag = 103;
        subLabel.font = [UIFont systemFontOfSize:12];
        subLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
        [bgView addSubview:subLabel];
        
        UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        playBtn.frame = CGRectMake(bgView.bounds.size.width - 90, 20, 30, 30);
        playBtn.tag = 104;
        [playBtn addTarget:self action:@selector(playTapped:) forControlEvents:UIControlEventTouchUpInside];
        [bgView addSubview:playBtn];
        
        UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        sendBtn.frame = CGRectMake(bgView.bounds.size.width - 45, 20, 30, 30);
        [sendBtn setImage:[UIImage systemImageNamed:@"paperplane.fill"] forState:UIControlStateNormal];
        sendBtn.tintColor = [UIColor systemBlueColor];
        sendBtn.tag = 105;
        [sendBtn addTarget:self action:@selector(sendTapped:) forControlEvents:UIControlEventTouchUpInside];
        [bgView addSubview:sendBtn];
        
        UIImageView *arrow = [[UIImageView alloc] initWithFrame:CGRectMake(bgView.bounds.size.width - 30, 25, 15, 20)];
        arrow.image = [UIImage systemImageNamed:@"chevron.right"];
        arrow.tintColor = [UIColor lightGrayColor];
        arrow.tag = 107;
        [bgView addSubview:arrow];
    }
    
    NSDictionary *item = self.dataList[indexPath.row];
    UIView *bgView = [cell.contentView viewWithTag:100];
    UIImageView *iconView = (UIImageView *)[bgView viewWithTag:101];
    UILabel *titleLabel = (UILabel *)[bgView viewWithTag:102];
    UILabel *subLabel = (UILabel *)[bgView viewWithTag:103];
    UIButton *playBtn = (UIButton *)[bgView viewWithTag:104];
    UIButton *sendBtn = (UIButton *)[bgView viewWithTag:105];
    UIImageView *selectIcon = (UIImageView *)[cell.contentView viewWithTag:106];
    UIImageView *arrow = (UIImageView *)[bgView viewWithTag:107];
    
    titleLabel.text = item[@"name"];
    
    if (self.isEditMode) {
        selectIcon.hidden = NO;
        bgView.frame = CGRectMake(50, 5, self.view.bounds.size.width - 65, 70);
        if ([self.selectedPaths containsObject:item[@"path"]]) {
            selectIcon.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
            selectIcon.tintColor = [UIColor systemBlueColor];
        } else {
            selectIcon.image = [UIImage systemImageNamed:@"circle"];
            selectIcon.tintColor = [UIColor lightGrayColor];
        }
        playBtn.hidden = YES;
        sendBtn.hidden = YES;
        arrow.hidden = YES; 
    } else {
        selectIcon.hidden = YES;
        bgView.frame = CGRectMake(15, 5, self.view.bounds.size.width - 30, 70);
    }
    
    if ([item[@"type"] isEqualToString:@"folder"]) {
        iconView.hidden = NO;
        iconView.image = [UIImage systemImageNamed:@"folder.fill"];
        iconView.tintColor = [UIColor colorWithRed:0.3 green:0.4 blue:0.9 alpha:1.0];
        titleLabel.frame = CGRectMake(60, 25, bgView.bounds.size.width - 100, 20);
        subLabel.hidden = YES; 
        playBtn.hidden = YES;  
        sendBtn.hidden = YES;  
        if (!self.isEditMode) { arrow.hidden = NO; }
    } else {
        iconView.hidden = YES; 
        titleLabel.frame = CGRectMake(15, 15, bgView.bounds.size.width - 110, 20);
        subLabel.frame = CGRectMake(15, 40, bgView.bounds.size.width - 110, 15);
        subLabel.hidden = NO;
        
        NSString *duration = self.durationCache[item[@"path"]];
        if (duration) {
            subLabel.text = [NSString stringWithFormat:@"%@ · %@ · %@", item[@"ext"], duration, item[@"size"]];
        } else {
            subLabel.text = [NSString stringWithFormat:@"%@ · %@", item[@"ext"], item[@"size"]];
        }
        arrow.hidden = YES; 
        
        if (!self.isEditMode) {
            playBtn.hidden = NO;
            sendBtn.hidden = NO;
            BOOL isPlaying = [self.playingPath isEqualToString:item[@"path"]];
            [playBtn setImage:[UIImage systemImageNamed:isPlaying ? @"pause.fill" : @"play.fill"] forState:UIControlStateNormal];
            
            // 新增：判断是否在播放，播放中变为红色，未播放保持默认绿色
            playBtn.tintColor = isPlaying ? [UIColor systemRedColor] : [UIColor colorWithRed:0.1 green:0.8 blue:0.3 alpha:1.0];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.dataList[indexPath.row];
    NSString *path = item[@"path"];
    
    if (self.isEditMode) {
        if ([self.selectedPaths containsObject:path]) {
            [self.selectedPaths removeObject:path];
        } else {
            [self.selectedPaths addObject:path];
        }
        [self updateBottomBarState];
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        return;
    }
    
    if ([item[@"type"] isEqualToString:@"folder"]) {
        DYYYVoiceViewController *subVC = [[DYYYVoiceViewController alloc] init];
        NSString *newPath = self.subPath ? [self.subPath stringByAppendingPathComponent:item[@"name"]] : item[@"name"];
        subVC.subPath = newPath;
        subVC.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:subVC animated:YES completion:nil];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditMode) return nil;
    
    NSDictionary *item = self.dataList[indexPath.row];
    NSString *path = item[@"path"];
    BOOL isFolder = [item[@"type"] isEqualToString:@"folder"];
    
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认删除" message:[NSString stringWithFormat:@"是否删除 %@？", item[@"name"]] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(NO);
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if ([[DYYYAudioManager sharedManager] deleteItemAtPath:path]) {
                [self loadData]; 
                completionHandler(YES);
            } else {
                [DYYYUtils showToast:@"删除失败"];
                completionHandler(NO);
            }
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    deleteAction.image = [UIImage systemImageNamed:@"trash.fill"];
    deleteAction.backgroundColor = [UIColor systemRedColor];
    
    UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            activityVC.popoverPresentationController.sourceView = sourceView;
        }
        [self presentViewController:activityVC animated:YES completion:nil];
        completionHandler(YES);
    }];
    shareAction.image = [UIImage systemImageNamed:@"square.and.arrow.up.fill"];
    shareAction.backgroundColor = [UIColor colorWithRed:0.35 green:0.34 blue:0.84 alpha:1.0];
    
    UIContextualAction *renameAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"重命名" message:@"请输入新名称" preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = item[@"name"];
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(NO);
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *newName = alert.textFields.firstObject.text;
            if (newName.length > 0) {
                if ([[DYYYAudioManager sharedManager] renameItemAtPath:path toNewName:newName]) {
                    [self loadData]; 
                    completionHandler(YES);
                } else {
                    [DYYYUtils showToast:@"重命名失败或名称已存在"];
                    completionHandler(NO);
                }
            } else {
                completionHandler(NO);
            }
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    renameAction.image = [UIImage systemImageNamed:@"square.and.pencil"];
    renameAction.backgroundColor = [UIColor systemBlueColor];
    
    UISwipeActionsConfiguration *config;
    if (isFolder) {
        config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, renameAction]];
    } else {
        config = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, shareAction, renameAction]];
    }
    
    config.performsFirstActionWithFullSwipe = NO;
    
    return config;
}
@end

// =======================================================
// 语音替换引擎 (原生 Runtime 实现，100% 免疫 Theos 报错)
// =======================================================
@interface DYYYVoiceHelper : NSObject
+ (void)processAndReplace:(NSString *)targetPath;
+ (void)showCustomToast:(NSString *)msg;
@end

@implementation DYYYVoiceHelper
+ (void)showCustomToast:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (!win) return;
        
        // 修改这个数值调整弹窗高度，越大越靠下
        CGFloat toastY = 200; 
        
        UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(win.bounds.size.width/2 - 100, toastY, 200, 40)];
        toast.backgroundColor = [UIColor colorWithRed:0.1 green:0.8 blue:0.3 alpha:0.95]; 
        toast.textColor = [UIColor whiteColor];
        toast.text = msg;
        toast.textAlignment = NSTextAlignmentCenter;
        toast.layer.cornerRadius = 20;
        toast.clipsToBounds = YES;
        toast.font = [UIFont boldSystemFontOfSize:14];
        
        [win addSubview:toast];
        
        toast.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{ toast.alpha = 1; } completion:^(BOOL f){
            [UIView animateWithDuration:0.3 delay:2.0 options:0 animations:^{ toast.alpha = 0; } completion:^(BOOL f){ [toast removeFromSuperview]; }];
        }];
    });
}

+ (void)processAndReplace:(NSString *)targetPath {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isArmed = [defaults boolForKey:@"DYYY_IsArmed"];
    NSString *pendingPath = [defaults stringForKey:@"DYYY_PendingReplacePath"];
    
    if (!isArmed || !pendingPath || pendingPath.length == 0) return;
    
    [defaults setBool:NO forKey:@"DYYY_IsArmed"];
    [defaults synchronize];

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:pendingPath]) return;
    
    NSTimeInterval duration = CMTimeGetSeconds([AVURLAsset assetWithURL:[NSURL fileURLWithPath:pendingPath]].duration);
    
    if (duration <= 29.5) {
        if ([fm fileExistsAtPath:targetPath]) [fm removeItemAtPath:targetPath error:nil];
        [fm copyItemAtPath:pendingPath toPath:targetPath error:nil];
        [self showCustomToast:@"✅ 语音发送替换成功！"];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self showCustomToast:@"⏳ 音频过长，正在为您自动裁剪..."];
            NSString *tempTrimmedPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp_trimmed.m4a"];
            if ([fm fileExistsAtPath:tempTrimmedPath]) [fm removeItemAtPath:tempTrimmedPath error:nil];
            
            AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:pendingPath]];
            AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
            exportSession.outputURL = [NSURL fileURLWithPath:tempTrimmedPath];
            exportSession.outputFileType = AVFileTypeAppleM4A;
            exportSession.timeRange = CMTimeRangeFromTimeToTime(CMTimeMake(0, 1), CMTimeMakeWithSeconds(29.5, 600));
            
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            [exportSession exportAsynchronouslyWithCompletionHandler:^{ dispatch_semaphore_signal(sema); }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                if ([fm fileExistsAtPath:targetPath]) [fm removeItemAtPath:targetPath error:nil];
                [fm copyItemAtPath:tempTrimmedPath toPath:targetPath error:nil];
                [self showCustomToast:@"✅ 已裁剪并替换 (29s)"];
            } else {
                [self showCustomToast:@"❌ 裁剪失败，将原样强制替换"];
                if ([fm fileExistsAtPath:targetPath]) [fm removeItemAtPath:targetPath error:nil];
                [fm copyItemAtPath:pendingPath toPath:targetPath error:nil];
            }
        });
    }
}
@end

static void (*original_AWEIMMessageBaseViewController_sendMessage)(id, SEL, id);
static void replaced_AWEIMMessageBaseViewController_sendMessage(id self, SEL _cmd, id msg) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"DYYY_IsArmed"] && [defaults stringForKey:@"DYYY_PendingReplacePath"]) {
        NSString *msgDesc = [NSString stringWithFormat:@"%@", msg];
        @try {
            if ([msg respondsToSelector:@selector(yy_modelToJSONObject)]) {
                msgDesc = [NSString stringWithFormat:@"%@\n%@", msgDesc, [msg performSelector:@selector(yy_modelToJSONObject)]];
            }
        } @catch(NSException *e){}
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?:/private)?/var/mobile/Containers/Data/Application/[A-Z0-9\\-]+/[\\w\\-/\\.]+" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:msgDesc options:0 range:NSMakeRange(0, msgDesc.length)];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSTextCheckingResult *match in matches) {
            NSString *path = [msgDesc substringWithRange:match.range];
            BOOL isDir = NO;
            if ([fm fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
                NSString *ext = path.pathExtension.lowercaseString;
                if ([ext isEqualToString:@"aac"] || [ext isEqualToString:@"m4a"] || [ext isEqualToString:@"wav"] || [ext isEqualToString:@"caf"] || [path.lowercaseString containsString:@"audio"] || [path.lowercaseString containsString:@"voice"]) {
                    [DYYYVoiceHelper processAndReplace:path];
                    break;
                }
            }
        }
    }
    if (original_AWEIMMessageBaseViewController_sendMessage) {
        original_AWEIMMessageBaseViewController_sendMessage(self, _cmd, msg);
    }
}

static void (*original_AVAudioRecorder_stop)(id, SEL);
static void replaced_AVAudioRecorder_stop(id self, SEL _cmd) {
    if (original_AVAudioRecorder_stop) {
        original_AVAudioRecorder_stop(self, _cmd);
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYY_IsArmed"]) {
        if ([self respondsToSelector:@selector(url)]) {
            NSURL *url = [self performSelector:@selector(url)];
            if (url && url.path) {
                [DYYYVoiceHelper processAndReplace:url.path];
            }
        }
    }
}

static BOOL (*original_NSFileManager_moveItemAtPath)(NSFileManager*, SEL, NSString*, NSString*, NSError**);
static BOOL replaced_NSFileManager_moveItemAtPath(NSFileManager* self, SEL _cmd, NSString* src, NSString* dst, NSError** err) {
    BOOL result = NO;
    if (original_NSFileManager_moveItemAtPath) {
        result = original_NSFileManager_moveItemAtPath(self, _cmd, src, dst, err);
    }
    if (result && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYY_IsArmed"] && dst) {
        NSString *ext = dst.pathExtension.lowercaseString;
        if ([ext isEqualToString:@"m4a"] || [ext isEqualToString:@"aac"] || [ext isEqualToString:@"wav"] || [ext isEqualToString:@"mp3"] || [dst.lowercaseString containsString:@"audio"] || [dst.lowercaseString containsString:@"voice"]) {
            [DYYYVoiceHelper processAndReplace:dst];
        }
    }
    return result;
}

// 注册 Hook
__attribute__((constructor)) static void DYYYVoiceHookInit() {
    Class msgClass = NSClassFromString(@"AWEIMMessageBaseViewController");
    if (msgClass) {
        Method m1 = class_getInstanceMethod(msgClass, NSSelectorFromString(@"sendMessage:"));
        if (m1) {
            original_AWEIMMessageBaseViewController_sendMessage = (void (*)(id, SEL, id))method_getImplementation(m1);
            method_setImplementation(m1, (IMP)replaced_AWEIMMessageBaseViewController_sendMessage);
        }
    }
    
    Class recorderClass = NSClassFromString(@"AVAudioRecorder");
    if (recorderClass) {
        Method m2 = class_getInstanceMethod(recorderClass, NSSelectorFromString(@"stop"));
        if (m2) {
            original_AVAudioRecorder_stop = (void (*)(id, SEL))method_getImplementation(m2);
            method_setImplementation(m2, (IMP)replaced_AVAudioRecorder_stop);
        }
    }

    Class fmClass = NSClassFromString(@"NSFileManager");
    if (fmClass) {
        Method m3 = class_getInstanceMethod(fmClass, NSSelectorFromString(@"moveItemAtPath:toPath:error:"));
        if (m3) {
            original_NSFileManager_moveItemAtPath = (BOOL (*)(NSFileManager*, SEL, NSString*, NSString*, NSError**))method_getImplementation(m3);
            method_setImplementation(m3, (IMP)replaced_NSFileManager_moveItemAtPath);
        }
    }
}
