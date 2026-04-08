#import "DYYYVoiceChanger.h"
#import <UIKit/UIKit.h> // 🌟 新增：引入 UI 框架以支持错误弹窗

static BOOL _isAudioAssistantActive = NO;

@implementation DYYYVoiceChanger

+ (void)setAudioAssistantActive:(BOOL)active {
    _isAudioAssistantActive = active;
}

+ (BOOL)isAudioAssistantActive {
    return _isAudioAssistantActive;
}

// 🚨 错误弹窗工具
+ (void)showDebugAlert:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) { window = w; break; }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;
        UIViewController *rootVC = window.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🚨 底层转换崩溃详情" 
                                                                       message:msg 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"复制错误" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIPasteboard generalPasteboard] setString:msg];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    if ([self isAudioAssistantActive]) {
        voiceType = 0; 
    }
    
    if (voiceType == 0) {
        return [self hardTranscodeAudioFrom:srcPath to:dstPath];
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    __block BOOL processSuccess = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self processAudioAtPath:srcPath withVoiceType:voiceType completion:^(NSString *outputPath, NSError *error) {
        if (outputPath) {
            if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
            processSuccess = [fm moveItemAtPath:outputPath toPath:dstPath error:nil];
        } else if (error) {
            [self showDebugAlert:[NSString stringWithFormat:@"变声器渲染失败:\n%@", error]];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return processSuccess;
}

// 💥 带有全面错误捕获的提纯重铸机
+ (BOOL)hardTranscodeAudioFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSURL *srcURL = [NSURL fileURLWithPath:srcPath];
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:srcPath]) {
        [self showDebugAlert:[NSString stringWithFormat:@"源文件根本不存在:\n%@", srcPath]];
        return NO;
    }
    
    NSError *fileError = nil;
    if ([fm fileExistsAtPath:dstPath]) {
        [fm removeItemAtPath:dstPath error:&fileError];
        if (fileError) {
            [self showDebugAlert:[NSString stringWithFormat:@"无法删除旧文件:\n%@", fileError]];
            return NO;
        }
    }
    
    AVAsset *asset = [AVAsset assetWithURL:srcURL];
    NSError *error = nil;
    
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (!reader) {
        [self showDebugAlert:[NSString stringWithFormat:@"Reader 初始化失败 (无法解码此文件):\n%@", error]];
        return NO;
    }
    
    CMTime duration = asset.duration;
    if (CMTimeGetSeconds(duration) > 29.5) {
        reader.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(29.5, 600));
    }
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!audioTrack) {
        [self showDebugAlert:@"此文件没有音频轨道！它可能是一个损坏的文件或纯视频。"];
        return NO;
    }
    
    NSDictionary *readerSettings = @{ AVFormatIDKey: @(kAudioFormatLinearPCM) };
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:readerSettings];
    if ([reader canAddOutput:readerOutput]) {
        [reader addOutput:readerOutput];
    } else {
        [self showDebugAlert:@"Reader 拒绝添加输出端口。"];
        return NO;
    }
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:dstURL fileType:AVFileTypeAppleM4A error:&error];
    if (!writer) {
        [self showDebugAlert:[NSString stringWithFormat:@"Writer 初始化失败:\n%@", error]];
        return NO;
    }
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSData *channelLayoutData = [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)];
    
    NSDictionary *writerSettings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(16000.0),
        AVNumberOfChannelsKey: @(1),
        AVEncoderBitRateKey: @(32000),
        AVChannelLayoutKey: channelLayoutData
    };
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:writerSettings];
    writerInput.expectsMediaDataInRealTime = NO;
    
    if ([writer canAddInput:writerInput]) {
        [writer addInput:writerInput];
    } else {
        [self showDebugAlert:@"Writer 拒绝接受写入参数！极大概率是 16000Hz 采样率和当前的设备硬件编码器不兼容。"];
        return NO;
    }
    
    if (![reader startReading]) {
        [self showDebugAlert:[NSString stringWithFormat:@"无法开始读取数据:\n%@", reader.error]];
        return NO;
    }
    
    if (![writer startWriting]) {
        [self showDebugAlert:[NSString stringWithFormat:@"无法开始写入数据:\n%@", writer.error]];
        return NO;
    }
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block BOOL success = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        BOOL isFirstBuffer = YES;
        
        while (reader.status == AVAssetReaderStatusReading) {
            if (writerInput.isReadyForMoreMediaData) {
                CMSampleBufferRef buffer = [readerOutput copyNextSampleBuffer];
                if (buffer) {
                    if (isFirstBuffer) {
                        CMTime pts = CMSampleBufferGetPresentationTimeStamp(buffer);
                        [writer startSessionAtSourceTime:pts];
                        isFirstBuffer = NO;
                    }
                    if (![writerInput appendSampleBuffer:buffer]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showDebugAlert:[NSString stringWithFormat:@"数据压入时崩溃！\nWriter Error: %@\nReader Error: %@", writer.error, reader.error]];
                        });
                        CFRelease(buffer);
                        break;
                    }
                    CFRelease(buffer);
                } else {
                    [writerInput markAsFinished];
                    break;
                }
            } else {
                [NSThread sleepForTimeInterval:0.005];
            }
        }
        
        if (reader.status == AVAssetReaderStatusCompleted && !isFirstBuffer) {
            [writer finishWritingWithCompletionHandler:^{
                if (writer.status == AVAssetWriterStatusCompleted) {
                    success = YES;
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showDebugAlert:[NSString stringWithFormat:@"收尾写入失败:\n%@", writer.error]];
                    });
                }
                dispatch_semaphore_signal(sema);
            }];
        } else {
            [writer cancelWriting];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (reader.status == AVAssetReaderStatusFailed) {
                    [self showDebugAlert:[NSString stringWithFormat:@"读取过程中断:\n%@", reader.error]];
                } else if (isFirstBuffer) {
                    [self showDebugAlert:@"未能读取到任何有效数据 (文件损坏或为空)。"];
                }
            });
            dispatch_semaphore_signal(sema);
        }
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return success;
}

// --- 变声特效渲染器 (暂不修改) ---
+ (void)processAudioAtPath:(NSString *)inputPath withVoiceType:(NSInteger)voiceType completion:(void(^)(NSString *outputPath, NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
        NSError *error = nil;
        AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
        if (error || !sourceFile) { if(completion) completion(nil, error); return; }
        
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
        [engine attachNode:playerNode];
        
        NSMutableArray<AVAudioNode *> *audioNodes = [NSMutableArray array];
        if (voiceType == 1) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = 1000.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; } 
        else if (voiceType == 2) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = -800.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; } 
        else if (voiceType == 3) { AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init]; [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall]; reverb.wetDryMix = 50.0; [engine attachNode:reverb]; [audioNodes addObject:reverb]; } 
        else if (voiceType == 4) { AVAudioUnitDistortion *distortion = [[AVAudioUnitDistortion alloc] init]; [distortion loadFactoryPreset:AVAudioUnitDistortionPresetSpeechRadioTower]; distortion.wetDryMix = 70.0; [engine attachNode:distortion]; [audioNodes addObject:distortion]; } 
        else if (voiceType == 5) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = -1200.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init]; [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumChamber]; reverb.wetDryMix = 40.0; [engine attachNode:reverb]; [audioNodes addObject:reverb]; }
        
        AVAudioFormat *sourceFormat = sourceFile.processingFormat;
        AVAudioNode *previousNode = playerNode;
        for (AVAudioNode *node in audioNodes) { [engine connect:previousNode to:node format:sourceFormat]; previousNode = node; }
        [engine connect:previousNode to:engine.mainMixerNode format:sourceFormat];
        
        AVAudioFormat *monoBufferFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sourceFormat.sampleRate channels:1];
        [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:monoBufferFormat maximumFrameCount:4096 error:&error];
        if (error) { if(completion) completion(nil, error); return; }
        
        [engine startAndReturnError:&error];
        if (error) { if(completion) completion(nil, error); return; }
        
        [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
        [playerNode play];
        
        NSString *outFileName = [NSString stringWithFormat:@"dyyy_fx_%@.m4a", [[NSUUID UUID] UUIDString]];
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:outFileName];
        
        NSDictionary *outputSettings = @{ AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVSampleRateKey: @(16000.0), AVNumberOfChannelsKey: @(1), AVEncoderBitRateKey: @(32000) };
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:outputPath] settings:outputSettings commonFormat:monoBufferFormat.commonFormat interleaved:monoBufferFormat.isInterleaved error:&error];
        if (error || !outputFile) { if(completion) completion(nil, error); return; }
        
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:monoBufferFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
        
        while (YES) {
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:buffer.frameCapacity toBuffer:buffer error:&error];
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                [outputFile writeFromBuffer:buffer error:&error];
                if (error) break;
            } else {
                break;
            }
        }
        
        [playerNode stop]; [engine stop];
        if (error) { if(completion) completion(nil, error); } else { if(completion) completion(outputPath, nil); }
    });
}
@end
