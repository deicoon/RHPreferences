//
//  NSView_NSView_TargetedKeyPaths.h
//  LuxIA
//
//  Created by Perceval FARAMAZ on 24/10/2017.
//  Copyright © 2017 deicoon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (InspectableTargetedKeyPath)
@property IBInspectable NSString* targetedKeyPath;
-(__kindof NSView*)viewForKeyPath:(NSString*)keypath;
@end
