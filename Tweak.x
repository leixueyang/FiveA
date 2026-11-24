#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

// 改成 1 后可用 Console.app 过滤 [FiveA] 观察命中情况
#define DEBUG_LOG 0

static NSString *const kFrom = @"5G+";
static NSString *const kTo   = @"5Gᴀ";

static void dbg(NSString *fmt, ...) {
#if DEBUG_LOG
    va_list ap;
    va_start(ap, fmt);
    NSString *line = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSLog(@"[FiveA] %@", line);
#else
    (void)fmt;
#endif
}

static NSString *remap(NSString *s) {
    if (![s isKindOfClass:[NSString class]]) return s;
    if ([s isEqualToString:kFrom]) {
        dbg(@"hit 5G+ -> 5Gᴀ");
        return kTo;
    }
    return s;
}

// ---------------------------------------------------------------
// 路径 1：旧状态栏条目（Data Logo Switcher 走的同一条，
//         已在 iOS 12–16 上验证，17 上是否仍被调用需实测）
// ---------------------------------------------------------------
%group GStatusItem
%hook _UIStatusBarCellularItem
- (NSString *)_stringForCellularType:(int)type {
    NSString *s = %orig;
    dbg(@"path1 type=%d str=%@", type, s);
    return remap(s);
}
%end
%end

// ---------------------------------------------------------------
// 路径 2：iOS 13+ 的 STStatusBarData 对象模型
//         5G+ 文案一般挂在 string / crossfadeString 上
// ---------------------------------------------------------------
%group GDataEntry
%hook STStatusBarDataCellularEntry
- (NSString *)string {
    return remap(%orig);
}
- (NSString *)crossfadeString {
    return remap(%orig);
}
%end
%end

// ---------------------------------------------------------------
// 路径 3：兜底，直接拦 SystemStatusUI / UIKit 的本地化查表。
//         不依赖私有类名，前两条都不命中时靠它。
// ---------------------------------------------------------------
%group GLocalize
%hook NSBundle
- (NSString *)localizedStringForKey:(NSString *)key
                              value:(NSString *)value
                              table:(NSString *)tableName {
    NSString *r = %orig;
    if (![r isEqualToString:kFrom]) return r;
    NSString *bid = [self bundleIdentifier];
    if ([bid hasPrefix:@"com.apple.SystemStatus"] ||
        [bid hasPrefix:@"com.apple.UIKit"] ||
        [bid isEqualToString:@"com.apple.SpringBoard"]) {
        dbg(@"path3 bundle=%@ key=%@", bid, key);
        return kTo;
    }
    return r;
}
%end
%end

%ctor {
    if (objc_getClass("_UIStatusBarCellularItem")) {
        dbg(@"init GStatusItem");
        %init(GStatusItem);
    }
    if (objc_getClass("STStatusBarDataCellularEntry")) {
        dbg(@"init GDataEntry");
        %init(GDataEntry);
    }
    %init(GLocalize);
}
