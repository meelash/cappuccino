/*
Cursor support by browser:
    OS X 10.6/Chrome 8       : All
    OS X 10.6/Safari 5       : All
    OS X 10.6/Firefox 3      : All except disappearingItemCursor (no url() support)
    OS X 10.6/Firefox 3.5    : All except disappearingItemCursor (no url() support)
    OS X 10.6/Firefox 3.6    : All except disappearingItemCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor (no url() support)
    OS X 10.6/Firefox 4.0b10 : All
    OS X/Opera 9             : All except disappearingItemCursor, closedHandCursor, openHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor, resizeUpDownCursor, resizeLeftRightCursor  (no url() support)
    OS X/Opera 10            : All except disappearingItemCursor, closedHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor (no url() support)
    OS X/Opera 11            : All except disappearingItemCursor, closedHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor (no url() support)
    Win XP/Chrome 8          : All 
    Win XP/Safari 5          : All
    Win XP/Firefox 3         : All
    Win XP/Firefox 3.5       : All
    Win XP/Firefox 3.6       : All
    Win XP/Firefox 4.0b10    : All
    Win XP/Opera 10          : All except disappearingItemCursor, closedHandCursor, openHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor, resizeUpDownCursor, resizeLeftRightCursor (no url() support)
    Win XP/Opera 11          : All except disappearingItemCursor, closedHandCursor, openHandCursor, contextualMenuCursor, dragLinkCursor, dragCopyCursor, operationNotAllowedCursor, resizeUpDownCursor, resizeLeftRightCursor (no url() support)
    Win XP/IE 7              : All
    Win XP/IE 8              : All
*/

@import <Foundation/CPObject.j>

var currentCursor = nil,
    cursorStack = [],
    cursors = {};

@implementation CPCursor : CPObject
{
    CPString _cssString @accessors(readonly);
    CPString _hotSpot @accessors(readonly, getter=hotSpot);
    CPImage  _image @accessors(readonly, getter=image);
    BOOL     _isSetOnMouseEntered @accessors(readwrite, getter=isSetOnMouseEntered, setter=setOnMouseEntered:);
    BOOL     _isSetOnMouseExited @accessors(readwrite, getter=isSetOnMouseExited, setter=setOnMouseExited:);
}

- (id)initWithCSSString:(CPString)aString
{
    if (self = [super init])
        _cssString = aString;

    return self;
}

// hotspot is supported in CSS3 (but not IE).
- (id)initWithImage:(CPImage)image hotSpot:(CPPoint)hotSpot
{
    _hotSpot = hotSpot;
    _image = image;
    return [self initWithCSSString:"url(" + [_image filename] + ")" + hotSpot.x + " " + hotSpot.y + ", auto"];
}

// foregroundColor and backgroundColor are ignored in Cocoa as well.  See http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Classes/NSCursor_Class/Reference/Reference.html
– (id)initWithImage:(CPImage)image foregroundColorHint:(CPColor)foregroundColor backgroundColorHint:(CPColor)backgroundColor hotSpot:(CPPoint)aHotSpot
{
    return [self initWithImage:image hotSpot:hotSpot];
}

+ (void)hide
{
    [self _setCursorCSS:"none"]; // Not supported in IE
}

+ (void)unhide
{
    [self _setCursorCSS:[currentCursor _cssString]];
}

+ (void)setHiddenUntilMouseMoves:(BOOL)flag
{
    if (flag)
        [CPCursor hide];
    else
        [CPCursor unhide];
}

- (void)pop
{
    [CPCursor pop];
}

+ (void)pop
{
    if (cursorStack.length > 1)
    {
        cursorStack.pop();
        currentCursor = cursorStack[cursorStack.length - 1];
    }
}

- (void)push
{
    currentCursor = cursorStack.push(self);
}

- (void)set
{
    currentCursor = self;

#if PLATFORM(DOM)
    [[self class] _setCursorCSS:_cssString];
#endif
}

- (void)mouseEntered:(CPEvent)event
{
}

- (void)mouseExited:(CPEvent)event
{
}

+ (CPCursor)currentCursor
{
    return currentCursor;
}

+ (void)_setCursorCSS:(CPString)aString
{
#if PLATFORM(DOM)
    var platformWindows = [[CPPlatformWindow visiblePlatformWindows] allObjects];
    for (var i = 0, count = [platformWindows count]; i < count; i++)
        platformWindows[i]._DOMBodyElement.style.cursor = aString;
#endif
}

// Internal method that is used to return the system cursors.  Caches the system cursors for performance.
+ (CPCursor)_systemCursorWithName:(CPString)cursorName cssString:(CPString)aString hasImage:(BOOL)doesHaveImage
{
    var cursor = cursors[cursorName];
    if (typeof cursor === 'undefined')
    {
        var cssString;
        if (doesHaveImage)
            cssString = @"url(" + [[CPBundle bundleForClass:self] resourcePath] + @"/CPCursor/" + cursorName + ".cur), " + aString;
        else
            cssString = aString
        cursor = [[CPCursor alloc] initWithCSSString:cssString];
        cursors[cursorName] = cursor;
    }
    return cursor;
}

+ (CPCursor)arrowCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:"default" hasImage:NO];
}

+ (CPCursor)crosshairCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"crosshair" hasImage:NO];
}

+ (CPCursor)IBeamCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"text" hasImage:NO];
}

+ (CPCursor)pointingHandCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"pointer" hasImage:NO];
}

+ (CPCursor)resizeDownCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"s-resize" hasImage:NO];
}

+ (CPCursor)resizeUpCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"n-resize" hasImage:NO];
}

+ (CPCursor)resizeLeftCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"w-resize" hasImage:NO];
}

+ (CPCursor)resizeRightCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"e-resize" hasImage:NO];
}

+ (CPCursor)resizeLeftRightCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"col-resize" hasImage:NO];
}

+ (CPCursor)resizeUpDownCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"row-resize" hasImage:NO];
}

+ (CPCursor)operationNotAllowedCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"not-allowed" hasImage:NO];
}

+ (CPCursor)dragCopyCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"copy" hasImage:YES];
}

+ (CPCursor)dragLinkCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"alias" hasImage:YES];
}

+ (CPCursor)contextualMenuCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"context-menu" hasImage:YES];
}

+ (CPCursor)openHandCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"move" hasImage:YES];
}

+ (CPCursor)closedHandCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"-moz-grabbing" hasImage:YES];
}

+ (CPCursor)disappearingItemCursor
{
    return [CPCursor _systemCursorWithName:CPStringFromSelector(_cmd) cssString:@"auto" hasImage:YES];
}

@end

@implementation CPCursor(CPCoding)

- (id)initWithCoder:(CPCoder)coder
{
    if (self = [super init])
        _cssString = [coder decodeObjectForKey:@"CPCursorNameKey"];

    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_cssString forKey:@"CPCursorNameKey"];
}

@end
