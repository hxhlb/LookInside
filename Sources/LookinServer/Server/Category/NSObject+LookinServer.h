#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  NSObject+LookinServer.h
//  LookinServer
//
//  Created by Li Kai on 2019/4/21.
//  https://lookin.work
//

#import "LookinDefines.h"
#import <Foundation/Foundation.h>
#if TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

@class LookinIvarTrace;

@interface NSObject (LookinServer)

#pragma mark - oid

/// 如果 oid 不存在则会创建新的 oid
- (unsigned long)lks_registerOid;

/// 0 表示不存在
@property(nonatomic, assign) unsigned long lks_oid;

+ (NSObject *)lks_objectWithOid:(unsigned long)oid;

#pragma mark - trace

@property(nonatomic, copy) NSArray<LookinIvarTrace *> *lks_ivarTraces;

@property(nonatomic, copy) NSString *lks_specialTrace;

+ (void)lks_clearAllObjectsTraces;

/**
 获取当前对象的 Class 层级树，如 @[@"UIView", @"UIResponder", @"NSObject"]。未 demangle，有 Swift Module Name
 */
- (NSArray<NSString *> *)lks_classChainList;

@end

#if TARGET_OS_MAC

@interface NSView (LookinServer)

@property(nonatomic, assign) float lks_horizontalContentHuggingPriority;
@property(nonatomic, assign) float lks_verticalContentHuggingPriority;
@property(nonatomic, assign) float lks_horizontalContentCompressionResistancePriority;
@property(nonatomic, assign) float lks_verticalContentCompressionResistancePriority;
@property(nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *lks_involvedRawConstraints;

+ (void)lks_rebuildGlobalInvolvedRawConstraints;
- (NSArray *)lks_constraints;

@end

@interface NSImageView (LookinServer)

- (NSString *)lks_imageSourceName;
- (NSNumber *)lks_imageViewOidIfHasImage;

@end

@interface NSTextField (LookinServer)

@property(nonatomic, assign) CGFloat lks_fontSize;
- (NSString *)lks_fontName;

@end

@interface NSTextView (LookinServer)

@property(nonatomic, assign) CGFloat lks_fontSize;
- (NSString *)lks_fontName;

@end

#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
