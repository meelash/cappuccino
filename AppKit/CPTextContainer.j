/*
 *  CPTextContainer.j
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
 
@import "CPLayoutManager.j"
 
/*
    @global
    @group CPLineSweepDirection
*/
CPLineSweepLeft = 0;
/*
    @global
    @group CPLineSweepDirection
*/
CPLineSweepRight = 1;
/*
    @global
    @group CPLineSweepDirection
*/
CPLineSweepDown = 2;
/*
    @global
    @group CPLineSweepDirection
*/
CPLineSweepUp = 3;

/*
    @global
    @group CPLineMovementDirection
*/
CPLineDoesntMoves = 0;
/*
    @global
    @group CPLineMovementDirection
*/
CPLineMovesLeft = 1;
/*
    @global
    @group CPLineMovementDirection
*/
CPLineMovesRight = 2;
/*
    @global
    @group CPLineMovementDirection
*/
CPLineMovesDown = 3;
/*
    @global
    @group CPLineMovementDirection
*/
CPLineMovesUp = 4;


@implementation _CPTextContainerLine : CPObject
{
    DOMElement _DOMElement;
    CPRect _frame;
    CPMutableArray _elements;
    BOOL _isDirty;
    BOOL _isVisible;
    int _lineFragmentPadding;
}
- (id)initWithFrame:(CPRect)aFrame
{   
    self = [super init];
    if (self)
    {
        _elements = [[CPMutableArray alloc] init];
        _frame = aFrame;
        
        _DOMElement = document.createElement("div");
        _DOMElement.style.position = "absolute";
        _DOMElement.style.overflow = "hidden";
        _isDirty = NO;
    }
    return self;
}

- (void)addElement:(_CPTextContainerElement)anElement
{
    [_elements addObject:anElement];
    [anElement setTextContainerLine:self];
    var newRect = CPRectUnion(_frame, anElement._displayFrame);
    _frame = CPRectUnion(_frame, anElement._displayFrame);
    
    _DOMElement.style.width = _frame.size.width + "px";
    _DOMElement.style.height = _frame.size.height + "px";
}

- (BOOL)isDirty
{
    return _isDirty;
}
- (void)markDirty
{
    _isDirty = YES;
}
- (BOOL)isVisible
{
    return _isVisible;
}
- (void)setVisible:(BOOL)visible
{
    _isVisible = visible;
}
- (CPString)description
{
    var descr = [super description]  + " _frame=" + CPStringFromRect(_frame) + " _isDirty=" + _isDirty + " _isVisible=" + _isVisible + " {\n";
    var c = [_elements count];
        for (var i = 0; i < c; i++)
            descr += [_elements[i] description] + "\n";
    descr += "}";
    return descr;
}
- (void)invalidateDirtyContent
{
    var current = 0,
        end = [_elements count];
    while(current < end)
    {
        if ([_elements[current] isDirty])
        {
            _DOMElement.removeChild([_elements objectAtIndex:current]._DOMElement);
            [_elements removeObjectAtIndex:current];
            end--;
        }
        else 
            current++;
    }
}
- (void)displayElement:(_CPTextContainerElement)anElement
{
    _DOMElement.appendChild(anElement._DOMElement);
}
- (void)setLineFragmentPadding:(float)padding
{
    _lineFragmentPadding = ROUND(padding);
    /* TODO: */
}
- (float)lineHeight
{
    return _frame.size.height;
}
- (_CPTextContainerElement)elementAtPoint:(CPPoint)point
{
    var c = [_elements count];
    for (var i= 0; i < c; i++)
        if (CPRectContainsPoint(_elements[i]._displayFrame, point))
            return _elements[i];
    return nil;
}
@end

@implementation _CPTextContainerElement : CPObject
{
    DOMElement _DOMElement;
    CPRect _displayFrame;
    _CPTextFragment _textFragment;
    CPRange _fragmentRange;
    
    _CPTextContainerLine _ownerLine;
    
    BOOL _isDirty;
    BOOL _isVisible;
}
+ (_CPTextContainerElement)textContainerElementWithFrame:(CPRect)aFrame element:(DOMElement)anElement
{
    return [[_CPTextContainerElement alloc] initWithFrame:aFrame element:anElement];
}
- (id)initWithFrame:(CPRect)aFrame element:(DOMElement)anElement
{
    self = [super init];
    if (self)
    {
        _DOMElement = anElement;
        _displayFrame = aFrame;
        _isDirty = NO;
        _isVisible = NO;
    }
    return self;
}
- (CPString)description
{
    return [super description] + " _displayFrame=" + CPStringFromRect(_displayFrame) + " _isDirty=" + _isDirty + " _isVisible=" + _isVisible;
}
- (void)setTextFragment:(_CPTextFragment)textFragment range:(CPRange)aRange
{
    _textFragment = textFragment;
    _fragmentRange = aRange;
}
- (void)setTextContainerLine:(_CPTextContainerLine)aLine
{
    _ownerLine = aLine;
}
- (CPArray)glyphsFrames
{
    var glyphsFrames = [],
        pos = CPPointCreateCopy(_displayFrame.origin),
        sizes = [_textFragment glyphsSizes],
        lineHeight = [_ownerLine lineHeight],
        c = _fragmentRange.length,
        i = _fragmentRange.location - _textFragment._range.location;
            
    while (c-- > 0)
    {
        glyphsFrames.push(CPRectMake(pos.x, pos.y, sizes[i].width, lineHeight));
        pos.x += sizes[i].width;
        i++;
    }
    return glyphsFrames;
}
- (BOOL)isDirty
{
    return _isDirty;
}
- (void)markDirty
{
    _isDirty = YES;
}
- (void)display
{
    if (_isDirty)
    {
        CPLog.error([super description] + " -"+_cmd+" _isDirty");
        return;
    }
    if (_isVisible)
        return;

    [_ownerLine displayElement:self];
    _isVisible = YES;
}
@end

/*! 
    @ingroup appkit
    @class CPTextContainer
*/
@implementation CPTextContainer : CPObject
{
    CPSize _size;
    CPTextView _textView;
    CPLayoutManager _layoutManager;
    float _lineFragmentPadding;
    
    CPMutableArray _lines;
}
-(id)initWithContainerSize:(CPSize)aSize
{
    self = [super init];
    if (self)
    {
        _size = aSize;
        _lineFragmentPadding = 0.0;
        _lines = [[CPMutableArray alloc] init];
    }
    return self;
}

- (CPSize)containerSize
{
    return _size;
}

- (void)setTextView:(CPTextView)aTextView
{
    if (_textView)
    {
        [self _removeAllLines];
        [_textView setTextContainer:nil];
    }
    _textView = aTextView;
    
    if (_textView != nil)
        [_textView setTextContainer:self];

    [_layoutManager textContainerChangedTextView:self];
}

-(CPTextView)textView
{
    return _textView;
}

-(void)setLayoutManager:(CPLayoutManager)aManager
{
    if (_layoutManager === aManager)
        return;
    _layoutManager = aManager;
}

-(CPLayoutManager)layoutManager
{
    return _layoutManager;
}

- (void)setLineFragmentPadding:(float)aFloat
{
    _lineFragmentPadding = aFloat;
}

- (float)lineFragmentPadding
{
    return _lineFragmentPadding;
}

- (BOOL)containsPoint:(CPPoint)aPoint
{
    return CPRectContainsPoint(CPRectMake(0, 0, _size.width, _size.height), aPoint);
}

- (BOOL)isSimpleRectangularTextContainer
{
    return YES;
}

- (CPRect)lineFragmentRectForProposedRect:(CPRect)proposedRect sweepDirection:(CPLineSweepDirection)sweep 
    movementDirection:(CPLineMovementDirection)movement remainingRect:(CPRectPointer)remainingRect
{
    var resultRect = CPRectCreateCopy(proposedRect);
    if (sweep != CPLineSweepRight || movement != CPLineMovesDown)
    {
        CPLog.trace(@"FIXME: unsupported sweep ("+sweep+") or movement ("+movement+")");
        return CPRectMakeZero();
    }
    if (resultRect.origin.x + resultRect.size.width > _size.width)
        resultRect.size.width = _size.width - resultRect.origin.x;

    if (resultRect.size.width < 0)
        resultRect = CPRectMakeZero();

    if (remainingRect)
        remainingRect = CPRectMake(resultRect.origin.x + resultRect.size.width, resultRect.origin.y, resultRect.size.height, _size.width - (resultRect.origin.x + resultRect.size.width));

   return resultRect;
}
@end

@implementation CPTextContainer (ExternPrivate)
- (void)_invalidateAllLines
{
    var current = 0,
        end = [_lines count];
    while (current < end)
    {
        if ([_lines[current] isDirty])
        {
            if ([_lines[current] isVisible])
            {
                [_textView removeElement:_lines[current]._DOMElement];
                [_lines[current] setVisible:NO];
            }
            [_lines removeObjectAtIndex:current];
            end--;
        }
        else
        {
            [_lines[current] invalidateDirtyContent];
            current++;
        }
    }
}

- (void)_displayLinesAtPoint:(CPPoint)origin
{
    var c = [_lines count];
    for (var i= 0; i < c; i++)
    {
        var aLine = _lines[i];
        aLine._DOMElement.style.left = ROUND(origin.x + aLine._frame.origin.x) + "px";
        aLine._DOMElement.style.top = ROUND(origin.y + aLine._frame.origin.y) + "px";
        if (![aLine isVisible])
        {
            [_textView appendElement:aLine._DOMElement];
            [aLine setVisible:YES];
        }
    }
}
- (void)_appendLine:(_CPTextContainerLine)aLine display:(BOOL)display
{
    [_lines addObject:aLine];
    if (display)
    {
        [_textView appendElement:aLine._DOMElement];
        [aLine setVisible:YES];
    }
}

- (_CPTextContainerElement)_elementAtPoint:(CPPoint)point
{
    var c = [_lines count];
    for (var i= 0; i < c; i++)
        if (CPRectContainsPoint(_lines[i]._frame, point))
            return [_lines[i] elementAtPoint:point];
    return nil;
}

- (void)_removeAllLines
{
    var c = [_lines count];
    for  (var i= 0; i < c; i++)
        if ([_lines[i] isVisible]) [_textView removeElement:_lines[i]._DOMElement];
    [_lines removeAllObjects];
}
- (CPArray)_containerLines
{
    return _lines;
}
@end
