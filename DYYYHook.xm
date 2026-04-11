#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 🔴 上帝视角探针：防撤回专属提示
static void showAntiRevokeToast(NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (!win) return;
        UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(win.bounds.size.width/2 - 160, 100, 320, 80)];
        toast.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.95]; // 科技蓝
        toast.textColor = [UIColor whiteColor];
        toast.text = msg;
        toast.numberOfLines = 0;
        toast.textAlignment = NSTextAlignmentCenter;
        toast.layer.cornerRadius = 15;
        toast.clipsToBounds = YES;
        toast.font = [UIFont boldSystemFontOfSize:14];
        [win addSubview:toast];
        [UIView animateWithDuration:0.5 delay:3.5 options:0 animations:^{ toast.alpha = 0; } completion:^(BOOL f){ [toast removeFromSuperview]; }];
    });
}

// ==========================================
// 🛡️ 防线 1：拦截 TIMMessage 底层 SDK 状态变更
// ==========================================
// 字节系 App 底层通常使用 TIMMessage 作为消息基类
%hook TIMMessage

// 拦截“设置为已撤回”的方法
- (void)setIsRevoked:(BOOL)revoked {
    if (revoked) {
        // 1. 发现撤回指令！强行篡改为 NO (未撤回)
        %orig(NO);
        
        // 2. 弹窗通知你，有人在“掩耳盗铃”
        dispatch_async(dispatch_get_main_queue(), ^{
            showAntiRevokeToast(@"🛡️ 拦截到一条撤回指令！\n原消息已为您保留。");
        });
        
        // 3. 拦截完毕，直接 return，不让后续的删除逻辑执行
        return;
    }
    // 正常状态放行
    %orig;
}

// 拦截获取状态的方法，永远告诉 UI 这条消息没被撤回
- (BOOL)isRevoked {
    return NO;
}

%end


// ==========================================
// 🛡️ 防线 2：拦截 AWEIMMessage 业务层状态变更 (双重保险)
// ==========================================
// 抖音上层业务逻辑可能会包装一层 AWEIMMessage
%hook AWEIMMessage

- (void)setRevoked:(BOOL)revoked {
    if (revoked) {
        %orig(NO);
        dispatch_async(dispatch_get_main_queue(), ^{
            showAntiRevokeToast(@"🛡️ 拦截到业务层撤回指令！\n消息已保住！");
        });
        return;
    }
    %orig;
}

- (BOOL)revoked {
    return NO;
}

%end