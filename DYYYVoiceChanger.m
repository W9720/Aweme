#import "DYYYVoiceChanger.h"
#import <AVFoundation/AVFoundation.h>

static BOOL _isAudioAssistantActive = NO;

@implementation DYYYVoiceChanger

// 🚀 状态管理
+ (void)setAudioAssistantActive:(BOOL)active {
    _isAudioAssistantActive = active;
    NSLog(@"[DYYYVoiceChanger] 🎛️ 助手状态: %@", active ? @"开启 (底层硬核重采样)" : @"关闭");
}

+ (BOOL)isAudioAssistantActive {
    return _isAudioAssistantActive;
}

// --- 供 Hook 调用的同步方法 ---
+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    // 只要是音频助手发来的，强制进入底层重采样通道！
    if ([self isAudioAssistantActive]) {
        voiceType = 0; 
    }
    
    if (voiceType == 0) {
        NSLog(@"[DYYYVoiceChanger] ⚡️ 启动底层榨汁机：强制 16000Hz 单声道 + 精准裁剪");
        return [self ultimateConvert:srcPath to:dstPath];
    }
    
    // (变音通道暂略，优先保证原声发送100%成功)
    return [self ultimateConvert:srcPath to:dstPath];
}

// ==========================================
// ⚡️ 终极榨汁机：逐帧读取，强制降维，精准掐断
// ==========================================
+ (BOOL)ultimateConvert:(NSString *)srcPath to:(NSString *)dstPath {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block BOOL isSuccess = NO;
    
    NSURL *sourceURL = [NSURL fileURLWithPath:srcPath];
    NSURL *outputURL = [NSURL fileURLWithPath:dstPath];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:dstPath]) {
        [fm removeItemAtPath:dstPath error:nil];
    }
    
    NSError *error = nil;
    AVAsset *asset = [AVAsset assetWithURL:sourceURL];
    
    // 1. 设置读取器 (把原音频解压成最原始的 PCM 数据)
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (error) return NO;
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!audioTrack) return NO;
    
    NSDictionary *readerOutputSettings = @{ AVFormatIDKey: @(kAudioFormatLinearPCM) };
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:readerOutputSettings];
    [reader addOutput:readerOutput];
    
    // 2. 设置写入器 (强制输出抖音最爱的 M4A 格式)
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeAppleM4A error:&error];
    if (error) return NO;
    
    // 🌟 核心破局点：在这里焊死 16000Hz 和 单声道！
    NSDictionary *writerInputSettings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(16000.0),
        AVNumberOfChannelsKey: @(1),
        AVEncoderBitRateKey: @(32000)
    };
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:writerInputSettings];
    writerInput.expectsMediaDataInRealTime = NO;
    [writer addInput:writerInput];
    
    [reader startReading];
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    
    // 3. 开启流水线，逐帧压榨！
    dispatch_queue_t queue = dispatch_queue_create("com.dyyy.audioconvert", NULL);
    [writerInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        while (writerInput.readyForMoreMediaData) {
            CMSampleBufferRef sampleBuffer = [readerOutput copyNextSampleBuffer];
            if (sampleBuffer) {
                CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                
                // ✂️ 精准到毫秒的裁剪：超过 29.5 秒立刻拉闸！
                if (CMTimeGetSeconds(timestamp) > 29.5) {
                    CFRelease(sampleBuffer);
                    [writerInput markAsFinished];
                    [writer finishWritingWithCompletionHandler:^{
                        isSuccess = YES;
                        dispatch_semaphore_signal(sema);
                    }];
                    return; // 结束流水线
                }
                
                [writerInput appendSampleBuffer:sampleBuffer];
                CFRelease(sampleBuffer);
            } else {
                // 读取完毕，正常结束
                [writerInput markAsFinished];
                [writer finishWritingWithCompletionHandler:^{
                    isSuccess = (reader.status == AVAssetReaderStatusCompleted);
                    dispatch_semaphore_signal(sema);
                }];
                break;
            }
        }
    }];
    
    // 挂起等待流水线完工
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return isSuccess;
}

@end
