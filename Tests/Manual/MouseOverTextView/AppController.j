/*
 * AppController.j
 * MouseOverText
 *
 * Test app based on an Apple sample http://developer.apple.com/mac/library/samplecode/LayoutManagerDemo/index.html
 */

@import <Foundation/CPObject.j>


@implementation MouseOverTextView : CPTextView
{
}
- (void)mouseMoved:(CPEvent)event
{
    var layoutManager = [self layoutManager];
    var textContainer = [self textContainer];
    var glyphIndex, charIndex, textLength = [[self textStorage] length];
    
    var point = [self convertPoint:[event locationInWindow] fromView:nil];
    var lineGlyphRange = CPMakeRange(0, 0), lineCharRange, wordCharRange, textCharRange = CPMakeRange(0, textLength);
    var glyphRect;
    
    // Remove any existing coloring.
    [layoutManager removeTemporaryAttribute:CPBackgroundColorAttributeName forCharacterRange:textCharRange];

    // Convert view coordinates to container coordinates
    point.x -= [self textContainerOrigin].x;
    point.y -= [self textContainerOrigin].y;
    
    // Convert those coordinates to the nearest glyph index
    glyphIndex = [layoutManager glyphIndexForPoint:point inTextContainer:textContainer];
    
    // Check to see whether the mouse actually lies over the glyph it is nearest to
    glyphRect = [layoutManager boundingRectForGlyphRange:CPMakeRange(glyphIndex, 1) inTextContainer:textContainer];
    if (CPRectContainsPoint(glyphRect, point)) {
        // Convert the glyph index to a character index
        charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

        // Determine the range of glyphs, and of characters, in the corresponding line
        [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:lineGlyphRange];        
        lineCharRange = [layoutManager characterRangeForGlyphRange:lineGlyphRange actualGlyphRange:nil];
        
        // Determine the word containing that character
        wordCharRange = CPIntersectionRange(lineCharRange, [self selectionRangeForProposedRange:CPMakeRange(charIndex, 0) granularity:CPSelectByWord]);
        
        // Color the characters using temporary attributes
        [layoutManager addTemporaryAttributes:[CPDictionary dictionaryWithObject:[CPColor cyanColor] forKey:CPBackgroundColorAttributeName] forCharacterRange:lineCharRange];
        [layoutManager addTemporaryAttributes:[CPDictionary dictionaryWithObject:[CPColor yellowColor] forKey:CPBackgroundColorAttributeName] forCharacterRange:wordCharRange];
        [layoutManager addTemporaryAttributes:[CPDictionary dictionaryWithObject:[CPColor magentaColor] forKey:CPBackgroundColorAttributeName] forCharacterRange:CPMakeRange(charIndex, 1)];
    }
}
@end

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    CPLogRegister(CPLogConsole);
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    [theWindow setAcceptsMouseMovedEvents:YES];

    var label = [[MouseOverTextView alloc] initWithFrame:CGRectMake(10,10,500,500)];

    [label setFont:[CPFont boldSystemFontOfSize:24.0]];
    [label insertText:@"Hello World!"];

    [contentView addSubview:label];

    /* build our menu */
    var mainMenu = [CPApp mainMenu];
    while ([mainMenu numberOfItems] > 0)
        [mainMenu removeItemAtIndex:0];

    var item = [mainMenu insertItemWithTitle:@"Edit" action:nil keyEquivalent:nil atIndex:0],
        editMenu = [[CPMenu alloc] initWithTitle:@"Edit Menu"];
        
    [editMenu addItemWithTitle:@"Delete" action:@selector(delete:) keyEquivalent:@""];
    [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    
    [mainMenu setSubmenu:editMenu forItem:item];

    item = [mainMenu insertItemWithTitle:@"Font" action:nil keyEquivalent:nil atIndex:1];    
    [mainMenu setSubmenu:[[CPFontManager sharedFontManager] fontMenu:YES] forItem:item];

    [theWindow orderFront:self];

    // Uncomment the following line to turn on the standard menu bar.
    [CPMenu setMenuBarVisible:YES];
}

@end
