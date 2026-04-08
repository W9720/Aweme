#import "DYYYVoiceChanger.h"
#import <UIKit/UIKit.h>

static BOOL _isAudioAssistantActive = NO;

@implementation DYYYVoiceChanger

+ (void)setAudioAssistantActive:(BOOL)active {
    _isAudioAssistantActive = active;
}

+ (BOOL)isAudioAssistantActive {
    return _isAudioAssistantActive;
}

+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    if ([self isAudioAssistantActive]) {
        voiceType = 0; 
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (voiceType == 0) {
        // 🌊 瀑布流第一层：严格解码 (针对标准 M4A/MP4 极速处理)
        if ([self hardTranscodeAudioFrom:srcPath to:dstPath]) {
            return YES;
        }
        
        // 🌊 瀑布流第二层：智能嗅探引擎！(照妖镜，专门对付假后缀、MP3伪装文件)
        NSLog(@"[DYYYVoiceChanger] ⚠️ 严格解码失败，启动智能嗅探引擎提纯...");
        if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
        if ([self engineTranscodeAudioFrom:srcPath to:dstPath]) {
            return YES;
        }
        
        // 🌊 瀑布流第三层：原生导出器兜底
        NSLog(@"[DYYYVoiceChanger] ⚠️ 嗅探引擎也失败，启动原生兜底...");
        if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
        __block BOOL exportSuccess = NO;
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self fallbackExportAudio:[NSURL fileURLWithPath:srcPath] to:dstPath completion:^(BOOL success) {
            exportSuccess = success;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        return exportSuccess;
    }
    
    // 🎛️ 变声特效通道...
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

// ==========================================
// 🛡️ 第二层神技：智能嗅探提纯机 (无视假后缀，精准裁剪 29.5s)
// ==========================================
+ (BOOL)engineTranscodeAudioFrom:(NSString *)inputPath to:(NSString *)outputPath {
    NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
    NSError *error = nil;
    
    // AVAudioFile 拥有嗅探能力，无视假后缀
    AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
    if (!sourceFile) return NO;
    
    AVAudioEngine *engine = [[AVAudioEngine alloc] init];
    AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
    [engine attachNode:playerNode];
    [engine connect:playerNode to:engine.mainMixerNode format:sourceFile.processingFormat];
    
    AVAudioFormat *monoBufferFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:sourceFile.processingFormat.sampleRate channels:1];
    
    [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:monoBufferFormat maximumFrameCount:4096 error:&error];
    if (error) return NO;
    
    [engine startAndReturnError:&error];
    if (error) return NO;
    
    [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
    [playerNode play];
    
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSData *channelLayoutData = [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)];
    
    NSDictionary *outputSettings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(16000.0),
        AVNumberOfChannelsKey: @(1),
        AVEncoderBitRateKey: @(32000),
        AVChannelLayoutKey: channelLayoutData
    };
    
    AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:outputPath] settings:outputSettings commonFormat:monoBufferFormat.commonFormat interleaved:monoBufferFormat.isInterleaved error:&error];
    if (!outputFile) return NO;
    
    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:monoBufferFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
    
    // 精准截断：最多只取 29.5 秒！
    AVAudioFramePosition maxLength = (AVAudioFramePosition)(29.5 * sourceFile.processingFormat.sampleRate);
    AVAudioFramePosition targetLength = MIN(sourceFile.length, maxLength);
    
    BOOL success = YES;
    while (engine.manualRenderingSampleTime < targetLength) {
        AVAudioFrameCount framesToRender = (AVAudioFrameCount)MIN(buffer.frameCapacity, targetLength - engine.manualRenderingSampleTime);
        AVAudioEngineManualRenderingStatus status = [engine renderOffline:framesToRender toBuffer:buffer error:&error];
        
        if (status == AVAudioEngineManualRenderingStatusSuccess) {
            [outputFile writeFromBuffer:buffer error:&error];
            if (error) { success = NO; break; }
        } else if (status == AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode) {
            break; 
        } else {
            success = NO; break;
        }
    }
    
    [playerNode stop];
    [engine stop];
    return success;
}

// 🛡️ 第一层：严格提纯机
+ (BOOL)hardTranscodeAudioFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSURL *srcURL = [NSURL fileURLWithPath:srcPath];
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    
    AVAsset *asset = [AVAsset assetWithURL:srcURL];
    NSError *error = nil;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (!reader) return NO;
    
    CMTime duration = asset.duration;
    if (CMTimeGetSeconds(duration) > 29.5) {
        reader.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(29.5, 600));
    }
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!audioTrack) return NO;
    
    NSDictionary *readerSettings = @{ AVFormatIDKey: @(kAudioFormatLinearPCM) };
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:readerSettings];
    if (![reader canAddOutput:readerOutput]) return NO;
    [reader addOutput:readerOutput];
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:dstURL fileType:AVFileTypeAppleM4A error:&error];
    if (!writer) return NO;
    
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
    if (![writer canAddInput:writerInput]) return NO;
    [writer addInput:writerInput];
    
    if (![reader startReading]) return NO;
    if (![writer startWriting]) return NO;
    
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
                success = (writer.status == AVAssetWriterStatusCompleted);
                dispatch_semaphore_signal(sema);
            }];
        } else {
            [writer cancelWriting];
            dispatch_semaphore_signal(sema);
        }
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return success;
}

// 🛡️ 第三层：原生兜底
+ (void)fallbackExportAudio:(NSURL *)sourceURL to:(NSString *)dstPath completion:(void(^)(BOOL))completion {
    AVAsset *asset = [AVAsset assetWithURL:sourceURL];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    exportSession.outputURL = [NSURL fileURLWithPath:dstPath];
    exportSession.outputFileType = AVFileTypeAppleM4A;
    if (CMTimeGetSeconds(asset.duration) > 29.5) {
        exportSession.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, CMTimeMakeWithSeconds(29.5, 600));
    }
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (completion) completion(exportSession.status == AVAssetExportSessionStatusCompleted);
    }];
}

// --- 变声特效渲染器 (无改动) ---
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
        
        AVAudioFramePosition maxLength = (AVAudioFramePosition)(29.5 * sourceFile.processingFormat.sampleRate);
        AVAudioFramePosition targetLength = MIN(sourceFile.length, maxLength);
        
        while (engine.manualRenderingSampleTime < targetLength) {
            AVAudioFrameCount framesToRender = (AVAudioFrameCount)MIN(buffer.frameCapacity, targetLength - engine.manualRenderingSampleTime);
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:framesToRender toBuffer:buffer error:&error];
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
