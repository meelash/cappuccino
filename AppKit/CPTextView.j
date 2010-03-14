/*
 *  CPTextView.j
 *  AppKit
 *
 *  Created by Emmanuel Maillard on 27/02/2010.
 *  Copyright Emmanuel Maillard 2010.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPText.j"
@import "CPTextStorage.j"
@import "CPTextContainer.j"
@import "CPLayoutManager.j"

/*
    CPTextView Notifications
*/
CPTextViewDidChangeSelectionNotification = @"CPTextViewDidChangeSelectionNotification";


var kDelegateRespondsTo_textShouldBeginEditing = 0x0001;
var kDelegateRespondsTo_textView_doCommandBySelector = 0x0002;
var kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange = 0x0004;

/*! 
    @ingroup appkit
    @class CPTextView
*/
@implementation CPTextView : CPText
{
    CPTextStorage _textStorage;
    CPTextContainer _textContainer;
    CPLayoutManager _layoutManager;
    id _delegate;

    unsigned _delegateRespondsToSelectorMask;
    
    CPSize _textContainerInset;
    CPPoint _textContainerOrigin;
    
    int _startTrackingLocation;
    CPRange _selectionRange;
    
    BOOL _isFirstResponder;
    
    BOOL _isEditable;
    BOOL _isSelectable;
        
    BOOL _drawCarret;
    CPTimer _carretTimer;
    CPRect _carretRect;
    
    CPFont _font;
    CPColor _textColor;
    
    /* use bit mask ? */
    BOOL _isRichText;
    BOOL _usesFontPanel;
    BOOL _allowsUndo;
}
-(id) initWithFrame:(CPRect)aFrame textContainer:(CPTextContainer)aContainer
{
    self = [super initWithFrame:aFrame];
    if (self)
    {
        _textContainerInset = CPSizeMake(2,0);
        _textContainerOrigin = CPPointMake(_bounds.origin.x, _bounds.origin.y);
        [aContainer setTextView:self];
        _isEditable = YES;
        _isSelectable = YES;
        
        _isFirstResponder = NO;
        _delegate = nil;
        _delegateRespondsToSelectorMask = 0;
        _selectionRange = CPMakeRange(0, 0);
        
        _textColor = [CPColor blackColor];
        _font = [CPFont fontWithName:@"Helvetica" size:12.0];
        
        _isRichText = YES;
        _usesFontPanel = YES;
        _allowsUndo = NO;
        
        _carretRect = CPRectMake(0,0,1,12);
    }
    return self;
}
- (id)initWithFrame:(CPRect)aFrame
{
    var layoutManager = [[CPLayoutManager alloc] init],
    textStorage = [[CPTextStorage alloc] init],
    container = [[CPTextContainer alloc] initWithContainerSize:aFrame.size];
    
    [textStorage addLayoutManager:layoutManager];
    [layoutManager addTextContainer:container];
        
    return [self initWithFrame:aFrame textContainer:container];
}

- (void)setDelegate:(id)aDelegate
{
    _delegateRespondsToSelectorMask = 0;
    if (_delegate)
    {
        [[CPNotificationCenter defaultCenter] removeObserver:_delegate name:nil object:self];
    }
    _delegate = aDelegate;
    if (_delegate)
    {
        if ([_delegate respondsToSelector:@selector(textDidChange:)])
            [[CPNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(textDidChange:) name:CPTextDidChangeNotification object:self];
        
        if ([_delegate respondsToSelector:@selector(textViewDidChangeSelection:)])
            [[CPNotificationCenter defaultCenter] addObserver:_delegate selector:@selector(textViewDidChangeSelection:) name:CPTextViewDidChangeSelectionNotification object:self];
            
        if ([_delegate respondsToSelector:@selector(textView:doCommandBySelector:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_doCommandBySelector;
            
        if ([_delegate respondsToSelector:@selector(textShouldBeginEditing:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textShouldBeginEditing;
            
        if ([_delegate respondsToSelector:@selector(textView:willChangeSelectionFromCharacterRange:toCharacterRange:)])
            _delegateRespondsToSelectorMask |= kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange;
    }
}

- (void)setTextContainer:(CPTextContainer)aContainer
{
    _textContainer = aContainer;
    _layoutManager = [_textContainer layoutManager];
    _textStorage = [_layoutManager textStorage];
    
    [self invalidateTextContainerOrigin];
}
- (CPTextStorage)textStorage
{
    return _textStorage;
}

-(CPTextContainer)textContainer
{
    return _textContainer;
}

- (void)setTextContainerInset:(CPSize)aSize
{
    _textContainerInset = aSize;
    [self invalidateTextContainerOrigin];
}

- (CPSize)textContainerInset
{
    return _textContainerInset;
}

- (CPPoint)textContainerOrigin
{
    return _textContainerOrigin;
}

- (void)invalidateTextContainerOrigin
{
    _textContainerOrigin.x = _bounds.origin.x;
    _textContainerOrigin.x += _textContainerInset.width;

    _textContainerOrigin.y = _bounds.origin.y;
    _textContainerOrigin.y += _textContainerInset.height;
}

- (BOOL)isEditable
{
    return _isEditable;
}

- (void)setEditable:(BOOL)flag
{
    _isEditable = flag;
    if (flag)
        _isSelectable = flag;
}

- (BOOL)isSelectable
{
    return _isSelectable;
}

- (void)setSelectable:(BOOL)flag
{
    _isSelectable = flag;
    if (flag)
        _isEditable = flag;
}

- (void)doCommandBySelector:(SEL)aSelector
{
    var done = NO;
    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_doCommandBySelector)
        done = [_delegate textView:self doCommandBySelector:aSelector];
    if (!done)
        [super doCommandBySelector:aSelector];
}

- (void)didChangeText
{
    [[CPNotificationCenter defaultCenter] postNotificationName:CPTextDidChangeNotification object:self];
}

- (BOOL)shouldChangeTextInRange:(CPRange)aRange replacementString:(CPString)aString
{
    if (!_isEditable)
        return NO;
        
    var shouldChange = YES;
    if (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textShouldBeginEditing)
        shouldChange = [_delegate textShouldBeginEditing:self];
    return shouldChange;
}

- (void)insertText:(id)aString
{    
    var isAttributed = [aString isKindOfClass:CPAttributedString],
        string = (isAttributed)?[aString string]:aString;

    if (![self shouldChangeTextInRange:CPCopyRange(_selectionRange) replacementString:string])
        return;

    if (isAttributed)
        [_textStorage replaceCharactersInRange:CPCopyRange(_selectionRange) withAttributedString:aString];
    else
    {
        var attributes = [[CPDictionary alloc] initWithObjects:[[self font], [self textColor]] forKeys:[CPFontAttributeName, CPForegroundColorAttributeName]];
        [_textStorage replaceCharactersInRange:CPCopyRange(_selectionRange) withAttributedString:[[CPAttributedString alloc] initWithString:aString attributes:attributes]];
    }
    [self setSelectedRange:CPMakeRange(_selectionRange.location + [string length], 0)];

    [self didChangeText];
}

- (void)_blinkCarret:(CPTimer)aTimer
{
    if (_isFirstResponder)
    {
        _drawCarret = !_drawCarret;
        if (_selectionRange.location == [_textStorage length])
            _carretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(_selectionRange.location - 1, 1) inTextContainer:_textContainer];
        else
            _carretRect = [_layoutManager boundingRectForGlyphRange:CPMakeRange(_selectionRange.location, 1) inTextContainer:_textContainer];
        if (CPRectIsEmpty(_carretRect))
            _carretRect = CPRectMake(_textContainerOrigin.x, _textContainerOrigin.y, 1, [[self font] size]);
        else
        {
            _carretRect.origin.x += _textContainerOrigin.x;
            _carretRect.origin.y += _textContainerOrigin.y;
            if (_selectionRange.location == [_textStorage length])
                _carretRect.origin.x += _carretRect.size.width;
            _carretRect.size.width = 1;
        }
        [self setNeedsDisplayInRect:_carretRect];
    }
}

- (void)drawRect:(CPRect)aRect
{
    /*
        ???: handle selection drawing like :
            -setSelectedRange:affinity:stillSelecting: send [_layoutManager setTemporaryAttributes:forCharacterRange:]
            ...
            -drawRect: send [_layoutManager drawBackgroundForGlyphRange:atPoint:]
    */
    var range = [_layoutManager glyphRangeForBoundingRect:aRect inTextContainer:_textContainer];
    if (!CPEmptyRange(range))
    {
        [_layoutManager drawGlyphsForGlyphRange:range atPoint:_textContainerOrigin];
    }
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextClearRect(ctx, aRect);
    if (!CPEmptyRange(_selectionRange))
    {
        var rect = [_layoutManager boundingRectForGlyphRange:_selectionRange inTextContainer:_textContainer];
        CGContextSaveGState(ctx);
    
        CGContextSetFillColor(ctx, [CPColor alternateSelectedControlColor]);
        CGContextFillRect(ctx, rect);
        CGContextRestoreGState(ctx);
    }
    else if (_drawCarret)
    {
        CGContextSaveGState(ctx);
        
        CGContextSetLineWidth(ctx, 1);
        CGContextSetFillColor(ctx, [CPColor blackColor]);
        CGContextFillRect(ctx, _carretRect);
        CGContextRestoreGState(ctx);
    }
}

- (void)setSelectedRange:(CPRange)range
{
    [self setSelectedRange:range affinity:0 stillSelecting:NO];
}

- (void)setSelectedRange:(CPRange)range affinity:(CPSelectionAffinity /* unused */ )affinity stillSelecting:(BOOL)selecting
{
    if (!selecting && (_delegateRespondsToSelectorMask & kDelegateRespondsTo_textView_willChangeSelectionFromCharacterRange_toCharacterRange))
        _selectionRange = [_delegate textView:self willChangeSelectionFromCharacterRange:_selectionRange toCharacterRange:range];
    else
        _selectionRange = CPCopyRange(range);
        
    if (!selecting)
    {
        [[CPNotificationCenter defaultCenter] postNotificationName:CPTextViewDidChangeSelectionNotification object:self];
        
        if (_usesFontPanel)
        {
            // TODO: check multiple font in selection        
            var attributes = [_textStorage attributesAtIndex:_selectionRange.location effectiveRange:nil],
                font = [attributes objectForKey:CPFontAttributeName];
            [[CPFontManager sharedFontManager] setSelectedFont:(font)?font:[self font] isMultiple:NO];
        }
    }
}

- (CPArray)selectedRanges
{
    return [_selectionRange];
}

- (void)keyDown:(CPEvent)event
{
    [self interpretKeyEvents:[event]];
}

- (void)mouseDown:(CPEvent)event
{
    var fraction = [];
    _startTrackingLocation = [_layoutManager glyphIndexForPoint:[self convertPoint:[event locationInWindow] fromView:nil] inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction];
    if (_startTrackingLocation == CPNotFound)
        _startTrackingLocation = [_textStorage length];
     
    [self setSelectedRange:CPMakeRange(_startTrackingLocation, 0) affinity:0 stillSelecting:YES];
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(CPEvent)event
{
    var fraction = [],
        index = [_layoutManager glyphIndexForPoint:[self convertPoint:[event locationInWindow] fromView:nil] inTextContainer:_textContainer fractionOfDistanceThroughGlyph:fraction];
    if (index == CPNotFound)
        index = [_textStorage length];
    
    if (index < _startTrackingLocation)
        [self setSelectedRange:CPMakeRange(index, _startTrackingLocation - index) affinity:0 stillSelecting:YES];
    else
        [self setSelectedRange:CPMakeRange(_startTrackingLocation, index - _startTrackingLocation) affinity:0 stillSelecting:YES];
    
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(CPEvent)event
{
    /* will post CPTextViewDidChangeSelectionNotification */
    [self setSelectedRange:[self selectedRange] affinity:0 stillSelecting:NO];
}

- (void)moveLeft:(id)sender
{
    if (_isSelectable)
    {
        /* TODO: handle modifiers */
        if (_selectionRange.location > 0)
            [self setSelectedRange:CPMakeRange(_selectionRange.location - 1, 0)];
    }
}

- (void)moveRight:(id)sender
{
    if (_isSelectable)
    {
        /* TODO: handle modifiers */
        if (_selectionRange.location < [_textStorage length])
            [self setSelectedRange:CPMakeRange(_selectionRange.location + 1, 0)];
    }
}

- (void)selectAll:(id)sender
{
    if (_isSelectable)
    {
        [self setSelectedRange:CPMakeRange(0, [_textStorage length])];
        [self setNeedsDisplay:YES];
    }
}   

- (void)deleteBackward:(id)sender
{
    var changedRange = nil;

    if (CPEmptyRange(_selectionRange) && _selectionRange.location > 0)
        changedRange = CPMakeRange(_selectionRange.location - 1, 1);
    else
        changedRange = CPCopyRange(_selectionRange);

    if (![self shouldChangeTextInRange:changedRange replacementString:@""])
        return;

    [_textStorage deleteCharactersInRange:CPCopyRange(changedRange)];
    [self setSelectedRange:CPMakeRange(changedRange.location, 0)];

    [self didChangeText];
}

- (void)insertLineBreak:(id)sender
{
    [self insertText:@"\n"];
}

- (BOOL)acceptsFirstResponder
{
    if (_isSelectable)
        return YES;
    return NO;
}

- (BOOL)becomeFirstResponder
{    
    _isFirstResponder = YES;
    _drawCarret = YES;
    _carretTimer = [CPTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_blinkCarret:) userInfo:nil repeats:YES];
    [[CPFontManager sharedFontManager] setSelectedFont:[self font] isMultiple:NO];
    return YES;
}
- (BOOL)resignFirstResponder
{
    [_carretTimer invalidate];
    _isFirstResponder = NO;
    return YES;
}

- (void)layoutSubviews
{
    [_textContainer _invalidateAllLines];
}

/* CPText concrete */
- (void)delete:(id)sender
{
    if (![self shouldChangeTextInRange:_selectionRange replacementString:@""])
        return;
        
    [_textStorage deleteCharactersInRange:CPCopyRange(_selectionRange)];
    [self setSelectedRange:CPMakeRange(_selectionRange.location, 0)];
    [self didChangeText];
}

- (void)setFont:(CPFont)font
{
    _font = font;
    [_textStorage addAttribute:CPFontAttributeName value:_font range:CPMakeRange(0, [_textStorage length])];
}

- (void)setFont:(CPFont)font range:(CPRange)range
{
    if (!_isRichText)
        return;

    if (CPMaxRange(range) >= [_textStorage length])
        _font = font;

    [_textStorage addAttribute:CPFontAttributeName value:font range:CPCopyRange(range)];
        
    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
}

- (CPFont)font
{
    return _font;
}

- (void)changeColor:(id)sender
{
    [self setTextColor:[sender color] range:_selectionRange];
}

- (void)changeFont:(id)sender
{
    var attributes = [_textStorage attributesAtIndex:_selectionRange.location effectiveRange:nil],
        oldFont = [attributes objectForKey:CPFontAttributeName];

    if (!oldFont)
        oldFont = [self font];

    if ([self isRichText])
    {
        [self setFont:[sender convertFont:oldFont] range:_selectionRange];
    }
    else
    {
        var range = CPMakeRange(0, [_textStorage length]);
        [self setFont:[sender convertFont:oldFont] range:range];
    }
}

- (void)underline:(id)sender
{
    if (![self shouldChangeTextInRange:_selectionRange replacementString:nil])
        return;

    if (!CPEmptyRange(_selectionRange))
    {
        var attrib = [_textStorage attributesAtIndex:_selectionRange.location effectiveRange:nil];
        if ([attrib containsKey:CPUnderlineStyleAttributeName] && [[attrib objectForKey:CPUnderlineStyleAttributeName] intValue])
            [_textStorage removeAttribute:CPUnderlineStyleAttributeName range:_selectionRange];
        else
            [_textStorage addAttribute:CPUnderlineStyleAttributeName value:[CPNumber numberWithInt:1] range:CPCopyRange(_selectionRange)];
    }
    /* else TODO: */
}

- (CPSelectionAffinity)selectionAffinity
{
    return 0;
}

- (void)setUsesFontPanel:(BOOL)flag
{
    _usesFontPanel = flags;
}

- (BOOL)usesFontPanel
{
    return _usesFontPanel;
}

- (void)setTextColor:(CPColor)aColor
{
    _textColor = aColor;
    if (_textColor)
        [_textStorage addAttribute:CPForegroundColorAttributeName value:_textColor range:CPMakeRange(0, [_textStorage length])];
    else
        [_textStorage removeAttribute:CPForegroundColorAttributeName range:CPMakeRange(0, [_textStorage length])];
}

- (void)setTextColor:(CPColor)aColor range:(CPRange)range
{
    if (!_isRichText)
        return;

    if (CPMaxRange(range) >= [_textStorage length])
        _textColor = aColor;

    if (aColor)
        [_textStorage addAttribute:CPForegroundColorAttributeName value:aColor range:CPCopyRange(range)];
    else
        [_textStorage removeAttribute:CPForegroundColorAttributeName range:CPCopyRange(range)];
}

- (CPColor)textColor
{
    return _textColor;
}

- (BOOL)isRichText
{
    return _isRichText;
}

- (BOOL)isRulerVisible
{
    return NO;
}
- (BOOL)allowsUndo
{
    return _allowsUndo;
}
- (CPRange)selectedRange
{
    return _selectionRange;
}
- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    [_textStorage replaceCharactersInRange:aRange withString:aString];
}
- (CPString)string
{
    return [_textStorage string];
}
@end

@implementation CPTextView (DOMElementHandling)
-(void)appendElement:(id)anElement
{
    _DOMElement.appendChild(anElement);
}
-(void)removeElement:(id)anElement
{
    _DOMElement.removeChild(anElement);
}
@end
