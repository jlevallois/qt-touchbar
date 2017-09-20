#include "touchbar.h"
#import <AppKit/NSTouchBar.h>
#import <AppKit/NSCustomTouchBarItem.h>
#import <AppKit/NSButton.h>
#import <Foundation/NSAttributedString.h>
#import <Cocoa/Cocoa.h>
#include <iostream>
#include <QDebug>
#include <QtCore>
#include "touchbarbutton.h"

using namespace std;

#import <AppKit/AppKit.h>

// This example shows how to create and populate touch bars for Qt applications.
// Two approaches are demonstrated: creating a global touch bar for the entire
// application via the NSApplication delegate, and creating per-window touch bars
// via the NSWindow delegate. Applications may use either or both of these, for example
// to provide global base touch bar with window specific additions. Refer to the
// NSTouchBar documentation for further details.

// The TouchBarProvider class implements the NSTouchBarDelegate protocol, as
// well as app and window delegate protocols.
@interface TouchBarProvider: NSResponder <NSTouchBarDelegate, NSApplicationDelegate, NSWindowDelegate>
@property (strong) NSMutableDictionary *items;
@property (strong) NSObject *qtDelegate;

@end

@implementation TouchBarProvider
@synthesize items;
- (NSTouchBar *)makeTouchBar
{
    // Create the touch bar with this instance as its delegate

    self.touchBar = [[NSTouchBar alloc] init];
    self.touchBar.delegate = self;

    return self.touchBar;
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    Q_UNUSED(touchBar);
    if([self.items objectForKey:identifier] != nil) {
        return [self.items objectForKey:identifier];
    }
    NSLog(@"Did not have key, checking rest: %@", identifier);
    return nil;
}

- (void)installAsDelegateForWindow:(NSWindow *)window
{
    _qtDelegate = window.delegate; // Save current delegate for forwarding
    window.delegate = self;
}

- (void)installAsDelegateForApplication:(NSApplication *)application
{
    _qtDelegate = application.delegate; // Save current delegate for forwarding
    application.delegate = self;
}

- (BOOL):(SEL)aSelector
{
    // We want to forward to the qt delegate. Respond to selectors it
    // responds to in addition to selectors this instance resonds to.
    return [_qtDelegate respondsToSelector:aSelector] || [super respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    // Forward to the existing delegate. This function is only called for selectors
    // this instance does not responds to, which means that the qt delegate
    // must respond to it (due to the respondsToSelector implementation above).
    [anInvocation invokeWithTarget:_qtDelegate];
}

@end

TouchBar::TouchBar(QQuickItem *parent) : QQuickItem(parent)
{
    qDebug() << "Did create TouchBar";
    m_tbProvider = [[TouchBarProvider alloc] init];
    [(id)m_tbProvider installAsDelegateForApplication:[NSApplication sharedApplication]];
}

void TouchBar::itemChange(ItemChange, const ItemChangeData &)
{
    NSMutableDictionary *items = [NSMutableDictionary dictionary];

    int i = 0;
    for(QObject *child : children()) {
        if(dynamic_cast<TouchBarButton*>(child)) {
            NSString *identifier = [NSString stringWithFormat:@"com.myapp.%d", i++];
            // This is a button
            TouchBarButton *button = dynamic_cast<TouchBarButton*>(child);
            NSCustomTouchBarItem *touchBarItem1 = [[[NSCustomTouchBarItem alloc] initWithIdentifier:identifier] autorelease];
            NSButton *touchBarButton1 = [[NSButton buttonWithTitle:button->title().toNSString() target:(id)button->block()
                                              action:@selector(invoke)] autorelease];
            touchBarItem1.view =  touchBarButton1;
            [items setObject:touchBarItem1 forKey:identifier];
        }
    }
    TouchBarProvider *tbp = static_cast<TouchBarProvider*>(m_tbProvider);
    [tbp setItems:items];
    tbp.touchBar.defaultItemIdentifiers = [items allKeys];
}
