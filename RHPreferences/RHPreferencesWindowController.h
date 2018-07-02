//
//  RHPreferencesWindowController.h
//  RHPreferences
//
//  Created by Richard Heard on 10/04/12.
//  Copyright (c) 2012 Richard Heard. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <Cocoa/Cocoa.h>

@protocol RHPreferencesViewControllerProtocol;

@interface RHPreferencesWindowController : NSWindowController <NSToolbarDelegate>{
    NSArray <NSToolbarItem*>*_toolbarItems;
}

//init
-(nonnull instancetype)initWithViewControllers:(NSArray*__nonnull)controllers;
-(nonnull instancetype)initWithViewControllers:(NSArray*__nonnull)controllers andTitle:(NSString*__nullable)title;

//properties
@property (copy, nonnull) NSString * windowTitle;
@property (copy, nullable) NSString *defaultWindowTitle;
@property (assign) BOOL windowTitleShouldAutomaticlyUpdateToReflectSelectedViewController; //defaults to YES

@property (nonnull) IBOutlet NSToolbar *toolbar;
@property (nonatomic, nonnull) IBOutlet NSArray *viewControllers; //controllers should implement RHPreferencesViewControllerProtocol

@property (assign) NSUInteger selectedIndex;
@property (weak, nonatomic, nullable) NSViewController <RHPreferencesViewControllerProtocol> *selectedViewController;

-(NSViewController <RHPreferencesViewControllerProtocol>*__nullable)viewControllerWithIdentifier:(NSString*__nonnull)identifier;

-(void)presentError:(NSError*__nonnull)err forKeyPath:(NSString*__nonnull)key;

//you can include these placeholder controllers amongst your array of view controllers to show their respective items in the toolbar
+(id __nonnull)separatorPlaceholderController;        // NSToolbarSeparatorItemIdentifier
+(id __nonnull)flexibleSpacePlaceholderController;    // NSToolbarFlexibleSpaceItemIdentifier
+(id __nonnull)spacePlaceholderController;            // NSToolbarSpaceItemIdentifier

+(id __nonnull)showColorsPlaceholderController;       // NSToolbarShowColorsItemIdentifier
+(id __nonnull)showFontsPlaceholderController;        // NSToolbarShowFontsItemIdentifier
+(id __nonnull)customizeToolbarPlaceholderController; // NSToolbarCustomizeToolbarItemIdentifier
+(id __nonnull)printPlaceholderController;            // NSToolbarPrintItemIdentifier

@end



// Implement this protocol on your view controller so that RHPreferencesWindow knows what to show in the tabbar. Label, image etc.
@protocol RHPreferencesViewControllerProtocol <NSObject>
@required

@property (nonatomic, readonly, retain, nonnull) NSString *identifier;
@property (nonatomic, readonly, retain, nullable) NSImage *toolbarItemImage;
@property (nonatomic, readonly, retain, nonnull) NSString *toolbarItemLabel;

@optional

@property (nonatomic, readonly, retain, nonnull) NSToolbarItem *toolbarItem; //optional, overrides the above 3 properties. allows for custom tabbar items.
@property (nonatomic, readonly, assign) BOOL isHiddenByDefault; //if an item is hidden by default; "alt" being pressed when showing RHPreferencesWindow will make it appear
//@property (nonatomic, readonly, assign) NSArray* preferencesKeyPaths; //key paths that may be impacted by changes in the view controller
//-(void)presentError:(NSError*)error forKeyPath:(NSString*)keypath;

-(__kindof NSView*__nullable)viewForKeyPath:(NSString*__nullable)keypath; //return the first view that may be impacted by a change of the passed key path

//methods called when switching between tabs
-(void)viewWillAppear;
-(void)viewDidAppear;
-(void)viewWillDisappear;
-(void)viewDidDisappear;

-(void)viewWindowDidBecomeKey;

@property (NS_NONATOMIC_IOSONLY, readonly, strong, nullable) NSView *initialKeyView;   // keyboard focus view on tab switch...

@end
