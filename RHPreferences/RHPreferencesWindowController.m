//
//  RHPreferencesWindowController.m
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


#import "RHPreferencesWindowController.h"
@import QuartzCore.CoreAnimation;
#import "NSAlert+Popover.h"
#import "NSView+TargetedKeyPath.h"

static NSString * const RHPreferencesWindowControllerSelectedItemIdentifier = @"RHPreferencesWindowControllerSelectedItemIdentifier";
static const CGFloat RHPreferencesWindowControllerResizeAnimationDurationPer100Pixels = 0.1f;

#pragma mark - Custom Item Placeholder Controller
@interface RHPreferencesCustomPlaceholderController : NSObject <RHPreferencesViewControllerProtocol> {
    NSString *_identifier;
}
+(id)controllerWithIdentifier:(NSString*)identifier;
@property (readwrite, nonatomic, strong) NSString *identifier;
@end

@implementation RHPreferencesCustomPlaceholderController
@synthesize identifier=_identifier;
+(id)controllerWithIdentifier:(NSString*)identifier{
    RHPreferencesCustomPlaceholderController * placeholder = [[RHPreferencesCustomPlaceholderController alloc] init];
    placeholder.identifier = identifier;
    return placeholder;
}
-(NSToolbarItem*)toolbarItem{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:_identifier];
    return item;
}
-(NSString*)identifier{
    return _identifier;
}
-(NSImage*)toolbarItemImage{
    return nil;
}
-(NSString*)toolbarItemLabel{
    return nil;
}
@end


@interface RHPreferencesFlippedContentView : NSView
@end
@implementation RHPreferencesFlippedContentView
- (BOOL)isFlipped { return YES; }
@end

#pragma mark - RHPreferencesWindowController

@interface RHPreferencesWindowController ()

//items
-(NSToolbarItem*)toolbarItemWithItemIdentifier:(NSString*)identifier;
-(NSToolbarItem*)newToolbarItemForViewController:(NSViewController<RHPreferencesViewControllerProtocol>*)controller;
-(void)reloadToolbarItems;
-(IBAction)selectToolbarItem:(NSToolbarItem*)itemToBeSelected;
-(NSArray*)toolbarItemIdentifiers;

//NSWindowController methods
-(void)resizeWindowForContentSize:(NSSize)size duration:(CGFloat)duration;

- (NSTimeInterval)durationForTransitionFromOldSize:(NSSize)oldSize toNewSize:(NSSize)newSize;

@end

@implementation RHPreferencesWindowController

#pragma mark - setup
-(instancetype)initWithViewControllers:(NSArray*)controllers {
    return [self initWithViewControllers:controllers andTitle:nil];
}

-(instancetype)initWithViewControllers:(NSArray*)controllers andTitle:(NSString*)title{
    self = [super initWithWindowNibName:@"RHPreferencesWindow"];
    if (self){
        
        //default settings
        _windowTitleShouldAutomaticlyUpdateToReflectSelectedViewController = YES;

        //store the controllers
        self.viewControllers = controllers;
        self.defaultWindowTitle = [title copy];
        
        NSView *contentView = self.window.contentView;
        [contentView setWantsLayer:YES];

        CATransition* transition = [CATransition animation];
        transition.type = kCATransitionFade;
        transition.speed = .9;
        
        NSDictionary *ani = @{@"subviews": transition};
        contentView.animations = ani;
        
    }
    [self.window setReleasedWhenClosed:NO];
    return self;
}

- (void)dealloc
{
    [self.selectedViewController removeObserver:self forKeyPath:@"view.frame"];
}

#pragma mark - properties

-(NSString*)windowTitle{
    return self.windowLoaded ? self.window.title : self.defaultWindowTitle;
}
-(void)setWindowTitle:(NSString *)windowTitle{
    if (self.windowLoaded){
        self.window.title = windowTitle;
    } else {
        self.defaultWindowTitle = [windowTitle copy];
    }
}

-(void)setViewControllers:(NSArray *)viewControllers{
    if (_viewControllers != viewControllers){
        NSUInteger oldSelectedIndex = self.selectedIndex;
        
        _viewControllers = viewControllers;
        
        //update the selected controller if we had one previously.
        if (self.selectedViewController){
            if ([_viewControllers containsObject:_selectedViewController]){
                //cool, nothing to do
            } else {
                self.selectedIndex = oldSelectedIndex; //reset the currently selected view controller
            }
        } else {
            //initial launch state (need to select previously selected tab)
            
            //set the selected controller
            NSViewController *selectedController = [self viewControllerWithIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:RHPreferencesWindowControllerSelectedItemIdentifier]];
            if (selectedController){
                self.selectedViewController = (id)selectedController;
            } else {
                for (NSUInteger idx = 0; idx < _viewControllers.count; idx++){
                    NSViewController <RHPreferencesViewControllerProtocol>* vc = _viewControllers[idx];
                    
                    if ([vc class] == [RHPreferencesCustomPlaceholderController class])
                        continue;
                    else {
                        self.selectedIndex = idx;
                        break;
                    }
                }
            }

        }

        [self reloadToolbarItems];
    }
}

-(void)setSelectedViewController:(NSViewController<RHPreferencesViewControllerProtocol> *)new{
    //alias
    NSViewController *old = _selectedViewController;

    //stash
    _selectedViewController = new; //weak because we retain it in our array

    [old removeObserver:self
             forKeyPath:@"view.frame"];
    
    [new addObserver:self
          forKeyPath:@"view.frame"
             options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
             context:NULL];
    
    //stash to defaults also
    BOOL shouldRememberSelected = true;
    if ([new respondsToSelector:@selector(isHiddenByDefault)])
        if (new.isHiddenByDefault)
            shouldRememberSelected = false; //don't re-open an element that may be hidden
    
    if (shouldRememberSelected)
        [[NSUserDefaults standardUserDefaults] setObject:[self toolbarItemIdentifierForViewController:new] forKey:RHPreferencesWindowControllerSelectedItemIdentifier];
    
    //bail if not yet loaded
    if (!self.windowLoaded){
        return;
    }    
    
    if (old != new){
        [new.view setFrameOrigin:NSMakePoint(0, 0)]; // force our view to a 0,0 origin, fixed in the lower right corner.
        (new.view).autoresizingMask = NSViewMaxXMargin|NSViewMaxYMargin|NSViewMinXMargin|NSViewMinYMargin;
        
        NSTimeInterval duration = [self durationForTransitionFromOldSize:old.view.bounds.size
                                                               toNewSize:new.view.bounds.size];
        
        [NSAnimationContext beginGrouping];
        [NSAnimationContext currentContext].duration = duration;
        
        //notify the old vc that its going away
        if ([old respondsToSelector:@selector(viewWillDisappear)]){
            [(id)old viewWillDisappear];
        }
        
        if (nil != old) {
            [[self.window.contentView animator] replaceSubview:old.view
                                                          with:new.view];
        } else {
            [[self.window.contentView animator] addSubview:new.view];
        }
        
        if ([old respondsToSelector:@selector(viewDidDisappear)]){
            [(id)old viewDidDisappear];
        }
        
        //notify the new vc of its appearance
        if ([new respondsToSelector:@selector(viewWillAppear)]){
            [(id)new viewWillAppear];
        }   
        
        [self resizeWindowForContentSize:new.view.bounds.size duration:duration];

        double delayInSeconds = duration + 0.02; // +.02 to give time for resize to finish before appearing
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

            //make sure our "new" vc is still the selected vc before we add it as a subview, otherwise it's possible we could add more than one vc to the window. (the user has likely clicked to another tab during resizing.)
            if (self.selectedViewController == new){
                //[self.window.contentView addSubview:new.view];
                
                if ([new respondsToSelector:@selector(viewDidAppear)]){
                    [(id)new viewDidAppear];
                }

                //if there is a initialKeyView set it as key
                if ([new respondsToSelector:@selector(initialKeyView)]){
                    [[new initialKeyView] becomeFirstResponder];
                }
            }
        });
        
        [NSAnimationContext endGrouping];
        
        //set the currently selected toolbar item
        _toolbar.selectedItemIdentifier = [self toolbarItemIdentifierForViewController:new];
                
        //if we should auto-update window title, do it now 
        if (_windowTitleShouldAutomaticlyUpdateToReflectSelectedViewController){
            NSString *identifier = [self toolbarItemIdentifierForViewController:new];
            NSString *title = [self toolbarItemWithItemIdentifier:identifier].label;
            if (title)self.windowTitle = title;
        }
    }
}

-(NSUInteger)selectedIndex{
    return [_viewControllers indexOfObject:self.selectedViewController];
}

-(void)setSelectedIndex:(NSUInteger)selectedIndex{
    id newSelection = (selectedIndex >= _viewControllers.count) ? _viewControllers.lastObject : _viewControllers[selectedIndex];
    self.selectedViewController = newSelection;
}

-(NSViewController <RHPreferencesViewControllerProtocol>*)viewControllerWithIdentifier:(NSString*)identifier{
    for (NSViewController <RHPreferencesViewControllerProtocol>* vc in _viewControllers){

        //set the toolbar back to the current controllers selection
        if ([vc respondsToSelector:@selector(toolbarItem)] && [vc.toolbarItem.itemIdentifier isEqualToString:identifier]){
            return vc;
        } 
        
        if ([vc.identifier isEqualToString:identifier]){
            return vc;
        }
    }    
    return nil;
}

- (NSTimeInterval)durationForTransitionFromOldSize:(NSSize)oldSize toNewSize:(NSSize)newSize
{
    //resize to Preferred window size for given view (duration is determined by difference between current and new sizes)
    float hDifference = fabs(newSize.height - oldSize.height);
    float wDifference = fabs(newSize.width - oldSize.width);
    float difference = MAX(hDifference, wDifference);
    float duration = MAX(RHPreferencesWindowControllerResizeAnimationDurationPer100Pixels * ( difference / 100), 0.10); // we always want a slight animation
    
    return (NSTimeInterval)duration;
}

#pragma mark - Error presentation

-(void)presentError:(NSError*)error forView:(__kindof NSView*)targetView {
    NSAlert* alert = [NSAlert alertWithError:error];
    //alert.alertStyle = NSCriticalAlertStyle;//NSWarningAlertStyle
    
    [alert runAsPopoverForView:targetView preferredEdge:NSMaxXEdge withCompletionBlock:^(NSInteger result) {
        if (result == NSAlertFirstButtonReturn) {
            NSLog(@"Recovery option 1");
        } else if (result == NSAlertSecondButtonReturn) {
            NSLog(@"Recovery option 2");
        } else if (result == NSAlertThirdButtonReturn) {
            NSLog(@"Recovery option 3");
        }
    }];
}

-(void)presentError:(NSError*)err forKeyPath:(NSString*)key {
    for (NSViewController<RHPreferencesViewControllerProtocol>* vc in _viewControllers) {
        if (![vc respondsToSelector:@selector(view)])
            continue;
        if (![vc.view respondsToSelector:@selector(viewForKeyPath:)])
            continue;
        
        NSView* view = [vc.view viewForKeyPath:key];
        
        if (view) {
            self.selectedViewController = vc;
            [self presentError:err forView:view];
            break;
        }
    }
}

#pragma mark - KVO Observer

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (object == self->_selectedViewController) {
        if ([keyPath isEqualToString:@"view.frame"]) {
            NSRect oldFrame = [change[NSKeyValueChangeOldKey] rectValue];
            NSRect newFrame = [change[NSKeyValueChangeNewKey] rectValue];
            
            if (!NSEqualSizes(oldFrame.size, newFrame.size)) {
                NSTimeInterval duration = [self durationForTransitionFromOldSize:oldFrame.size
                                                                       toNewSize:newFrame.size];
                
                [self resizeWindowForContentSize:newFrame.size
                                        duration:duration];
            }
        }
    }
}

#pragma mark - View Controller Methods

-(void)resizeWindowForContentSize:(NSSize)size duration:(CGFloat)duration{
    NSWindow *window = self.window;
    
    NSRect frame = [window contentRectForFrameRect:window.frame];
    
    CGFloat newX = NSMinX(frame) + (0.5* (NSWidth(frame) - size.width));
    NSRect newFrame = [window frameRectForContentRect:NSMakeRect(newX, NSMaxY(frame) - size.height, size.width, size.height)];
    
    if (duration > 0.0f){
        //[[NSAnimationContext currentContext] setDuration:duration];
            [[window animator] setFrame:newFrame display:YES];
    } else {
        [window setFrame:newFrame display:YES];
    }

}


#pragma mark - Toolbar Items

-(NSToolbarItem*)toolbarItemWithItemIdentifier:(NSString*)identifier{
    for (NSToolbarItem *item in _toolbarItems){
        if ([item.itemIdentifier isEqualToString:identifier]){
            return item;
        }
    }    
    return nil;
}

-(NSString*)toolbarItemIdentifierForViewController:(NSViewController*)controller{
    if ([controller respondsToSelector:@selector(toolbarItem)]){
        NSToolbarItem *item = [(id)controller toolbarItem];
        if (item){
            return item.itemIdentifier;
        }
    }
    
    if ([controller respondsToSelector:@selector(identifier)]){
        return [(id)controller identifier];
    }
    
    return nil;
}


-(NSToolbarItem*)newToolbarItemForViewController:(NSViewController<RHPreferencesViewControllerProtocol>*)controller{
    //if the controller wants to provide a toolbar item, return that
    if ([controller respondsToSelector:@selector(toolbarItem)]){
        NSToolbarItem *item = controller.toolbarItem;
        if (item){
            item = [item copy]; //we copy the item because it needs to be unique for a specific toolbar
            item.target = self;
            item.action = @selector(selectToolbarItem:);
            return item;
        }
    }

    //otherwise, default to creation of a new item.
    
    NSToolbarItem *new = [[NSToolbarItem alloc] initWithItemIdentifier:controller.identifier];
    new.image = controller.toolbarItemImage;
    new.label = controller.toolbarItemLabel;
    new.target = self;
    new.action = @selector(selectToolbarItem:);
    return new;
}

-(void)reloadToolbarItems{
    NSMutableArray <NSToolbarItem*>*newItems = [NSMutableArray arrayWithCapacity:_viewControllers.count];
    
    for (NSViewController<RHPreferencesViewControllerProtocol>* vc in _viewControllers){

        NSToolbarItem *insertItem = [self toolbarItemWithItemIdentifier:vc.identifier];
        if (!insertItem){
            //create a new one
            insertItem = [self newToolbarItemForViewController:vc];
        }
        [newItems addObject:insertItem];
    }
    
    _toolbarItems = [NSArray arrayWithArray:newItems];
}


-(IBAction)selectToolbarItem:(NSToolbarItem*)itemToBeSelected{
    NSViewController <RHPreferencesViewControllerProtocol> *selectedViewController = self.selectedViewController;
    if ([selectedViewController commitEditing] && [[NSUserDefaultsController sharedUserDefaultsController] commitEditing]){
        NSUInteger index = [_toolbarItems indexOfObject:itemToBeSelected];
        if (index != NSNotFound){
            self.selectedViewController = _viewControllers[index];
        }
    } else {
        //set the toolbar back to the current controllers selection
        if ([selectedViewController respondsToSelector:@selector(toolbarItem)] && selectedViewController.toolbarItem.itemIdentifier){
            _toolbar.selectedItemIdentifier = selectedViewController.toolbarItem.itemIdentifier;
        } else if ([selectedViewController respondsToSelector:@selector(identifier)]){
            _toolbar.selectedItemIdentifier = selectedViewController.identifier;
        }

    }
}

-(NSArray*)toolbarItemIdentifiers {
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:self.viewControllers.count];
    
    for (id viewController in _viewControllers){
        [identifiers addObject:[self toolbarItemIdentifierForViewController:viewController]];
    }
    
    return [NSArray arrayWithArray:identifiers];
}

#pragma mark - Custom Placeholder Controller Toolbar Items

+(id)separatorPlaceholderController{
    return [RHPreferencesCustomPlaceholderController controllerWithIdentifier:NSToolbarSeparatorItemIdentifier];
}
+(id)flexibleSpacePlaceholderController{ 
    return [RHPreferencesCustomPlaceholderController controllerWithIdentifier:NSToolbarFlexibleSpaceItemIdentifier];
}
+(id)spacePlaceholderController{ 
    return [RHPreferencesCustomPlaceholderController controllerWithIdentifier:NSToolbarSpaceItemIdentifier]; 
}
+(id)showColorsPlaceholderController{ 
    return [RHPreferencesCustomPlaceholderController controllerWithIdentifier:NSToolbarShowColorsItemIdentifier]; 
}
+(id)showFontsPlaceholderController{ 
    return [RHPreferencesCustomPlaceholderController controllerWithIdentifier:NSToolbarShowFontsItemIdentifier]; 
}
+(id)customizeToolbarPlaceholderController{ 
    return [RHPreferencesCustomPlaceholderController controllerWithIdentifier:NSToolbarCustomizeToolbarItemIdentifier]; 
}
+(id)printPlaceholderController{ 
    return [RHPreferencesCustomPlaceholderController controllerWithIdentifier:NSToolbarPrintItemIdentifier]; 
}

#pragma mark - NSWindowController

-(void)loadWindow{
    [super loadWindow];
    
    if (self.defaultWindowTitle){
        self.window.title = self.defaultWindowTitle;
         self.defaultWindowTitle = nil;
    }
    
    NSViewController <RHPreferencesViewControllerProtocol> *selectedViewController = self.selectedViewController;
    if (selectedViewController){
        
        //add the view to the windows content view
        if ([selectedViewController respondsToSelector:@selector(viewWillAppear)]){
            [selectedViewController viewWillAppear];
        }        
        
        [self.window.contentView addSubview:selectedViewController.view];
        
        if ([selectedViewController respondsToSelector:@selector(viewDidAppear)]){
            [selectedViewController viewDidAppear];
        }        
        
        //resize to Preferred window size for given view    
        [self resizeWindowForContentSize:selectedViewController.view.bounds.size duration:0.0f];
        
        [selectedViewController.view setFrameOrigin:NSMakePoint(0, 0)];
        (selectedViewController.view).autoresizingMask = NSViewMaxXMargin|NSViewMaxYMargin;
        
        
        //set the current controllers tab to selected    
        _toolbar.selectedItemIdentifier = [self toolbarItemIdentifierForViewController:selectedViewController];
        
        //if there is a initialKeyView set it as key
        if ([selectedViewController respondsToSelector:@selector(initialKeyView)]){
            [[selectedViewController initialKeyView] becomeFirstResponder];
        }
        
        //if we should auto-update window title, do it now 
        if (_windowTitleShouldAutomaticlyUpdateToReflectSelectedViewController){
            NSString *identifier = [self toolbarItemIdentifierForViewController:selectedViewController];
            NSString *title = [self toolbarItemWithItemIdentifier:identifier].label;
            if (title)self.windowTitle = title;
        }
    }
}

-(void)windowDidLoad{
    [super windowDidLoad];
}

#pragma mark - NSWindowDelegate

- (void)showWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    //[self.window center];
    [super showWindow:sender];
    
    NSEvent* causalEvent = NSApp.currentEvent;
    
    NSUInteger currentItemCount = _toolbar.items.count;
    do {
        [_toolbar removeItemAtIndex:0];
        currentItemCount--;
    }
    while (currentItemCount > 0); //remove all toolbar items
    
    
    if (causalEvent.modifierFlags & NSEventModifierFlagOption)
    {
        for (NSUInteger idx = 0; idx < _toolbarItems.count; idx++) { //then add ALL items
            [_toolbar insertItemWithItemIdentifier:_toolbarItems[idx].itemIdentifier atIndex:idx];
        }
    } else {
        NSUInteger idxInToolbar = 0;
        for (NSUInteger idx = 0; idx < _toolbarItems.count; idx++) { //then (re-)add the non-hidden ones
            NSToolbarItem* item = _toolbarItems[idx];
            
            NSViewController <RHPreferencesViewControllerProtocol>* controller = [self viewControllerWithIdentifier:item.itemIdentifier];
            if ([controller respondsToSelector:@selector(isHiddenByDefault)])
                if (controller.isHiddenByDefault)
                    continue;
            
            [_toolbar insertItemWithItemIdentifier:_toolbarItems[idx].itemIdentifier atIndex:idxInToolbar];
            idxInToolbar++;
        }
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    NSViewController <RHPreferencesViewControllerProtocol> *selectedViewController = self.selectedViewController;
    if (self.window == notification.object) {
        if ([selectedViewController respondsToSelector:@selector(viewWindowDidBecomeKey)]) {
            [selectedViewController viewWindowDidBecomeKey];
        }
    }
}

-(BOOL)windowShouldClose:(id)sender{
    NSViewController <RHPreferencesViewControllerProtocol> *selectedViewController = self.selectedViewController;
    if (selectedViewController){
        /*return */[selectedViewController commitEditing];
    }
    
    [self.window makeFirstResponder:self];
    return YES;
}

-(void)windowWillClose:(NSNotification *)notification{
    // steal firstResponder away from text fields, to commit editing to bindings
    [self.window makeFirstResponder:self];
}

#pragma mark - NSToolbarDelegate

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag{
   return [self toolbarItemWithItemIdentifier:itemIdentifier];
}

-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar{
    return [self toolbarItemIdentifiers];
}

-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar{
    return [self toolbarItemIdentifiers];
}

-(NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar{
    return [self toolbarItemIdentifiers];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem{
    return toolbarItem.enabled;
}

#pragma mark - Keyboard listeners

- (void)keyDown:(NSEvent *)theEvent
{
    if ([theEvent.charactersIgnoringModifiers isEqualToString:@"w"] && theEvent.modifierFlags & NSEventModifierFlagCommand) {
        [self close];
        return;
    }
    
    [super keyDown:theEvent];
}

@end
