#import "DYYYVoiceChanger.h"

// 全局静态变量，记录音频助手是否处于激活/发送状态
static BOOL _isAudioAssistantActive = NO;

@implementation DYYYVoiceChanger

// 🚀 新增：实现状态管理
+ (void)setAudioAssistantActive:(BOOL)active {
    _isAudioAssistantActive = active;
    NSLog(@"[DYYYVoiceChanger] 🎛️ 音频助手状态已切换为: %@", active ? @"开启 (强制洗澡瘦身模式)" : @"关闭 (拦截模式)");
}

+ (BOOL)isAudioAssistantActive {
    return _isAudioAssistantActive;
}

// --- 供 Hook 调用的同步方法 ---
+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    // 🚨 核心防御升级：即使是音频助手，也【绝对不能】return NO！
    // 必须让所有文件都往下走，去执行底层的强制单声道和采样率转换。
    if ([self isAudioAssistantActive]) {
        NSLog(@"[DYYYVoiceChanger] 🎧 音频助手正在工作，放行原声文件并执行强制格式瘦身！");
        voiceType = 0; // 0 代表不加特效，只做格式压缩
    }
    
    __block BOOL processSuccess = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSLog(@"[DYYYVoiceChanger] ⏳ 开始处理音频，当前模式 (0为纯净格式转换): %ld", (long)voiceType);
    
    // 🚀 核心处理模块
    [self processAudioAtPath:srcPath withVoiceType:voiceType completion:^(NSString *outputPath, NSError *error) {
        if (error || !outputPath) {
            NSLog(@"[DYYYVoiceChanger] ❌ 音频核心处理失败: %@", error.localizedDescription);
            processSuccess = NO;
        } else {
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:dstPath]) {
                [fm removeItemAtPath:dstPath error:nil];
            }
            NSError *moveError = nil;
            processSuccess = [fm moveItemAtPath:outputPath toPath:dstPath error:&moveError];
            
            if (processSuccess) {
                NSLog(@"[DYYYVoiceChanger] ✅ 音频处理并瘦身完成，成功就位: %@", dstPath);
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    return processSuccess;
}

// --- 核心变声及格式化方法 (支持多效果节点串联) ---
+ (void)processAudioAtPath:(NSString *)inputPath
             withVoiceType:(NSInteger)voiceType
                completion:(void(^)(NSString *outputPath, NSError *error))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
        NSError *error = nil;
        
        AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
        if (error) { if (completion) completion(nil, error); return; }
        
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
        [engine attachNode:playerNode];
        
        // 🚀 用于按顺序存放音频效果节点的数组
        NSMutableArray<AVAudioNode *> *audioNodes = [NSMutableArray array];
        
        // -----------------------------------------------------
        // 🎛️ 根据类型动态组装效果器 (Node Chaining)
        // -----------------------------------------------------
        if (voiceType == 1) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = 1000.0;
            [engine attachNode:pitch];
            [audioNodes addObject:pitch];
        } else if (voiceType == 2) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = -800.0;
            [engine attachNode:pitch];
            [audioNodes addObject:pitch];
        } else if (voiceType == 3) {
            AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init];
            [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall];
            reverb.wetDryMix = 50.0; // 混响强度 0~100
            [engine attachNode:reverb];
            [audioNodes addObject:reverb];
        } else if (voiceType == 4) {
            AVAudioUnitDistortion *distortion = [[AVAudioUnitDistortion alloc] init];
            [distortion loadFactoryPreset:AVAudioUnitDistortionPresetSpeechRadioTower];
            distortion.wetDryMix = 70.0;
            [engine attachNode:distortion];
            [audioNodes addObject:distortion];
        } else if (voiceType == 5) {
            AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init];
            pitch.pitch = -1200.0; // 比大叔更低
            [engine attachNode:pitch];
            [audioNodes addObject:pitch];
            
            AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init];
            [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumChamber];
            reverb.wetDryMix = 40.0;
            [engine attachNode:reverb];
            [audioNodes addObject:reverb];
        }
        
        // -----------------------------------------------------
        // 🔗 动态连接所有节点
        // -----------------------------------------------------
        AVAudioFormat *sourceFormat = sourceFile.processingFormat;
        AVAudioNode *previousNode = playerNode;
        
        for (AVAudioNode *node in audioNodes) {
            [engine connect:previousNode to:node format:sourceFormat];
            previousNode = node;
        }
        // 最后一个节点连向引擎的主混音器
        [engine connect:previousNode to:engine.mainMixerNode format:sourceFormat];
        
        // ==========================================
        // 🌟 核心突破：强行定义一个“单声道 + 44100Hz”的模具格式
        // 让 AVAudioEngine 的混音器提前把立体声合并并降级！
        // ==========================================
        AVAudioFormat *monoFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 
                                                                     sampleRate:44100.0 
                                                                       channels:1 
                                                                    interleaved:NO];
        
        // 配置离线渲染：指定引擎直接输出我们需要的 monoFormat！
        [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline
                                   format:monoFormat
                        maximumFrameCount:4096
                                    error:&error];
        if (error) { if (completion) completion(nil, error); return; }
        
        [engine startAndReturnError:&error];
        if (error) { if (completion) completion(nil, error); return; }
        
        [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
        [playerNode play];
        
        // 准备输出文件
        NSString *outFileName = [NSString stringWithFormat:@"dyyy_fx_%@.m4a", [[NSUUID UUID] UUIDString]];
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:outFileName];
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        
        // 告诉文件系统我们要写入的标准配置 (单声道，AAC)
        NSDictionary *outputSettings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVSampleRateKey: @(44100.0), 
            AVNumberOfChannelsKey: @(1), 
            AVEncoderBitRateKey: @(64000) 
        };
        
        // 这里的 commonFormat 必须使用 monoFormat，与缓冲区严格一致，否则会崩溃！
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:outputURL 
                                                             settings:outputSettings 
                                                         commonFormat:monoFormat.commonFormat 
                                                          interleaved:monoFormat.isInterleaved 
                                                                error:&error];
        if (error || !outputFile) {
            if (completion) completion(nil, error);
            return;
        }
        
        // ==========================================
        // 🛡️ 稳健的渲染循环 (不再计算长度，直接等数据抽干)
        // ==========================================
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:monoFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
        
        while (YES) {
            AVAudioFrameCount framesToRender = buffer.frameCapacity;
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:framesToRender toBuffer:buffer error:&error];
            
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                // 此时 buffer 里已经是纯正的单声道数据，写入文件绝对安全！
                [outputFile writeFromBuffer:buffer error:&error];
                if (error) break;
            } else if (status == AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode) {
                // 原音频已经读取完毕，正常结束循环
                break;
            } else if (status == AVAudioEngineManualRenderingStatusError) {
                // 发生意外错误，跳出
                break;
            }
        }
        
        [playerNode stop];
        [engine stop];
        
        if (error) {
            if (completion) completion(nil, error);
        } else {
            if (completion) completion(outputPath, nil);
        }
    });
}

@end
