//
//  RHAppDelegate.h
//  RHPreferencesTester
//
//  Created by Richard Heard on 23/05/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface RHAppDelegate : NSObject <NSApplicationDelegate> {
    
    __weak NSWindow * _window;
    RHPreferencesWindowController *_preferencesWindowController;
}

@property (weak) IBOutlet NSWindow *window;
@property (strong) RHPreferencesWindowController *preferencesWindowController;


#pragma mark - IBActions
-(IBAction)showPreferences:(id)sender;



@end
