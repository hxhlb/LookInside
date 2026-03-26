#if defined(SHOULD_COMPILE_LOOKIN_SERVER) && (TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_VISION || TARGET_OS_MAC)
//
//  NSObject+LookinServer.m
//  LookinServer
//
//  Created by Li Kai on 2019/4/21.
//  https://lookin.work
//

#import "NSObject+Lookin.h"
#import "NSObject+LookinServer.h"
#import "NSArray+Lookin.h"
#import "LookinServerDefines.h"
#import "LKS_ObjectRegistry.h"
#if TARGET_OS_MAC
#import "LookinObject.h"
#import "LookinAutoLayoutConstraint.h"
#import "LKS_MultiplatformAdapter.h"

@interface LookinAutoLayoutConstraint (LookinServerFactory)
+ (instancetype)instanceFromNSConstraint:(NSLayoutConstraint *)constraint isEffective:(BOOL)isEffective firstItemType:(LookinConstraintItemType)firstItemType secondItemType:(LookinConstraintItemType)secondItemType;
@end
#endif
#import <objc/runtime.h>

@implementation NSObject (LookinServer)

#pragma mark - oid

- (unsigned long)lks_registerOid {
    if (!self.lks_oid) {
        unsigned long oid = [[LKS_ObjectRegistry sharedInstance] addObject:self];
        self.lks_oid = oid;
    }
    return self.lks_oid;
}

- (void)setLks_oid:(unsigned long)lks_oid {
    [self lookin_bindObject:@(lks_oid) forKey:@"lks_oid"];
}

- (unsigned long)lks_oid {
    NSNumber *number = [self lookin_getBindObjectForKey:@"lks_oid"];
    return [number unsignedLongValue];
}

+ (NSObject *)lks_objectWithOid:(unsigned long)oid {
    return [[LKS_ObjectRegistry sharedInstance] objectWithOid:oid];
}

#pragma mark - trace

- (void)setLks_ivarTraces:(NSArray<LookinIvarTrace *> *)lks_ivarTraces {
    [self lookin_bindObject:lks_ivarTraces.copy forKey:@"lks_ivarTraces"];
    
    if (lks_ivarTraces) {
        [[NSObject lks_allObjectsWithTraces] addPointer:(void *)self];
    }
}

- (NSArray<LookinIvarTrace *> *)lks_ivarTraces {
    return [self lookin_getBindObjectForKey:@"lks_ivarTraces"];
}

- (void)setLks_specialTrace:(NSString *)lks_specialTrace {
    [self lookin_bindObject:lks_specialTrace forKey:@"lks_specialTrace"];
    if (lks_specialTrace) {
        [[NSObject lks_allObjectsWithTraces] addPointer:(void *)self];
    }
}
- (NSString *)lks_specialTrace {
    return [self lookin_getBindObjectForKey:@"lks_specialTrace"];
}

+ (void)lks_clearAllObjectsTraces {
    [[[NSObject lks_allObjectsWithTraces] allObjects] enumerateObjectsUsingBlock:^(NSObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.lks_ivarTraces = nil;
        obj.lks_specialTrace = nil;
    }];
    [NSObject lks_allObjectsWithTraces].count = 0;
}

+ (NSPointerArray *)lks_allObjectsWithTraces {
    static dispatch_once_t onceToken;
    static NSPointerArray *lks_allObjectsWithTraces = nil;
    dispatch_once(&onceToken,^{
        lks_allObjectsWithTraces = [NSPointerArray weakObjectsPointerArray];
    });
    return lks_allObjectsWithTraces;
}

- (NSArray<NSString *> *)lks_classChainList {
    NSMutableArray<NSString *> *classChainList = [NSMutableArray array];
    Class currentClass = self.class;
    
    while (currentClass) {
        NSString *currentClassName = NSStringFromClass(currentClass);
        if (currentClassName) {
            [classChainList addObject:currentClassName];
        }
        currentClass = [currentClass superclass];
    }
    return classChainList.copy;
}

@end

#if TARGET_OS_MAC

@implementation NSView (LookinServer)

- (void)setLks_verticalContentHuggingPriority:(float)value {
    [self setContentHuggingPriority:value forOrientation:NSLayoutConstraintOrientationVertical];
}

- (float)lks_verticalContentHuggingPriority {
    return [self contentHuggingPriorityForOrientation:NSLayoutConstraintOrientationVertical];
}

- (void)setLks_horizontalContentHuggingPriority:(float)value {
    [self setContentHuggingPriority:value forOrientation:NSLayoutConstraintOrientationHorizontal];
}

- (float)lks_horizontalContentHuggingPriority {
    return [self contentHuggingPriorityForOrientation:NSLayoutConstraintOrientationHorizontal];
}

- (void)setLks_verticalContentCompressionResistancePriority:(float)value {
    [self setContentCompressionResistancePriority:value forOrientation:NSLayoutConstraintOrientationVertical];
}

- (float)lks_verticalContentCompressionResistancePriority {
    return [self contentCompressionResistancePriorityForOrientation:NSLayoutConstraintOrientationVertical];
}

- (void)setLks_horizontalContentCompressionResistancePriority:(float)value {
    [self setContentCompressionResistancePriority:value forOrientation:NSLayoutConstraintOrientationHorizontal];
}

- (float)lks_horizontalContentCompressionResistancePriority {
    return [self contentCompressionResistancePriorityForOrientation:NSLayoutConstraintOrientationHorizontal];
}

+ (void)lks_rebuildGlobalInvolvedRawConstraints {
    [[LKS_MultiplatformAdapter allWindows] enumerateObjectsUsingBlock:^(NSWindow *window, NSUInteger idx, BOOL *stop) {
        [self lks_removeInvolvedRawConstraintsForViewsRootedByView:window.contentView];
    }];
    [[LKS_MultiplatformAdapter allWindows] enumerateObjectsUsingBlock:^(NSWindow *window, NSUInteger idx, BOOL *stop) {
        [self lks_addInvolvedRawConstraintsForViewsRootedByView:window.contentView];
    }];
}

+ (void)lks_addInvolvedRawConstraintsForViewsRootedByView:(NSView *)rootView {
    [rootView.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *constraint, NSUInteger idx, BOOL *stop) {
        NSView *firstView = [constraint.firstItem isKindOfClass:[NSView class]] ? constraint.firstItem : nil;
        if (firstView && ![firstView.lks_involvedRawConstraints containsObject:constraint]) {
            if (!firstView.lks_involvedRawConstraints) {
                firstView.lks_involvedRawConstraints = [NSMutableArray array];
            }
            [firstView.lks_involvedRawConstraints addObject:constraint];
        }

        NSView *secondView = [constraint.secondItem isKindOfClass:[NSView class]] ? constraint.secondItem : nil;
        if (secondView && ![secondView.lks_involvedRawConstraints containsObject:constraint]) {
            if (!secondView.lks_involvedRawConstraints) {
                secondView.lks_involvedRawConstraints = [NSMutableArray array];
            }
            [secondView.lks_involvedRawConstraints addObject:constraint];
        }
    }];

    [rootView.subviews enumerateObjectsUsingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop) {
        [self lks_addInvolvedRawConstraintsForViewsRootedByView:subview];
    }];
}

+ (void)lks_removeInvolvedRawConstraintsForViewsRootedByView:(NSView *)rootView {
    [rootView.lks_involvedRawConstraints removeAllObjects];
    [rootView.subviews enumerateObjectsUsingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop) {
        [self lks_removeInvolvedRawConstraintsForViewsRootedByView:subview];
    }];
}

- (void)setLks_involvedRawConstraints:(NSMutableArray<NSLayoutConstraint *> *)constraints {
    [self lookin_bindObject:constraints forKey:@"lks_involvedRawConstraints"];
}

- (NSMutableArray<NSLayoutConstraint *> *)lks_involvedRawConstraints {
    return [self lookin_getBindObjectForKey:@"lks_involvedRawConstraints"];
}

- (NSArray<LookinAutoLayoutConstraint *> *)lks_constraints {
    NSMutableArray<NSLayoutConstraint *> *effectiveConstraints = [NSMutableArray array];
    [effectiveConstraints addObjectsFromArray:[self constraintsAffectingLayoutForOrientation:NSLayoutConstraintOrientationHorizontal]];
    [effectiveConstraints addObjectsFromArray:[self constraintsAffectingLayoutForOrientation:NSLayoutConstraintOrientationVertical]];

    NSArray<LookinAutoLayoutConstraint *> *constraints = [self.lks_involvedRawConstraints lookin_map:^id(NSUInteger idx, NSLayoutConstraint *constraint) {
        BOOL isEffective = [effectiveConstraints containsObject:constraint];
        if (!constraint.active) {
            return nil;
        }
        LookinConstraintItemType firstItemType = [self _lks_constraintItemTypeForItem:constraint.firstItem];
        LookinConstraintItemType secondItemType = [self _lks_constraintItemTypeForItem:constraint.secondItem];
        return [LookinAutoLayoutConstraint instanceFromNSConstraint:constraint
                                                        isEffective:isEffective
                                                      firstItemType:firstItemType
                                                     secondItemType:secondItemType];
    }];
    return constraints.count ? constraints : nil;
}

- (LookinConstraintItemType)_lks_constraintItemTypeForItem:(id)item {
    if (!item) {
        return LookinConstraintItemTypeNil;
    }
    if (item == self) {
        return LookinConstraintItemTypeSelf;
    }
    if (item == self.superview) {
        return LookinConstraintItemTypeSuper;
    }
    if ([item isKindOfClass:[NSLayoutGuide class]]) {
        return LookinConstraintItemTypeLayoutGuide;
    }
    if ([item isKindOfClass:[NSView class]]) {
        return LookinConstraintItemTypeView;
    }
    return LookinConstraintItemTypeUnknown;
}

@end

@implementation NSImageView (LookinServer)

- (NSString *)lks_imageSourceName {
    return self.image.name;
}

- (NSNumber *)lks_imageViewOidIfHasImage {
    if (!self.image) {
        return nil;
    }
    return @([self lks_registerOid]);
}

@end

@implementation NSTextField (LookinServer)

- (CGFloat)lks_fontSize {
    return self.font.pointSize;
}

- (void)setLks_fontSize:(CGFloat)value {
    self.font = [self.font fontWithSize:value];
}

- (NSString *)lks_fontName {
    return self.font.fontName;
}

@end

@implementation NSTextView (LookinServer)

- (CGFloat)lks_fontSize {
    return self.font.pointSize;
}

- (void)setLks_fontSize:(CGFloat)value {
    self.font = [self.font fontWithSize:value];
}

- (NSString *)lks_fontName {
    return self.font.fontName;
}

@end

#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
