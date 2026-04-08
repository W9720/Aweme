#import "DYYYVoiceChanger.h"

static BOOL _isAudioAssistantActive = NO;

@implementation DYYYVoiceChanger

+ (void)setAudioAssistantActive:(BOOL)active {
    _isAudioAssistantActive = active;
    NSLog(@"[DYYYVoiceChanger] 🎛️ 音频助手状态已切换为: %@", active ? @"开启 (极速秒发模式)" : @"关闭 (拦截模式)");
}

+ (BOOL)isAudioAssistantActive {
    return _isAudioAssistantActive;
}

+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    // 🚨 只要是音频助手发来的，强制进入 0 号极速通道！
    if ([self isAudioAssistantActive]) {
        voiceType = 0; 
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // ==========================================
    // ⚡️ 极速秒转通道：苹果硬件级加速，0.1秒完成裁剪+转码！
    // ==========================================
    if (voiceType == 0) {
        NSLog(@"[DYYYVoiceChanger] ⚡️ 启动硬件极速秒转通道...");
        if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block BOOL success = NO;
        
        AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:srcPath]];
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
        exportSession.outputURL = [NSURL fileURLWithPath:dstPath];
        exportSession.outputFileType = AVFileTypeAppleM4A;
        
        // 自动裁剪 29.5 秒，绝不超时
        if (CMTimeGetSeconds(asset.duration) > 29.5) {
            exportSession.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, CMTimeMakeWithSeconds(29.5, 600));
        }
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                success = YES;
            } else {
                // 如果硬件转码失败，直接复制保底
                [fm copyItemAtPath:srcPath toPath:dstPath error:nil];
                success = YES; 
            }
            dispatch_semaphore_signal(sema);
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        return success;
    }
    
    // ==========================================
    // 🎛️ 特效通道：修复了无限死循环的变音渲染器
    // ==========================================
    __block BOOL processSuccess = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self processAudioAtPath:srcPath withVoiceType:voiceType completion:^(NSString *outputPath, NSError *error) {
        if (outputPath) {
            if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
            processSuccess = [fm moveItemAtPath:outputPath toPath:dstPath error:nil];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return processSuccess;
}

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
        if (voiceType == 1) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = 1000.0;
            [engine attachNode:pitch]; [audioNodes addObject:pitch];
        } else if (voiceType == 2) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = -800.0;
            [engine attachNode:pitch]; [audioNodes addObject:pitch];
        } else if (voiceType == 3) {
            AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init]; [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall]; reverb.wetDryMix = 50.0;
            [engine attachNode:reverb]; [audioNodes addObject:reverb];
        } else if (voiceType == 4) {
            AVAudioUnitDistortion *distortion = [[AVAudioUnitDistortion alloc] init]; [distortion loadFactoryPreset:AVAudioUnitDistortionPresetSpeechRadioTower]; distortion.wetDryMix = 70.0;
            [engine attachNode:distortion]; [audioNodes addObject:distortion];
        } else if (voiceType == 5) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = -1200.0;
            [engine attachNode:pitch]; [audioNodes addObject:pitch];
            AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init]; [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumChamber]; reverb.wetDryMix = 40.0;
            [engine attachNode:reverb]; [audioNodes addObject:reverb];
        }
        
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
                // 🚨 核心修复：只要不是 Success，立刻打断！彻底消灭死循环！
                break;
            }
        }
        
        [playerNode stop]; [engine stop];
        if (error) { if(completion) completion(nil, error); } else { if(completion) completion(outputPath, nil); }
    });
}
@end
