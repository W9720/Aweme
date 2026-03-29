#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface DYYYVoiceChanger : NSObject

// 核心变声方法：输入原路径 -> 变调 -> 输出新路径
+ (void)processAudioAtPath:(NSString *)inputPath
                 withPitch:(float)pitchValue // 1000 是萝莉，-1000 是大叔
                completion:(void(^)(NSString *outputPath, NSError *error))completion;

@end