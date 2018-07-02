//
//  NSView+TargetedKeyPath.m
//  LuxIA
//
//  Created by Perceval FARAMAZ on 24/10/2017.
//  Copyright © 2017 deicoon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSView+TargetedKeyPath.h"
#import <objc/runtime.h>

void *TargetedKeyPath = &TargetedKeyPath;

@implementation NSView (InspectableTargetedKeyPath)
@dynamic targetedKeyPath;
-(void)setTargetedKeyPath:(NSString *)targetedKeyPath {
    objc_setAssociatedObject(self, @selector(targetedKeyPath), targetedKeyPath, OBJC_ASSOCIATION_COPY);
}

-(NSString*)targetedKeyPath {
    NSString *key = objc_getAssociatedObject(self, @selector(targetedKeyPath));
    return key;
}

-(__kindof NSView*)viewForKeyPath:(NSString*)keypath {
    NSView* targetView = nil;
    for (NSView* aView in self.subviews) {
        NSString* kp = aView.targetedKeyPath;
        if ([keypath isEqualToString:kp]) {
            targetView = aView;
            break;
        } else {
            targetView = [aView viewForKeyPath:keypath];
            if (targetView)
                break;
        }
    }
    return targetView;
}

@end
