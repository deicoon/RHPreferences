//
//  RHAboutViewController.h
//  RHPreferencesTester
//
//  Created by Richard Heard on 17/04/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface RHAboutViewController : NSViewController  <RHPreferencesViewControllerProtocol> {
    __weak NSTextField* _emailTextField;
}

@property (weak) IBOutlet NSTextField *emailTextField;

@end
