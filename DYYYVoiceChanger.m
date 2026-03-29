#import "DYYYVoiceChanger.h"

@implementation DYYYVoiceChanger

+ (void)processAudioAtPath:(NSString *)inputPath withPitch:(float)pitchValue completion:(void(^)(NSString *outputPath, NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
        NSError *error = nil;
        AVAudioFile *inputFile = [[AVAudioFile alloc] initForReading:inputURL error:&error];
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *player = [[AVAudioPlayerNode alloc] init];
        AVAudioUnitTimePitch *pitchEffect = [[AVAudioUnitTimePitch alloc] init];
        
        // 设置变声参数 (Cents: 100 cents = 1 semitone)
        pitchEffect.pitch = pitchValue; 
        
        [engine attachNode:player];
        [engine attachNode:pitchEffect];
        [engine connect:player to:pitchEffect format:inputFile.processingFormat];
        [engine connect:pitchEffect to:engine.mainMixerNode format:inputFile.processingFormat];
        
        [player scheduleFile:inputFile atTime:nil completionHandler:nil];
        
        // 开启离线渲染模式 (超高速处理，不播放出声音)
        [engine setUnbufferedManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:inputFile.processingFormat maximumFrameCount:4096 error:&error];
        [engine startAndReturnError:&error];
        [player play];
        
        // 创建输出文件路径
        NSString *outputDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"DYYY_Voice"];
        [[NSFileManager defaultManager] createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *outputPath = [outputDir stringByAppendingPathComponent:[NSString stringWithFormat:@"changed_%ld.m4a", (long)[[NSDate date] timeIntervalSince1970]]];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        
        // 渲染并写入新文件
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:outputURL settings:inputFile.fileFormat.settings error:&error];
        
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:engine.manualRenderingFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
        
        while (engine.manualRenderingSampleTime < inputFile.length) {
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:engine.manualRenderingMaximumFrameCount toBuffer:buffer error:&error];
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                [outputFile writeFromBuffer:buffer error:&error];
            } else {
                break;
            }
        }
        
        [player stop];
        [engine stop];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(outputPath, nil);
        });
    });
}
@end