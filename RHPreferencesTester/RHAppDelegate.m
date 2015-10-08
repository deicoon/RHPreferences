//
//  RHAppDelegate.m
//  RHPreferencesTester
//
//  Created by Richard Heard on 23/05/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//

#import "RHAppDelegate.h"
#import "RHAboutViewController.h"
#import "RHAccountsViewController.h"
#import "RHWideViewController.h"

@implementation RHAppDelegate

@synthesize window = _window;
@synthesize preferencesWindowController=_preferencesWindowController;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}




#pragma mark - IBActions
-(IBAction)showPreferences:(id)sender{
    //if we have not created the window controller yet, create it now
    if (!_preferencesWindowController){
        RHAccountsViewController *accounts = [[RHAccountsViewController alloc] init];
        RHAboutViewController *about = [[RHAboutViewController alloc] init];
        RHWideViewController *wide = [[RHWideViewController alloc] init];
        
        NSArray *controllers = [NSArray arrayWithObjects:accounts, wide, 
                                [RHPreferencesWindowController flexibleSpacePlaceholderController], 
                                about,
                                nil];
        
        _preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Preferences", @"Preferences Window Title")];
    }
    
    [_preferencesWindowController showWindow:self];
    
}



@end
