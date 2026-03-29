#import "DYYYAudioManager.h"
#import "AwemeHeaders.h"
#import "DYYYBottomAlertView.h"
#import "DYYYConfirmCloseView.h"
#import "DYYYCustomInputView.h"
#import "DYYYFilterSettingsView.h"
#import "DYYYKeywordListView.h"
#import "DYYYManager.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"
#import "DYYYVoiceViewController.h"
#import <AVFoundation/AVFoundation.h>

// ==========================================
// 完美声明区
// ==========================================
@interface DYYYManager (Download)
+ (void)downloadMediaWithProgress:(NSURL *)url mediaType:(NSInteger)mediaType audio:(NSURL *)audioURL progress:(void (^)(float progress))progressBlock completion:(void (^)(BOOL success, NSURL *fileURL))completion;
@end
// ==========================================

%hook AWELongPressPanelViewGroupModel
%property(nonatomic, assign) BOOL isDYYYCustomGroup;
%end

// ==========================================
// Modern风格长按面板（新版UI）
// ==========================================
%hook AWEModernLongPressPanelTableViewController
- (NSArray *)dataArray {
    NSArray *originalArray = %orig;
    if (!originalArray) {
        originalArray = @[];
    }

    BOOL hasAnyFeatureEnabled = NO;
    BOOL enableSaveVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveVideo"];
    BOOL enableSaveCover = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveCover"];
    BOOL enableSaveAudio = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveAudio"];
    BOOL enableSaveCurrentImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveCurrentImage"];
    BOOL enableSaveAllImages = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveAllImages"];
    BOOL enableCopyText = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCopyText"];
    BOOL enableCopyLink = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCopyLink"];
    BOOL enableApiDownload = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressApiDownload"];
    BOOL enableFilterUser = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterUser"];
    BOOL enableFilterKeyword = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterTitle"];
    BOOL enableTimerClose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressTimerClose"];
    BOOL enableCreateVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCreateVideo"];
    BOOL enableVoiceFavorites = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressVoiceFavorites"];

    hasAnyFeatureEnabled = enableSaveVideo || enableSaveCover || enableSaveAudio || enableSaveCurrentImage || enableSaveAllImages || enableCopyText || enableCopyLink || enableApiDownload ||
                           enableFilterUser || enableFilterKeyword || enableTimerClose || enableCreateVideo || enableVoiceFavorites;

    BOOL hideDaily = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelDaily"];
    BOOL hideRecommend = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelRecommend"];
    BOOL hideNotInterested = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelNotInterested"];
    BOOL hideReport = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelReport"];
    BOOL hideSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSpeed"];
    BOOL hideClearScreen = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelClearScreen"];
    BOOL hideFavorite = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelFavorite"];
    BOOL hideLater = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelLater"];
    BOOL hideCast = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelCast"];
    BOOL hideOpenInPC = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelOpenInPC"];
    BOOL hideSubtitle = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSubtitle"];
    BOOL hideAutoPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelAutoPlay"];
    BOOL hideSearchImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSearchImage"];
    BOOL hideListenDouyin = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelListenDouyin"];
    BOOL hideBackgroundPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelBackgroundPlay"];
    BOOL hideBiserial = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelBiserial"];
    BOOL hideTimerclose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelTimerClose"];

    NSMutableArray *modifiedOriginalGroups = [NSMutableArray array];

    for (id group in originalArray) {
        if ([group isKindOfClass:%c(AWELongPressPanelViewGroupModel)]) {
            AWELongPressPanelViewGroupModel *groupModel = (AWELongPressPanelViewGroupModel *)group;
            NSMutableArray *filteredGroupArr = [NSMutableArray array];

            for (id item in groupModel.groupArr) {
                if ([item isKindOfClass:%c(AWELongPressPanelBaseViewModel)]) {
                    AWELongPressPanelBaseViewModel *viewModel = (AWELongPressPanelBaseViewModel *)item;
                    NSString *descString = viewModel.describeString;
                    BOOL shouldHide = NO;
                    if (([descString isEqualToString:@"转发到日常"] || [descString isEqualToString:@"分享到日常"]) && hideDaily) {
                        shouldHide = YES;
                    } else if (([descString isEqualToString:@"推荐"] || [descString isEqualToString:@"取消推荐"]) && hideRecommend) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"不感兴趣"] && hideNotInterested) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"举报"] && hideReport) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"倍速"] && hideSpeed) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"清屏播放"] && hideClearScreen) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"缓存视频"] && hideFavorite) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"添加至稍后再看"] && hideLater) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"投屏"] && hideCast) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"电脑/Pad打开"] && hideOpenInPC) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕开关"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕设置"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"自动连播"] && hideAutoPlay) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"识别图片"] && hideSearchImage) {
                        shouldHide = YES;
                    } else if (([descString isEqualToString:@"听抖音"] || [descString isEqualToString:@"后台听"] || [descString isEqualToString:@"听视频"]) && hideListenDouyin) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"后台播放设置"] && hideBackgroundPlay) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"首页双列快捷入口"] && hideBiserial) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"定时关闭"] && hideTimerclose) {
                        shouldHide = YES;
                    }

                    if (!shouldHide) {
                        [filteredGroupArr addObject:viewModel];
                    }
                }
            }

            if (filteredGroupArr.count > 0) {
                AWELongPressPanelViewGroupModel *newGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
                newGroup.isDYYYCustomGroup = YES;
                newGroup.groupType = groupModel.groupType;
                newGroup.isModern = YES;
                newGroup.groupArr = filteredGroupArr;
                [modifiedOriginalGroups addObject:newGroup];
            }
        }
    }

    if (!hasAnyFeatureEnabled) {
        return modifiedOriginalGroups;
    }

    NSMutableArray *viewModels = [NSMutableArray array];
    BOOL isNewLivePhoto = (self.awemeModel.video && self.awemeModel.animatedImageVideoInfo != nil);

    if (enableSaveVideo && self.awemeModel.awemeType != 68 && !isNewLivePhoto) {
        AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        downloadViewModel.awemeModel = self.awemeModel;
        downloadViewModel.actionType = 666;
        downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        downloadViewModel.describeString = @"保存视频";
        downloadViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id videoModel = awemeModel.video;
            id musicModel = awemeModel.music;
            NSURL *audioURL = nil;
            
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        audioURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }

            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"h264URL")]) {
                id h264URL = [videoModel performSelector:NSSelectorFromString(@"h264URL")];
                if (h264URL && [h264URL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [h264URL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeVideo audio:audioURL completion:nil];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:downloadViewModel];
    }

    if (enableSaveVideo && self.awemeModel.awemeType != 68 && isNewLivePhoto) {
        AWELongPressPanelBaseViewModel *livePhotoViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        livePhotoViewModel.awemeModel = self.awemeModel;
        livePhotoViewModel.actionType = 679;
        livePhotoViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        livePhotoViewModel.describeString = @"保存实况";
        livePhotoViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id videoModel = awemeModel.video;

            NSURL *imageURL = nil;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"coverURL")]) {
                id coverURL = [videoModel performSelector:NSSelectorFromString(@"coverURL")];
                if (coverURL && [coverURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [coverURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        imageURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }

            NSURL *videoURL = nil;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [videoModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        videoURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            } else if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"h264URL")]) {
                id h264URL = [videoModel performSelector:NSSelectorFromString(@"h264URL")];
                if (h264URL && [h264URL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [h264URL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        videoURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }

            if (imageURL && videoURL) {
                [DYYYManager downloadLivePhoto:imageURL videoURL:videoURL completion:nil];
            }

            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:livePhotoViewModel];
    }

    if (enableSaveCurrentImage && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
        AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        imageViewModel.awemeModel = self.awemeModel;
        imageViewModel.actionType = 669;
        imageViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";

        if (self.awemeModel.albumImages.count == 1) {
            imageViewModel.describeString = @"保存图片";
        } else {
            imageViewModel.describeString = @"保存当前图片";
        }

        AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
        if (currimge.clipVideo != nil || self.awemeModel.isLivePhoto) {
            if (self.awemeModel.albumImages.count == 1) {
                imageViewModel.describeString = @"保存实况";
            } else {
                imageViewModel.describeString = @"保存当前实况";
            }
        }
        imageViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEImageAlbumImageModel *currentImageModel = nil;
            if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
            } else {
                currentImageModel = awemeModel.albumImages.firstObject;
            }

            NSURL *downloadURL = nil;
            for (NSString *urlString in currentImageModel.urlList) {
                NSURL *url = [NSURL URLWithString:urlString];
                NSString *pathExtension = [url.path.lowercaseString pathExtension];
                if (![pathExtension isEqualToString:@"image"]) {
                    downloadURL = url;
                    break;
                }
            }

            if (currentImageModel.clipVideo != nil) {
                NSURL *videoURL = [currentImageModel.clipVideo.playURL getDYYYSrcURLDownload];
                [DYYYManager downloadLivePhoto:downloadURL videoURL:videoURL completion:nil];
            } else if (currentImageModel && currentImageModel.urlList.count > 0) {
                if (downloadURL) {
                    [DYYYManager downloadMedia:downloadURL mediaType:MediaTypeImage audio:nil completion:^(BOOL success) {
                        if (!success) {
                            [DYYYUtils showToast:@"图片保存已取消"];
                        }
                    }];
                } else {
                    [DYYYUtils showToast:@"没有找到合适格式的图片"];
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:imageViewModel];
    }

    if (enableSaveAllImages && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 1) {
        AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        allImagesViewModel.awemeModel = self.awemeModel;
        allImagesViewModel.actionType = 670;
        allImagesViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        allImagesViewModel.describeString = @"保存所有图片";
        
        BOOL hasLivePhoto = NO;
        for (AWEImageAlbumImageModel *imageModel in self.awemeModel.albumImages) {
            if (imageModel.clipVideo != nil) {
                hasLivePhoto = YES;
                break;
            }
        }
        if (hasLivePhoto) {
            allImagesViewModel.describeString = @"保存所有实况";
        }
        allImagesViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            NSMutableArray *imageURLs = [NSMutableArray array];
            NSMutableArray *livePhotos = [NSMutableArray array];

            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                if (imageModel.urlList.count > 0) {
                    NSURL *downloadURL = nil;
                    for (NSString *urlString in imageModel.urlList) {
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSString *pathExtension = [url.path.lowercaseString pathExtension];
                        if (![pathExtension isEqualToString:@"image"]) {
                            downloadURL = url;
                            break;
                        }
                    }
                    if (!downloadURL && imageModel.urlList.count > 0) {
                        downloadURL = [NSURL URLWithString:imageModel.urlList.firstObject];
                    }

                    if (imageModel.clipVideo != nil) {
                        NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                        [livePhotos addObject:@{@"imageURL" : downloadURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
                    } else {
                        [imageURLs addObject:downloadURL.absoluteString];
                    }
                }
            }

            if (livePhotos.count > 0) {
                [DYYYManager downloadAllLivePhotos:livePhotos];
            }
            if (imageURLs.count > 0) {
                [DYYYManager downloadAllImages:imageURLs];
            }
            if (livePhotos.count == 0 && imageURLs.count == 0) {
                [DYYYUtils showToast:@"没有找到合适格式的图片"];
            }

            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:allImagesViewModel];
    }

    NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
    if (enableApiDownload && apiKey.length > 0) {
        AWELongPressPanelBaseViewModel *apiDownload = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        apiDownload.awemeModel = self.awemeModel;
        apiDownload.actionType = 673;
        apiDownload.duxIconName = @"ic_cloudarrowdown_outlined_20";
        apiDownload.describeString = @"接口保存";
        apiDownload.action = ^{
            NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
            if (shareLink.length == 0) {
                [DYYYUtils showToast:@"无法获取分享链接"];
                return;
            }
            [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:apiDownload];
    }

    if (enableSaveCover && self.awemeModel.awemeType != 68) {
        AWELongPressPanelBaseViewModel *coverViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        coverViewModel.awemeModel = self.awemeModel;
        coverViewModel.actionType = 667;
        coverViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        coverViewModel.describeString = @"保存封面";
        coverViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id videoModel = awemeModel.video;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"coverURL")]) {
                id coverURL = [videoModel performSelector:NSSelectorFromString(@"coverURL")];
                if (coverURL && [coverURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [coverURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeImage audio:nil completion:^(BOOL success) {
                            if (!success) {
                                [DYYYUtils showToast:@"封面保存已取消"];
                            }
                        }];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:coverViewModel];
    }

    if (enableSaveAudio) {
        AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        audioViewModel.awemeModel = self.awemeModel;
        audioViewModel.actionType = 668;
        audioViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        audioViewModel.describeString = @"保存音频";
        audioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id musicModel = awemeModel.music;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeAudio audio:nil completion:nil];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:audioViewModel];
    }

    if (enableVoiceFavorites) {
        AWELongPressPanelBaseViewModel *voiceViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        voiceViewModel.awemeModel = self.awemeModel;
        voiceViewModel.actionType = 680;
        voiceViewModel.duxIconName = @"ic_phonearrowup_outlined_20"; 
        voiceViewModel.describeString = @"音频助手";
        voiceViewModel.action = ^{
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:^{
                UIViewController *topVC = [DYYYUtils topView];
                if (!topVC) return;
                Class VoiceVCClass = NSClassFromString(@"DYYYVoiceViewController");
                if (VoiceVCClass) {
                    UIViewController *voiceVC = [[VoiceVCClass alloc] init];
                    voiceVC.modalPresentationStyle = UIModalPresentationPageSheet;
                    [topVC presentViewController:voiceVC animated:YES completion:nil];
                }
            }];
        };
        [viewModels addObject:voiceViewModel];
    }

    if (enableVoiceFavorites) {
        AWELongPressPanelBaseViewModel *favAudioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        favAudioViewModel.awemeModel = self.awemeModel;
        favAudioViewModel.actionType = 681; 
        favAudioViewModel.duxIconName = @"ic_star_outlined_20"; 
        favAudioViewModel.describeString = @"音频入库";
        favAudioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id musicModel = awemeModel.music;
            id videoModel = awemeModel.video;
            NSString *audioUrlString = nil;
            
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if ([originList isKindOfClass:[NSArray class]] && originList.count > 0) {
                        audioUrlString = originList.firstObject;
                    }
                }
            } else if (videoModel) {
                id downloadURL = nil;
                if ([videoModel respondsToSelector:NSSelectorFromString(@"downloadURL")]) {
                    downloadURL = [videoModel performSelector:NSSelectorFromString(@"downloadURL")];
                } else if ([videoModel respondsToSelector:NSSelectorFromString(@"playAddr")]) {
                    downloadURL = [videoModel performSelector:NSSelectorFromString(@"playAddr")];
                }
                if (downloadURL && [downloadURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [downloadURL performSelector:NSSelectorFromString(@"originURLList")];
                    if ([originList isKindOfClass:[NSArray class]] && originList.count > 0) {
                        audioUrlString = originList.firstObject;
                    }
                }
            }
            
            if (audioUrlString && audioUrlString.length > 0) {
                NSString *videoTitle = [awemeModel valueForKey:@"descriptionString"];
                if (!videoTitle || videoTitle.length == 0) {
                    videoTitle = [NSString stringWithFormat:@"提取音频_%ld", (long)[[NSDate date] timeIntervalSince1970]];
                } else {
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@" " withString:@""]; 
                    if (videoTitle.length > 20) {
                        videoTitle = [videoTitle substringToIndex:20];
                    }
                }
                NSString *fileName = videoTitle;
                NSURL *downloadUrl = [NSURL URLWithString:audioUrlString];
                
                [DYYYManager downloadMediaWithProgress:downloadUrl 
                                             mediaType:MediaTypeAudio
                                                 audio:nil 
                                              progress:nil 
                                            completion:^(BOOL success, NSURL *fileURL) {
                    if (success && fileURL) {
                        NSString *targetDir = [[DYYYAudioManager sharedManager] voiceDirectory];
                        NSString *safeFileName = [fileName stringByAppendingPathExtension:@"m4a"];
                        NSString *targetPath = [targetDir stringByAppendingPathComponent:safeFileName];
                        
                        if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
                            [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
                        }
                        [[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:[NSURL fileURLWithPath:targetPath] error:nil];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [DYYYUtils showToast:@"❌ 下载失败：版权限制或网络错误"];
                        });
                    }
                }];
            } else {
                [DYYYUtils showToast:@"⚠️ 此视频无法提取声音"];
            }
            
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:favAudioViewModel];
    }

    if (enableCreateVideo && self.awemeModel.awemeType == 68) {
        AWELongPressPanelBaseViewModel *createVideoViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        createVideoViewModel.awemeModel = self.awemeModel;
        createVideoViewModel.actionType = 677;
        createVideoViewModel.duxIconName = @"ic_videosearch_outlined_20";
        createVideoViewModel.describeString = @"制作视频";
        createVideoViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            NSMutableArray *imageURLs = [NSMutableArray array];
            NSMutableArray *livePhotos = [NSMutableArray array];
            NSString *bgmURL = nil;
            id musicModel = awemeModel.music;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        bgmURL = originList.firstObject;
                    }
                }
            }

            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                if (imageModel.urlList.count > 0) {
                    NSString *bestURL = nil;
                    for (NSString *urlString in imageModel.urlList) {
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSString *pathExtension = [url.path.lowercaseString pathExtension];
                        if (![pathExtension isEqualToString:@"image"]) {
                            bestURL = urlString;
                            break;
                        }
                    }
                    if (!bestURL && imageModel.urlList.count > 0) {
                        bestURL = imageModel.urlList.firstObject;
                    }
                    if (imageModel.clipVideo != nil) {
                        NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                        if (videoURL) {
                            [livePhotos addObject:@{@"imageURL" : bestURL, @"videoURL" : videoURL.absoluteString}];
                        }
                    } else {
                        [imageURLs addObject:bestURL];
                    }
                }
            }

            [DYYYManager createVideoFromMedia:imageURLs livePhotos:livePhotos bgmURL:bgmURL progress:nil completion:^(BOOL success, NSString *message) {
                if (!success) {
                    [DYYYUtils showToast:[NSString stringWithFormat:@"视频制作失败: %@", message]];
                }
            }];

            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:createVideoViewModel];
    }

    if (enableCopyText) {
        AWELongPressPanelBaseViewModel *copyText = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        copyText.awemeModel = self.awemeModel;
        copyText.actionType = 671;
        copyText.duxIconName = @"ic_xiaoxihuazhonghua_outlined";
        copyText.describeString = @"复制文案";
        copyText.action = ^{
            NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
            [[UIPasteboard generalPasteboard] setString:descText];
            [DYYYToast showSuccessToastWithMessage:@"文案已复制"];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:copyText];
    }

    if (enableCopyLink) {
        AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        copyShareLink.awemeModel = self.awemeModel;
        copyShareLink.actionType = 672;
        copyShareLink.duxIconName = @"ic_share_outlined";
        copyShareLink.describeString = @"复制链接";
        copyShareLink.action = ^{
            NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
            NSString *cleanedURL = cleanShareURL(shareLink);
            [[UIPasteboard generalPasteboard] setString:cleanedURL];
            [DYYYToast showSuccessToastWithMessage:@"分享链接已复制"];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:copyShareLink];
    }

    if (enableFilterUser) {
        AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        filterKeywords.awemeModel = self.awemeModel;
        filterKeywords.actionType = 674;
        filterKeywords.duxIconName = @"ic_userban_outlined_20";
        filterKeywords.describeString = @"过滤用户";
        filterKeywords.action = ^{
            AWEUserModel *author = self.awemeModel.author;
            NSString *nickname = author.nickname ?: @"未知用户";
            NSString *shortId = author.shortID ?: @"";
            NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];
            NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"] ?: @"";
            NSArray *userArray = [savedUsers length] > 0 ? [savedUsers componentsSeparatedByString:@","] : @[];
            BOOL userExists = NO;
            for (NSString *userInfo in userArray) {
                NSArray *components = [userInfo componentsSeparatedByString:@"-"];
                if (components.count >= 2) {
                    NSString *userId = [components lastObject];
                    if ([userId isEqualToString:shortId] && shortId.length > 0) {
                        userExists = YES;
                        break;
                    }
                }
            }
            NSString *actionButtonText = userExists ? @"取消过滤" : @"添加过滤";
            [DYYYBottomAlertView showAlertWithTitle:@"过滤用户视频" message:[NSString stringWithFormat:@"用户: %@ (ID: %@)", nickname, shortId] avatarURL:nil cancelButtonText:@"管理过滤列表" confirmButtonText:actionButtonText cancelAction:^{
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:userArray];
                keywordListView.onConfirm = ^(NSArray *users) {
                    NSString *userString = [users componentsJoinedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYFilterUsers"];
                    [DYYYUtils showToast:@"过滤用户列表已更新"];
                };
                [keywordListView show];
            } closeAction:nil confirmAction:^{
                NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];
                if (userExists) {
                    NSMutableArray *toRemove = [NSMutableArray array];
                    for (NSString *userInfo in updatedUsers) {
                        NSArray *components = [userInfo componentsSeparatedByString:@"-"];
                        if (components.count >= 2 && [[components lastObject] isEqualToString:shortId]) {
                            [toRemove addObject:userInfo];
                        }
                    }
                    [updatedUsers removeObjectsInArray:toRemove];
                    [DYYYUtils showToast:@"已从过滤列表中移除此用户"];
                } else {
                    [updatedUsers addObject:currentUserFilter];
                    [DYYYUtils showToast:@"已添加此用户到过滤列表"];
                }
                NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
                [[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYFilterUsers"];
            }];
        };
        [viewModels addObject:filterKeywords];
    }

    if (enableFilterKeyword) {
        AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        filterKeywords.awemeModel = self.awemeModel;
        filterKeywords.actionType = 675;
        filterKeywords.duxIconName = @"ic_funnel_outlined_20";
        filterKeywords.describeString = @"过滤文案";
        filterKeywords.action = ^{
            NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
            NSString *propName = nil;
            if (self.awemeModel.propGuideV2) {
                propName = self.awemeModel.propGuideV2.propName;
            }
            DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"过滤关键词调整" text:descText propName:propName];
            filterView.onConfirm = ^(NSString *selectedText) {
                if (selectedText.length > 0) {
                    NSString *currentKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                    NSString *newKeywords = currentKeywords.length > 0 ? [NSString stringWithFormat:@"%@,%@", currentKeywords, selectedText] : selectedText;
                    [[NSUserDefaults standardUserDefaults] setObject:newKeywords forKey:@"DYYYFilterKeywords"];
                    [DYYYUtils showToast:[NSString stringWithFormat:@"已添加过滤词: %@", selectedText]];
                }
            };
            filterView.onKeywordFilterTap = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                    NSString *keywordString = [keywords componentsJoinedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYFilterKeywords"];
                    [DYYYUtils showToast:@"过滤关键词已更新"];
                };
                [keywordListView show];
            };
            [filterView show];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:filterKeywords];
    }

    if (enableTimerClose) {
        AWELongPressPanelBaseViewModel *timerCloseViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        timerCloseViewModel.awemeModel = self.awemeModel;
        timerCloseViewModel.actionType = 676;
        timerCloseViewModel.duxIconName = @"ic_alarm_outlined";
        
        NSNumber *shutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
        BOOL hasActiveTimer = shutdownTime != nil && [shutdownTime doubleValue] > [[NSDate date] timeIntervalSince1970];
        timerCloseViewModel.describeString = hasActiveTimer ? @"取消定时" : @"定时关闭";
        
        timerCloseViewModel.action = ^{
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:timerCloseViewModel];
    }

    NSMutableArray *customGroups = [NSMutableArray array];
    NSInteger totalButtons = viewModels.count;
    NSInteger buttonsPerRow = 5; 
    
    for (NSInteger i = 0; i < totalButtons; i += buttonsPerRow) {
        NSInteger length = MIN(buttonsPerRow, totalButtons - i);
        NSArray<AWELongPressPanelBaseViewModel *> *rowButtons = [viewModels subarrayWithRange:NSMakeRange(i, length)];
        
        AWELongPressPanelViewGroupModel *rowGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
        rowGroup.isDYYYCustomGroup = YES;
        rowGroup.groupType = (length <= 3) ? 11 : 12;
        rowGroup.isModern = YES;
        rowGroup.groupArr = rowButtons;
        
        [customGroups addObject:rowGroup];
    }

    NSMutableArray *resultArray = [NSMutableArray arrayWithArray:customGroups];
    [resultArray addObjectsFromArray:modifiedOriginalGroups];
    return resultArray;
}
%end

%hook AWEModernLongPressHorizontalSettingCell
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.longPressViewGroupModel && [self.longPressViewGroupModel isDYYYCustomGroup]) {
        if (self.dataArray && indexPath.item < self.dataArray.count) {
            CGFloat totalWidth = collectionView.bounds.size.width;
            NSInteger itemCount = self.dataArray.count;
            CGFloat itemWidth = totalWidth / itemCount;
            return CGSizeMake(itemWidth, 73);
        }
        return CGSizeMake(73, 73);
    }
    return %orig;
}
%end

%hook AWEModernLongPressInteractiveCell
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.longPressViewGroupModel && [self.longPressViewGroupModel isDYYYCustomGroup]) {
        if (self.dataArray && indexPath.item < self.dataArray.count) {
            NSInteger itemCount = self.dataArray.count;
            CGFloat totalWidth = collectionView.bounds.size.width - 12 * (itemCount - 1);
            CGFloat itemWidth = totalWidth / itemCount;
            return CGSizeMake(itemWidth, 73);
        }
        return CGSizeMake(73, 73);
    }
    return %orig;
}
%end

// ==========================================
// 经典风格长按面板 (旧版UI)
// ==========================================
%hook AWELongPressPanelTableViewController
- (NSArray *)dataArray {
    NSArray *originalArray = %orig;
    if (!originalArray) {
        originalArray = @[];
    }
    if (!self.awemeModel.author.nickname) {
        return originalArray;
    }

    BOOL hasAnyFeatureEnabled = NO;
    BOOL enableSaveVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveVideo"];
    BOOL enableSaveCover = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveCover"];
    BOOL enableSaveAudio = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveAudio"];
    BOOL enableSaveCurrentImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveCurrentImage"];
    BOOL enableSaveAllImages = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressSaveAllImages"];
    BOOL enableCopyText = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCopyText"];
    BOOL enableCopyLink = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCopyLink"];
    BOOL enableApiDownload = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressApiDownload"];
    BOOL enableFilterUser = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterUser"];
    BOOL enableFilterKeyword = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressFilterTitle"];
    BOOL enableTimerClose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressTimerClose"];
    BOOL enableCreateVideo = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressCreateVideo"];
    BOOL enableVoiceFavorites = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYLongPressVoiceFavorites"];

    hasAnyFeatureEnabled = enableSaveVideo || enableSaveCover || enableSaveAudio || enableSaveCurrentImage || enableSaveAllImages || enableCopyText || enableCopyLink || enableApiDownload ||
                           enableFilterUser || enableFilterKeyword || enableTimerClose || enableCreateVideo || enableVoiceFavorites;

    NSMutableArray *modifiedArray = [NSMutableArray array];

    BOOL hideDaily = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelDaily"];
    BOOL hideRecommend = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelRecommend"];
    BOOL hideNotInterested = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelNotInterested"];
    BOOL hideReport = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelReport"];
    BOOL hideSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSpeed"];
    BOOL hideClearScreen = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelClearScreen"];
    BOOL hideFavorite = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelFavorite"];
    BOOL hideLater = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelLater"];
    BOOL hideCast = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelCast"];
    BOOL hideOpenInPC = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelOpenInPC"];
    BOOL hideSubtitle = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSubtitle"];
    BOOL hideAutoPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelAutoPlay"];
    BOOL hideSearchImage = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelSearchImage"];
    BOOL hideListenDouyin = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelListenDouyin"];
    BOOL hideBackgroundPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelBackgroundPlay"];
    BOOL hideBiserial = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelBiserial"];
    BOOL hideTimerclose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHidePanelTimerClose"];

    for (id group in originalArray) {
        if ([group isKindOfClass:%c(AWELongPressPanelViewGroupModel)]) {
            AWELongPressPanelViewGroupModel *groupModel = (AWELongPressPanelViewGroupModel *)group;
            NSMutableArray *filteredGroupArr = [NSMutableArray array];
            for (id item in groupModel.groupArr) {
                if ([item isKindOfClass:%c(AWELongPressPanelBaseViewModel)]) {
                    AWELongPressPanelBaseViewModel *viewModel = (AWELongPressPanelBaseViewModel *)item;
                    NSString *descString = viewModel.describeString;
                    BOOL shouldHide = NO;
                    if (([descString isEqualToString:@"转发到日常"] || [descString isEqualToString:@"分享到日常"]) && hideDaily) {
                        shouldHide = YES;
                    } else if (([descString isEqualToString:@"推荐"] || [descString isEqualToString:@"取消推荐"]) && hideRecommend) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"不感兴趣"] && hideNotInterested) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"举报"] && hideReport) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"倍速"] && hideSpeed) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"清屏播放"] && hideClearScreen) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"缓存视频"] && hideFavorite) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"添加至稍后再看"] && hideLater) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"投屏"] && hideCast) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"电脑/Pad打开"] && hideOpenInPC) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕开关"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"弹幕设置"] && hideSubtitle) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"自动连播"] && hideAutoPlay) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"识别图片"] && hideSearchImage) {
                        shouldHide = YES;
                    } else if (([descString isEqualToString:@"听抖音"] || [descString isEqualToString:@"后台听"] || [descString isEqualToString:@"听视频"]) && hideListenDouyin) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"后台播放设置"] && hideBackgroundPlay) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"首页双列快捷入口"] && hideBiserial) {
                        shouldHide = YES;
                    } else if ([descString isEqualToString:@"定时关闭"] && hideTimerclose) {
                        shouldHide = YES;
                    }

                    if (!shouldHide) {
                        [filteredGroupArr addObject:viewModel];
                    }
                } else {
                    [filteredGroupArr addObject:item];
                }
            }
            if (filteredGroupArr.count > 0) {
                AWELongPressPanelViewGroupModel *newGroup = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
                newGroup.groupType = groupModel.groupType;
                newGroup.groupArr = filteredGroupArr;
                [modifiedArray addObject:newGroup];
            }
        } else {
            [modifiedArray addObject:group];
        }
    }

    if (!hasAnyFeatureEnabled) {
        return modifiedArray;
    }

    AWELongPressPanelViewGroupModel *newGroupModel = [[%c(AWELongPressPanelViewGroupModel) alloc] init];
    newGroupModel.groupType = 0;
    NSMutableArray *viewModels = [NSMutableArray array];
    BOOL isNewLivePhoto = (self.awemeModel.video && self.awemeModel.animatedImageVideoInfo != nil);

    if (enableSaveVideo && self.awemeModel.awemeType != 68 && !isNewLivePhoto) {
        AWELongPressPanelBaseViewModel *downloadViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        downloadViewModel.awemeModel = self.awemeModel;
        downloadViewModel.actionType = 666;
        downloadViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        downloadViewModel.describeString = @"保存视频";
        downloadViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEVideoModel *videoModel = awemeModel.video;
            AWEMusicModel *musicModel = awemeModel.music;
            NSURL *audioURL = nil;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        audioURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"h264URL")]) {
                id h264URL = [videoModel performSelector:NSSelectorFromString(@"h264URL")];
                if (h264URL && [h264URL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [h264URL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeVideo audio:audioURL completion:nil];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:downloadViewModel];
    }

    if (enableSaveVideo && self.awemeModel.awemeType != 68 && isNewLivePhoto) {
        AWELongPressPanelBaseViewModel *livePhotoViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        livePhotoViewModel.awemeModel = self.awemeModel;
        livePhotoViewModel.actionType = 679;
        livePhotoViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        livePhotoViewModel.describeString = @"保存实况";
        livePhotoViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEVideoModel *videoModel = awemeModel.video;
            
            NSURL *imageURL = nil;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"coverURL")]) {
                id coverURL = [videoModel performSelector:NSSelectorFromString(@"coverURL")];
                if (coverURL && [coverURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [coverURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        imageURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }
            
            NSURL *videoURL = nil;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [videoModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        videoURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            } else if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"h264URL")]) {
                id h264URL = [videoModel performSelector:NSSelectorFromString(@"h264URL")];
                if (h264URL && [h264URL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [h264URL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        videoURL = [NSURL URLWithString:originList.firstObject];
                    }
                }
            }
            
            if (imageURL && videoURL) {
                [DYYYManager downloadLivePhoto:imageURL videoURL:videoURL completion:nil];
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:livePhotoViewModel];
    }

    if (enableSaveCurrentImage && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 0) {
        AWELongPressPanelBaseViewModel *imageViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        imageViewModel.awemeModel = self.awemeModel;
        imageViewModel.actionType = 669;
        imageViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";

        if (self.awemeModel.albumImages.count == 1) {
            imageViewModel.describeString = @"保存图片";
        } else {
            imageViewModel.describeString = @"保存当前图片";
        }
        AWEImageAlbumImageModel *currimge = self.awemeModel.albumImages[self.awemeModel.currentImageIndex - 1];
        if (currimge.clipVideo != nil || self.awemeModel.isLivePhoto) {
            if (self.awemeModel.albumImages.count == 1) {
                imageViewModel.describeString = @"保存实况";
            } else {
                imageViewModel.describeString = @"保存当前实况";
            }
        }
        imageViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEImageAlbumImageModel *currentImageModel = nil;
            if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
            } else {
                currentImageModel = awemeModel.albumImages.firstObject;
            }
            NSURL *downloadURL = nil;
            for (NSString *urlString in currentImageModel.urlList) {
                NSURL *url = [NSURL URLWithString:urlString];
                NSString *pathExtension = [url.path.lowercaseString pathExtension];
                if (![pathExtension isEqualToString:@"image"]) {
                    downloadURL = url;
                    break;
                }
            }
            if (currentImageModel.clipVideo != nil) {
                NSURL *videoURL = [currentImageModel.clipVideo.playURL getDYYYSrcURLDownload];
                [DYYYManager downloadLivePhoto:downloadURL videoURL:videoURL completion:nil];
            } else if (currentImageModel && currentImageModel.urlList.count > 0) {
                if (downloadURL) {
                    [DYYYManager downloadMedia:downloadURL mediaType:MediaTypeImage audio:nil completion:^(BOOL success) {
                        if (!success) {
                            [DYYYUtils showToast:@"图片保存已取消"];
                        }
                    }];
                } else {
                    [DYYYUtils showToast:@"没有找到合适格式的图片"];
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:imageViewModel];
    }

    if (enableSaveAllImages && self.awemeModel.awemeType == 68 && self.awemeModel.albumImages.count > 1) {
        AWELongPressPanelBaseViewModel *allImagesViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        allImagesViewModel.awemeModel = self.awemeModel;
        allImagesViewModel.actionType = 670;
        allImagesViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        allImagesViewModel.describeString = @"保存所有图片";
        BOOL hasLivePhoto = NO;
        for (AWEImageAlbumImageModel *imageModel in self.awemeModel.albumImages) {
            if (imageModel.clipVideo != nil) {
                hasLivePhoto = YES;
                break;
            }
        }
        if (hasLivePhoto) {
            allImagesViewModel.describeString = @"保存所有实况";
        }
        allImagesViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            NSMutableArray *imageURLs = [NSMutableArray array];
            NSMutableArray *livePhotos = [NSMutableArray array];
            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                if (imageModel.urlList.count > 0) {
                    NSURL *downloadURL = nil;
                    for (NSString *urlString in imageModel.urlList) {
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSString *pathExtension = [url.path.lowercaseString pathExtension];
                        if (![pathExtension isEqualToString:@"image"]) {
                            downloadURL = url;
                            break;
                        }
                    }
                    if (!downloadURL && imageModel.urlList.count > 0) {
                        downloadURL = [NSURL URLWithString:imageModel.urlList.firstObject];
                    }
                    if (imageModel.clipVideo != nil) {
                        NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                        [livePhotos addObject:@{@"imageURL" : downloadURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
                    } else {
                        [imageURLs addObject:downloadURL.absoluteString];
                    }
                }
            }
            if (livePhotos.count > 0) {
                [DYYYManager downloadAllLivePhotos:livePhotos];
            }
            if (imageURLs.count > 0) {
                [DYYYManager downloadAllImages:imageURLs];
            }
            if (livePhotos.count == 0 && imageURLs.count == 0) {
                [DYYYUtils showToast:@"没有找到合适格式的图片"];
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:allImagesViewModel];
    }

    if (enableApiDownload && [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"]) {
        NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
        if (apiKey.length > 0) {
            AWELongPressPanelBaseViewModel *apiDownload = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
            apiDownload.awemeModel = self.awemeModel;
            apiDownload.actionType = 673;
            apiDownload.duxIconName = @"ic_cloudarrowdown_outlined_20";
            apiDownload.describeString = @"接口保存";
            apiDownload.action = ^{
                NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
                if (shareLink.length == 0) {
                    [DYYYUtils showToast:@"无法获取分享链接"];
                    return;
                }
                [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];
                AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
                [panelManager dismissWithAnimation:YES completion:nil];
            };
            [viewModels addObject:apiDownload];
        }
    }

    if (enableSaveCover && self.awemeModel.awemeType != 68) {
        AWELongPressPanelBaseViewModel *coverViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        coverViewModel.awemeModel = self.awemeModel;
        coverViewModel.actionType = 667;
        coverViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        coverViewModel.describeString = @"保存封面";
        coverViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            AWEVideoModel *videoModel = awemeModel.video;
            if (videoModel && [videoModel respondsToSelector:NSSelectorFromString(@"coverURL")]) {
                id coverURL = [videoModel performSelector:NSSelectorFromString(@"coverURL")];
                if (coverURL && [coverURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [coverURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeImage audio:nil completion:^(BOOL success) {
                            if (!success) {
                                [DYYYUtils showToast:@"封面保存已取消"];
                            }
                        }];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:coverViewModel];
    }

    if (enableSaveAudio) {
        AWELongPressPanelBaseViewModel *audioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        audioViewModel.awemeModel = self.awemeModel;
        audioViewModel.actionType = 668;
        audioViewModel.duxIconName = @"ic_boxarrowdownhigh_outlined";
        audioViewModel.describeString = @"保存音频";
        audioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id musicModel = awemeModel.music;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        NSURL *url = [NSURL URLWithString:originList.firstObject];
                        [DYYYManager downloadMedia:url mediaType:MediaTypeAudio audio:nil completion:nil];
                    }
                }
            }
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:audioViewModel];
    }

    if (enableVoiceFavorites) {
        AWELongPressPanelBaseViewModel *voiceViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        voiceViewModel.awemeModel = self.awemeModel;
        voiceViewModel.actionType = 680;
        voiceViewModel.duxIconName = @"ic_phonearrowup_outlined_20"; 
        voiceViewModel.describeString = @"音频助手";
        voiceViewModel.action = ^{
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:^{
                UIViewController *topVC = [DYYYUtils topView];
                if (!topVC) return;
                Class VoiceVCClass = NSClassFromString(@"DYYYVoiceViewController");
                if (VoiceVCClass) {
                    UIViewController *voiceVC = [[VoiceVCClass alloc] init];
                    voiceVC.modalPresentationStyle = UIModalPresentationPageSheet;
                    [topVC presentViewController:voiceVC animated:YES completion:nil];
                }
            }];
        };
        [viewModels addObject:voiceViewModel];
    }

    if (enableVoiceFavorites) {
        AWELongPressPanelBaseViewModel *favAudioViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        favAudioViewModel.awemeModel = self.awemeModel;
        favAudioViewModel.actionType = 681; 
        favAudioViewModel.duxIconName = @"ic_star_outlined_20"; 
        favAudioViewModel.describeString = @"音频入库";
        favAudioViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            id musicModel = awemeModel.music;
            id videoModel = awemeModel.video;
            NSString *audioUrlString = nil;
            
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if ([originList isKindOfClass:[NSArray class]] && originList.count > 0) {
                        audioUrlString = originList.firstObject;
                    }
                }
            } else if (videoModel) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                id downloadURL = nil;
                if ([videoModel respondsToSelector:NSSelectorFromString(@"downloadURL")]) {
                    downloadURL = [videoModel performSelector:NSSelectorFromString(@"downloadURL")];
                } else if ([videoModel respondsToSelector:NSSelectorFromString(@"playAddr")]) {
                    downloadURL = [videoModel performSelector:NSSelectorFromString(@"playAddr")];
                }
                
                if (downloadURL && [downloadURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [downloadURL performSelector:NSSelectorFromString(@"originURLList")];
                    if ([originList isKindOfClass:[NSArray class]] && originList.count > 0) {
                        audioUrlString = originList.firstObject;
                    }
                }
                #pragma clang diagnostic pop
            }
            
            if (audioUrlString && audioUrlString.length > 0) {
                NSString *videoTitle = [awemeModel valueForKey:@"descriptionString"];
                if (!videoTitle || videoTitle.length == 0) {
                    videoTitle = [NSString stringWithFormat:@"提取音频_%ld", (long)[[NSDate date] timeIntervalSince1970]];
                } else {
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                    videoTitle = [videoTitle stringByReplacingOccurrencesOfString:@" " withString:@""]; 
                    if (videoTitle.length > 20) {
                        videoTitle = [videoTitle substringToIndex:20];
                    }
                }
                NSString *fileName = videoTitle;
                NSURL *downloadUrl = [NSURL URLWithString:audioUrlString];
                
                [DYYYManager downloadMediaWithProgress:downloadUrl 
                                             mediaType:MediaTypeAudio
                                                 audio:nil 
                                              progress:nil 
                                            completion:^(BOOL success, NSURL *fileURL) {
                    if (success && fileURL) {
                        NSString *targetDir = [[DYYYAudioManager sharedManager] voiceDirectory];
                        NSString *safeFileName = [fileName stringByAppendingPathExtension:@"m4a"];
                        NSString *targetPath = [targetDir stringByAppendingPathComponent:safeFileName];
                        
                        if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
                            [[NSFileManager defaultManager] removeItemAtPath:targetPath error:nil];
                        }
                        [[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:[NSURL fileURLWithPath:targetPath] error:nil];
                    }
                }];
            } else {
                [DYYYUtils showToast:@"⚠️ 此视频无法提取声音"];
            }
            
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:favAudioViewModel];
    }

    if (enableCreateVideo && self.awemeModel.awemeType == 68) {
        AWELongPressPanelBaseViewModel *createVideoViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        createVideoViewModel.awemeModel = self.awemeModel;
        createVideoViewModel.actionType = 677;
        createVideoViewModel.duxIconName = @"ic_videosearch_outlined_20";
        createVideoViewModel.describeString = @"制作视频";
        createVideoViewModel.action = ^{
            AWEAwemeModel *awemeModel = self.awemeModel;
            NSMutableArray *imageURLs = [NSMutableArray array];
            NSMutableArray *livePhotos = [NSMutableArray array];
            NSString *bgmURL = nil;
            id musicModel = awemeModel.music;
            if (musicModel && [musicModel respondsToSelector:NSSelectorFromString(@"playURL")]) {
                id playURL = [musicModel performSelector:NSSelectorFromString(@"playURL")];
                if (playURL && [playURL respondsToSelector:NSSelectorFromString(@"originURLList")]) {
                    NSArray *originList = [playURL performSelector:NSSelectorFromString(@"originURLList")];
                    if (originList.count > 0) {
                        bgmURL = originList.firstObject;
                    }
                }
            }

            for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                if (imageModel.urlList.count > 0) {
                    NSString *bestURL = nil;
                    for (NSString *urlString in imageModel.urlList) {
                        NSURL *url = [NSURL URLWithString:urlString];
                        NSString *pathExtension = [url.path.lowercaseString pathExtension];
                        if (![pathExtension isEqualToString:@"image"]) {
                            bestURL = urlString;
                            break;
                        }
                    }
                    if (!bestURL && imageModel.urlList.count > 0) {
                        bestURL = imageModel.urlList.firstObject;
                    }
                    if (imageModel.clipVideo != nil) {
                        NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                        if (videoURL) {
                            [livePhotos addObject:@{@"imageURL" : bestURL, @"videoURL" : videoURL.absoluteString}];
                        }
                    } else {
                        [imageURLs addObject:bestURL];
                    }
                }
            }

            [DYYYManager createVideoFromMedia:imageURLs livePhotos:livePhotos bgmURL:bgmURL progress:nil completion:^(BOOL success, NSString *message) {
                if (!success) {
                    [DYYYUtils showToast:[NSString stringWithFormat:@"视频制作失败: %@", message]];
                }
            }];

            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:createVideoViewModel];
    }

    if (enableCopyText) {
        AWELongPressPanelBaseViewModel *copyText = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        copyText.awemeModel = self.awemeModel;
        copyText.actionType = 671;
        copyText.duxIconName = @"ic_xiaoxihuazhonghua_outlined";
        copyText.describeString = @"复制文案";
        copyText.action = ^{
            NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
            [[UIPasteboard generalPasteboard] setString:descText];
            [DYYYToast showSuccessToastWithMessage:@"文案已复制"];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:copyText];
    }

    if (enableCopyLink) {
        AWELongPressPanelBaseViewModel *copyShareLink = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        copyShareLink.awemeModel = self.awemeModel;
        copyShareLink.actionType = 672;
        copyShareLink.duxIconName = @"ic_share_outlined";
        copyShareLink.describeString = @"复制链接";
        copyShareLink.action = ^{
            NSString *shareLink = [self.awemeModel valueForKey:@"shareURL"];
            NSString *cleanedURL = cleanShareURL(shareLink);
            [[UIPasteboard generalPasteboard] setString:cleanedURL];
            [DYYYToast showSuccessToastWithMessage:@"分享链接已复制"];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:copyShareLink];
    }

    if (enableFilterUser) {
        AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        filterKeywords.awemeModel = self.awemeModel;
        filterKeywords.actionType = 674;
        filterKeywords.duxIconName = @"ic_userban_outlined_20";
        filterKeywords.describeString = @"过滤用户";
        filterKeywords.action = ^{
            AWEUserModel *author = self.awemeModel.author;
            NSString *nickname = author.nickname ?: @"未知用户";
            NSString *shortId = author.shortID ?: @"";
            NSString *currentUserFilter = [NSString stringWithFormat:@"%@-%@", nickname, shortId];
            NSString *savedUsers = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"] ?: @"";
            NSArray *userArray = [savedUsers length] > 0 ? [savedUsers componentsSeparatedByString:@","] : @[];
            BOOL userExists = NO;
            for (NSString *userInfo in userArray) {
                NSArray *components = [userInfo componentsSeparatedByString:@"-"];
                if (components.count >= 2) {
                    NSString *userId = [components lastObject];
                    if ([userId isEqualToString:shortId] && shortId.length > 0) {
                        userExists = YES;
                        break;
                    }
                }
            }
            NSString *actionButtonText = userExists ? @"取消过滤" : @"添加过滤";
            [DYYYBottomAlertView showAlertWithTitle:@"过滤用户视频" message:[NSString stringWithFormat:@"用户: %@ (ID: %@)", nickname, shortId] avatarURL:nil cancelButtonText:@"管理过滤列表" confirmButtonText:actionButtonText cancelAction:^{
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:userArray];
                keywordListView.onConfirm = ^(NSArray *users) {
                    NSString *userString = [users componentsJoinedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setObject:userString forKey:@"DYYYFilterUsers"];
                    [DYYYUtils showToast:@"过滤用户列表已更新"];
                };
                [keywordListView show];
            } closeAction:nil confirmAction:^{
                NSMutableArray *updatedUsers = [NSMutableArray arrayWithArray:userArray];
                if (userExists) {
                    NSMutableArray *toRemove = [NSMutableArray array];
                    for (NSString *userInfo in updatedUsers) {
                        NSArray *components = [userInfo componentsSeparatedByString:@"-"];
                        if (components.count >= 2 && [[components lastObject] isEqualToString:shortId]) {
                            [toRemove addObject:userInfo];
                        }
                    }
                    [updatedUsers removeObjectsInArray:toRemove];
                    [DYYYUtils showToast:@"已从过滤列表中移除此用户"];
                } else {
                    [updatedUsers addObject:currentUserFilter];
                    [DYYYUtils showToast:@"已添加此用户到过滤列表"];
                }
                NSString *updatedUserString = [updatedUsers componentsJoinedByString:@","];
                [[NSUserDefaults standardUserDefaults] setObject:updatedUserString forKey:@"DYYYFilterUsers"];
            }];
        };
        [viewModels addObject:filterKeywords];
    }

    if (enableFilterKeyword) {
        AWELongPressPanelBaseViewModel *filterKeywords = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        filterKeywords.awemeModel = self.awemeModel;
        filterKeywords.actionType = 675;
        filterKeywords.duxIconName = @"ic_funnel_outlined_20";
        filterKeywords.describeString = @"过滤文案";
        filterKeywords.action = ^{
            NSString *descText = [self.awemeModel valueForKey:@"descriptionString"];
            NSString *propName = nil;
            if (self.awemeModel.propGuideV2) {
                propName = self.awemeModel.propGuideV2.propName;
            }
            DYYYFilterSettingsView *filterView = [[DYYYFilterSettingsView alloc] initWithTitle:@"过滤关键词调整" text:descText propName:propName];
            filterView.onConfirm = ^(NSString *selectedText) {
                if (selectedText.length > 0) {
                    NSString *currentKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                    NSString *newKeywords = currentKeywords.length > 0 ? [NSString stringWithFormat:@"%@,%@", currentKeywords, selectedText] : selectedText;
                    [[NSUserDefaults standardUserDefaults] setObject:newKeywords forKey:@"DYYYFilterKeywords"];
                    [DYYYUtils showToast:[NSString stringWithFormat:@"已添加过滤词: %@", selectedText]];
                }
            };
            filterView.onKeywordFilterTap = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                NSArray *keywordArray = [savedKeywords length] > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                    NSString *keywordString = [keywords componentsJoinedByString:@","];
                    [[NSUserDefaults standardUserDefaults] setObject:keywordString forKey:@"DYYYFilterKeywords"];
                    [DYYYUtils showToast:@"过滤关键词已更新"];
                };
                [keywordListView show];
            };
            [filterView show];
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:filterKeywords];
    }

    if (enableTimerClose) {
        AWELongPressPanelBaseViewModel *timerCloseViewModel = [[%c(AWELongPressPanelBaseViewModel) alloc] init];
        timerCloseViewModel.awemeModel = self.awemeModel;
        timerCloseViewModel.actionType = 676;
        timerCloseViewModel.duxIconName = @"ic_alarm_outlined";
        
        NSNumber *shutdownTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimerShutdownTime"];
        BOOL hasActiveTimer = shutdownTime != nil && [shutdownTime doubleValue] > [[NSDate date] timeIntervalSince1970];
        timerCloseViewModel.describeString = hasActiveTimer ? @"取消定时" : @"定时关闭";
        
        timerCloseViewModel.action = ^{
            AWELongPressPanelManager *panelManager = [%c(AWELongPressPanelManager) shareInstance];
            [panelManager dismissWithAnimation:YES completion:nil];
        };
        [viewModels addObject:timerCloseViewModel];
    }

    newGroupModel.groupArr = viewModels;

    if (modifiedArray.count > 0) {
        NSMutableArray *resultArray = [modifiedArray mutableCopy];
        [resultArray insertObject:newGroupModel atIndex:0];
        return [resultArray copy];
    } else {
        return @[ newGroupModel ];
    }
}
%end

// 隐藏评论分享功能~ 
%hook AWEIMCommentShareUserHorizontalCollectionViewCell
- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentShareToFriends"]) {
        self.hidden = YES;
    } else {
        self.hidden = NO;
    }
}
%end

%hook AWEIMCommentShareUserHorizontalSectionController
- (CGSize)sizeForItemAtIndex:(NSInteger)index model:(id)model collectionViewSize:(CGSize)size {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentShareToFriends"]) {
        return CGSizeZero;
    }
    return %orig;
}

- (void)configCell:(id)cell index:(NSInteger)index model:(id)model {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentShareToFriends"]) {
        return;
    }
    %orig;
}
%end


// ==========================================
// 🚀 评论区/私信语音提取模块 (终极全覆盖修复版)
// ==========================================
static NSString *g_lastCapturedAudioPath = nil;
static BOOL g_isLastCapturedNetwork = NO; // 显式标记当前抓到的是否为网络流

static void DYYY_CheckAndCaptureAudio(NSURL *URL, NSString *source) {
    if (!URL) return;
    
    NSString *urlStr = URL.absoluteString;
    NSString *localPath = URL.path; // 纯粹的本地路径，没有 file:// 前缀
    NSString *lowerStr = urlStr.lowercaseString;
    
    // 🛑 核心黑名单：屏蔽自己录制的、裁剪的、变声的文件
    if ([lowerStr containsString:@"temp_trimmed"] ||
        [lowerStr containsString:@"dyyy_"] ||
        [lowerStr containsString:@"record"] ||
        [lowerStr containsString:@"upload"] ||
        [lowerStr containsString:@"draft"]) {
        return;
    }
    
    BOOL isNetwork = [lowerStr hasPrefix:@"http"];
    // 扩大本地白名单，防漏抓
    BOOL isLocalTarget = localPath && (
                         [lowerStr containsString:@"cache"] ||
                         [lowerStr containsString:@"attachment"] ||
                         [lowerStr containsString:@"comment"] ||
                         [lowerStr containsString:@"im_audio"] ||
                         [lowerStr containsString:@"chat"] ||
                         [lowerStr containsString:@"audio"]); 
                         
    // 过滤掉明显的非音频文件 (视频/图片)
    if ([lowerStr containsString:@".mp4"] ||
        [lowerStr containsString:@".jpg"] ||
        [lowerStr containsString:@".png"] ||
        [lowerStr containsString:@".webp"] ||
        [lowerStr containsString:@".gif"]) {
        return;
    }

    // 🎯 记录路径并区分网络/本地
    if (isNetwork && [lowerStr containsString:@"audio"]) { 
        // 针对网络流，必须带有 audio 关键词，防止抓到网页请求
        g_lastCapturedAudioPath = urlStr;
        g_isLastCapturedNetwork = YES;
    } else if (isLocalTarget) {
        // ⚠️ 修复私信 Bug：本地文件必须存纯路径 localPath，不能存 urlStr
        g_lastCapturedAudioPath = localPath; 
        g_isLastCapturedNetwork = NO;
    }
}

// --- 🎯 全面拦截 AVFoundation 的初始化与类方法 (防止漏网) ---

%hook AVPlayerItem
- (instancetype)initWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"AVPlayerItem_Init");
    return %orig;
}
+ (instancetype)playerItemWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"AVPlayerItem_Class");
    return %orig;
}
%end

%hook AVPlayer
- (instancetype)initWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"AVPlayer_Init");
    return %orig;
}
+ (instancetype)playerWithURL:(NSURL *)URL {
    DYYY_CheckAndCaptureAudio(URL, @"AVPlayer_Class");
    return %orig;
}
%end

%hook AVAudioPlayer
- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)outError {
    DYYY_CheckAndCaptureAudio(url, @"AVAudioPlayer_Init");
    return %orig;
}
%end

%hook AVURLAsset
- (id)initWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    DYYY_CheckAndCaptureAudio(URL, @"AVURLAsset_Init");
    return %orig;
}
+ (instancetype)URLAssetWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    DYYY_CheckAndCaptureAudio(URL, @"AVURLAsset_Class");
    return %orig;
}
%end


// ==========================================
// 📱 摇一摇触发导出 (网络与本地智能分发版)
// ==========================================
%hook UIWindow
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake && g_lastCapturedAudioPath) {
        
        NSString *targetDir = [[DYYYAudioManager sharedManager] voiceDirectory];
        NSString *ext = @"aac"; // 默认 aac
        
        if (!g_isLastCapturedNetwork && g_lastCapturedAudioPath.pathExtension.length > 0) {
            ext = g_lastCapturedAudioPath.pathExtension.lowercaseString;
        } else if (g_isLastCapturedNetwork && [[NSURL URLWithString:g_lastCapturedAudioPath] pathExtension].length > 0) {
            ext = [[NSURL URLWithString:g_lastCapturedAudioPath] pathExtension].lowercaseString;
        }
        if ([ext containsString:@"tmp"]) ext = @"aac";
        
        NSString *fileName = [NSString stringWithFormat:@"提取语音_%ld.%@", (long)[[NSDate date] timeIntervalSince1970], ext];
        NSString *targetPath = [targetDir stringByAppendingPathComponent:fileName];
        
        // 🌐 场景 1：网络下载 (评论区)
        if (g_isLastCapturedNetwork) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYUtils showToast:@"⏳ 正在下载网络语音..."];
            });
            
            NSString *downloadUrl = g_lastCapturedAudioPath; // 备份URL防止被覆盖
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *audioData = [NSData dataWithContentsOfURL:[NSURL URLWithString:downloadUrl]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (audioData && [audioData writeToFile:targetPath atomically:YES]) {
                        [DYYYUtils showToast:@"✅ 摇一摇：评论语音已下载至助手！"];
                        g_lastCapturedAudioPath = nil; 
                    } else {
                        [DYYYUtils showToast:@"❌ 语音下载失败，请重新播放"];
                    }
                });
            });
            
        } 
        // 📁 场景 2：本地拷贝 (私信)
        else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:g_lastCapturedAudioPath]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] copyItemAtPath:g_lastCapturedAudioPath toPath:targetPath error:&error];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error) {
                        [DYYYUtils showToast:@"✅ 摇一摇：私信语音已提取至助手！"];
                        g_lastCapturedAudioPath = nil;
                    } else {
                        [DYYYUtils showToast:@"❌ 本地提取失败"];
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [DYYYUtils showToast:@"❌ 本地文件不存在或已失效"];
                });
            }
        }
    }
    %orig;
}
%end


%ctor {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"]) {
        %init;
    }
}

%group DYYYFilterSetterGroup
%hook HOOK_TARGET_OWNER_CLASS
- (void)setModelsArray:(id)arg1 {
    if (![arg1 isKindOfClass:[NSArray class]]) {
        %orig(arg1);
        return;
    }

    NSArray *inputArray = (NSArray *)arg1;
    NSMutableArray *filteredArray = nil;

    for (id item in inputArray) {
        NSString *className = NSStringFromClass([item class]);

        BOOL shouldFilter = ([className isEqualToString:@"AWECommentIMSwiftImpl.CommentLongPressPanelForwardElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressDaily"]) ||
                            ([className isEqualToString:@"AWECommentLongPressPanelSwiftImpl.CommentLongPressPanelCopyElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressCopy"]) ||
                            ([className isEqualToString:@"AWECommentLongPressPanelSwiftImpl.CommentLongPressPanelSaveImageElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressSaveImage"]) ||
                            ([className isEqualToString:@"AWECommentLongPressPanelSwiftImpl.CommentLongPressPanelReportElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressReport"]) ||
                            ([className isEqualToString:@"AWECommentStudioSwiftImpl.CommentLongPressPanelVideoReplyElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressVideoReply"]) ||
                            ([className isEqualToString:@"AWECommentSearchSwiftImpl.CommentLongPressPanelPictureSearchElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressPictureSearch"]) ||
                            ([className isEqualToString:@"AWECommentSearchSwiftImpl.CommentLongPressPanelSearchElement"] &&
                             [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLongPressSearch"]);

        if (shouldFilter) {
            if (!filteredArray) {
                filteredArray = [NSMutableArray arrayWithCapacity:inputArray.count];
                for (id keepItem in inputArray) {
                    if (keepItem == item)
                        break;
                    [filteredArray addObject:keepItem];
                }
            }
            continue;
        }

        if (filteredArray) {
            [filteredArray addObject:item];
        }
    }

    if (filteredArray) {
        %orig([filteredArray copy]);
    } else {
        %orig(arg1);
    }
}
%end
%end


// ==========================================
// ⚠️ 构造函数必须永远放在文件的【最底部】
// ==========================================
%ctor {
    Class ownerClass = objc_getClass("AWECommentLongPressPanelSwiftImpl.CommentLongPressPanelNormalSectionViewModel");
    if (ownerClass) {
        %init(DYYYFilterSetterGroup, HOOK_TARGET_OWNER_CLASS = ownerClass);
    }
}