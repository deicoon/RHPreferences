//
//  RHNewViewController.m
//  RHPreferences
//
//  Created by Joseph Daniels on 10/8/15.
//  Copyright © 2015 Richard Heard. All rights reserved.
//

#import "RHNewViewController.h"

@implementation RHNewViewController
- (IBAction)changeSize:(id)sender {
//        self.view.needsLayout = YES;
    self.heightConstraint.constant =  (self.heightConstraint.constant == 200 ? 100 : 200);

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext* context) {
//        context.duration = 2;
        context.allowsImplicitAnimation = YES;
        [self.view updateConstraintsForSubtreeIfNeeded];
//        [self.view layoutSubtreeIfNeeded];
        
    } completionHandler:nil] ;
}
-(void)viewDidLayout{
    NSLog(@"ohhhh");
}
-(NSString*)identifier{
    return NSStringFromClass(self.class);
}
-(NSImage*)toolbarItemImage{
    return [NSImage imageNamed:@"WidePreferences"];
}
-(NSString*)toolbarItemLabel{
    return NSLocalizedString(@"New", @"WideToolbarItemLabel");
}

@end
