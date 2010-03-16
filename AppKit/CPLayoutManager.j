/*
 *  CPLayoutManager.j
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
 
@import "CPTextStorage.j"
@import "CPTextContainer.j"

var _CPLayoutManagerDefaultAttibutes = nil;

@implementation _CPTextFragment :  CPObject
{
    CPSize _textSize;
    CPRange _range;
    CPTextStorage _textStorage;
    CPDictionary _cachedAttributes;
    /* TODO: temporary attributes */
    
    CPFont _font;
    
    BOOL _hasNewline;
    BOOL _isDirty;
    
    CPArray _glyphsSizes;
    CPMutableArray _textContainerElements;
}
+ (_CPTextFragment)textFragmentWithRange:(CPRange)aRange textStorage:(CPTextStorage)textStorage
{
    return [[_CPTextFragment alloc] initWithRange:aRange textStorage:textStorage];
}
- (id)initWithRange:(CPRange)aRange textStorage:(CPTextStorage)textStorage
{
    self = [super init];
    if (self)
    {
        _range = aRange;
        _textStorage = textStorage;
        [self reset];
        _textContainerElements = [[CPMutableArray alloc] init];
    }
    return self;
}

- (void)reset
{
    _cachedAttributes = [_textStorage attributesAtIndex:_range.location effectiveRange:nil];
    if ([_cachedAttributes containsKey:CPFontAttributeName])
        _font = [_cachedAttributes objectForKey:CPFontAttributeName];
    else
        _font = [_textStorage font];

    var fragmentString = [self string];
    _textSize = [fragmentString sizeWithFont:_font];
    _hasNewline = (fragmentString.indexOf('\n') != -1);
    _glyphsSizes = nil;
    _isDirty = YES;
}

- (void)setRange:(CPRange)aRange
{
    _range = aRange;
    [self reset];
}

- (CPString)string
{
    return [_textStorage._string substringWithRange:_range];
}
- (CPDictionary)attributes
{
    return _cachedAttributes;
}
- (CPSize)textSize
{
    return _textSize;
}
- (CPRange)range
{
    return _range;
}
- (CPString)description
{
    return @" _range=" + CPStringFromRange(_range) + " _string=" +[self string] +" _attributes=" + [_cachedAttributes description] + " _textSize=" + CPStringFromSize(_textSize);
}

- (id)makeDOMElement
{
    var domElement = document.createElement("span"),
        domStyle = domElement.style;

    domStyle.font = [_font cssString];

    if ([_cachedAttributes containsKey:CPForegroundColorAttributeName])
        domStyle.color = [[_cachedAttributes objectForKey:CPForegroundColorAttributeName] cssString];
    else
        domStyle.color = [[_textStorage foregroundColor] cssString];

    if ([_cachedAttributes containsKey:CPUnderlineStyleAttributeName] && [[_cachedAttributes objectForKey:CPUnderlineStyleAttributeName] intValue] == 1)
        domStyle.textDecoration = "underline";
    else
        domStyle.textDecoration = "none";
        
    if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
    {
        domElement.innerText = [self string];
    }
    else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
    {
        domElement.textContent = [self string];
    }
    return domElement;
}

- (id)makeDOMElementForRange:(CPRange)aRange
{
    var domElement = document.createElement("span"),
        domStyle = domElement.style;
    
    domStyle.font = [_font cssString];

    if ([_cachedAttributes containsKey:CPForegroundColorAttributeName])
        domStyle.color = [[_cachedAttributes objectForKey:CPForegroundColorAttributeName] cssString];
    else
        domStyle.color = [[_textStorage foregroundColor] cssString];
    
    if ([_cachedAttributes containsKey:CPUnderlineStyleAttributeName] && [[_cachedAttributes objectForKey:CPUnderlineStyleAttributeName] intValue] == 1)
        domStyle.textDecoration = "underline";
    else
        domStyle.textDecoration = "none";
        
    if (CPFeatureIsCompatible(CPJavascriptInnerTextFeature))
    {
        domElement.innerText = [[self string] substringWithRange:aRange];
    }
    else if (CPFeatureIsCompatible(CPJavascriptTextContentFeature))
    {
        domElement.textContent = [[self string] substringWithRange:aRange];
    }
    return domElement;
}

- (BOOL)hasNewline
{
    return _hasNewline;
}
- (_CPTextFragment)divideAtLocation:(int)aLocation
{
      var newRange = CPMakeRange(aLocation, CPMaxRange(_range) - aLocation),
        newFragment = [_CPTextFragment textFragmentWithRange:newRange textStorage:_textStorage];

    [self setRange:CPMakeRange(_range.location, aLocation - _range.location)];
    return newFragment;
}

- (CPArray)glyphsSizes
{
    if (!_glyphsSizes)
    {
        _glyphsSizes = [];
        var fragmentString = [self string],
            c = [fragmentString length];

        for (var i = 0; i < c; i++)
        {
            var size = [_font boundingRectForGlyph:[fragmentString substringWithRange:CPMakeRange(i, 1)]].size;
            _glyphsSizes.push(size);
        }
    }
    return _glyphsSizes;
}

- (CPArray)glyphsFrames
{
    var glyphsFrames = [[CPMutableArray alloc] init],
        c = _textContainerElements.length;
    for (var i = 0; i < c; i++)
    {
        [glyphsFrames addObjectsFromArray:[_textContainerElements[i] glyphsFrames]];
    }
    return glyphsFrames;
}

- (CPRange)rangeForGlyphBoundingWidth:(int)aWidth sweepDirection:(CPLineSweepDirection)sweep startingIndex:(int)startingIndex
{
    if (sweep != CPLineSweepRight)
    {
        CPLog.error(@"FIXME: unsupported CPLineSweepDirection ("+sweep+")");
        return CPMakeRange(startingIndex, 0);
    }
    var sizes = [self glyphsSizes]
        parsedWidth = 0,
        c = sizes.length;
        
    for (var i = startingIndex; i < c; i++)
    {
        parsedWidth += sizes[i].width;
        if (parsedWidth > aWidth && i > 0)
            return CPMakeRange(startingIndex, i-1-startingIndex);
        else
            if (parsedWidth == aWidth)
                return CPMakeRange(startingIndex, i-startingIndex);
    }        
    return CPMakeRange(startingIndex, i-startingIndex);
}

- (CPRange)rangeForGlyphBoundingWidth:(int)aWidth sweepDirection:(CPLineSweepDirection)sweep startingIndex:(int)startingIndex whitespaceBreak:(BOOL)flag
{
    var range = [self rangeForGlyphBoundingWidth:aWidth sweepDirection:sweep startingIndex:startingIndex];
    if (CPEmptyRange(range))
        return range;
    if (flag)
    {
        var whitespaceIndex = [[self string] substringWithRange:range].lastIndexOf(' ');
        if (whitespaceIndex != -1)
            range.length = whitespaceIndex + 1;
    }   
    return range;
}

- (_CPTextContainerLine)layoutLineElementsInTextContainer:(CPTextContainer)aContainer currentLine:(_CPTextContainerLine)aLine
{
    [_textContainerElements makeObjectsPerformSelector:@selector(markDirty)];
    [_textContainerElements removeAllObjects];

    var lineHeight = aLine._frame.size.height,
        fragmentPos = CPPointMake(aLine._frame.origin.x + aLine._frame.size.width, aLine._frame.origin.y);
        
    lineHeight = Math.max(lineHeight, _textSize.height);
    var proposed = CPRectMake(fragmentPos.x, fragmentPos.y, _textSize.width, lineHeight),
        remainingRect = CPRectMakeZero();
    
    var lineRect = [aContainer lineFragmentRectForProposedRect:proposed 
            sweepDirection:CPLineSweepRight movementDirection:CPLineMovesDown remainingRect:remainingRect]; 

    if (CPRectEqualToRect(lineRect, proposed))
    {       
        var containerElement = [_CPTextContainerElement textContainerElementWithFrame:proposed element:[self makeDOMElement]];
        [containerElement setTextFragment:self range:_range];
        [_textContainerElements addObject:containerElement];
        [aLine addElement:containerElement];
        
        if ([self hasNewline])
        {
            [aContainer _appendLine:aLine display:YES];
            aLine = [[_CPTextContainerLine alloc] initWithFrame:CPRectMake(0, fragmentPos.y + lineHeight, 0, _textSize.height)];
        }
    }
    else
    {
        var index = 0,
            finishingLine = YES;
        do {
            var range = [self rangeForGlyphBoundingWidth:lineRect.size.width sweepDirection:CPLineSweepRight startingIndex:index whitespaceBreak:YES],
                rangeSize = [[[self string] substringWithRange:range] sizeWithFont:_font];            
            if (CPEmptyRange(range))
            {
                CPLog.error(_cmd +" FIXME: rangeForGlyphBoundingWidth:"+lineRect.size.width+" sweepDirection:startingIndex:"+index+" return an empty range");
                return aLine;
            }
            lineHeight = Math.max(lineHeight, rangeSize.height);
            proposed = CPRectMake(fragmentPos.x, fragmentPos.y, rangeSize.width, lineHeight);
            remainingRect = CPRectMakeZero();
    
            lineRect = [aContainer lineFragmentRectForProposedRect:proposed sweepDirection:CPLineSweepRight movementDirection:CPLineMovesDown remainingRect:remainingRect]; 
            if (CPRectEqualToRect(lineRect, proposed))
            {
                var containerElement = [_CPTextContainerElement textContainerElementWithFrame:proposed element:[self makeDOMElementForRange:range]];
                [containerElement setTextFragment:self range:CPMakeRange(range.location + _range.location, range.length)];
                                
                [_textContainerElements addObject:containerElement];
                [aLine addElement:containerElement];
                fragmentPos.x = 0;
                fragmentPos.y += lineHeight;
                
                if (finishingLine)
                {
                    fragmentPos.x = 0;
                    fragmentPos.y += lineHeight;
                    lineHeight = rangeSize.height;
                    [aContainer _appendLine:aLine display:YES];
                    aLine = [[_CPTextContainerLine alloc] initWithFrame:CPRectMake(0, fragmentPos.y, 0, lineHeight)];
                    finishingLine = NO;
                }
                else
                {
                    fragmentPos.x += rangeSize.width;
                }
            }
            else {
                CPLog.error(_cmd+" aContainer refused proposed="+CPStringFromRect(proposed)+" lineRect="+CPStringFromRect(lineRect)+ " range="+CPStringFromRange(range));
                return aLine;
            }
            index += range.length;
            lineRect.size.width = [aContainer containerSize].width;
        } while (index != _range.length);
    }
    return aLine;
}
@end

function _textFragmentWithLocation(aList, aLocation)
{
    var i, c = aList.length;
    for (i = 0; i < c; i++)
    {
        if (CPLocationInRange(aLocation, aList[i]._range))
            return aList[i];
    }
    return nil;
}

function _indexOfTextFragmentWithLocation(aList, aLocation)
{
    var i, c = aList.length;
    for (i = 0; i < c; i++)
    {
        if (CPLocationInRange(aLocation, aList[i]._range))
            return i;
    }
    return CPNotFound;
}

function _fragmentsInRange(aList, aRange)
{
    var list = [],
        c = aList.length;
    for (var i = 0; i < c; i++)
    {
        if (CPRangeInRange(aRange, aList[i]._range))
            list.push(aList[i]);
    }
    return list;
}


/*! 
    @ingroup appkit
    @class CPLayoutManager
*/
@implementation CPLayoutManager : CPObject
{
    CPTextStorage _textStorage;
    id _delegate;
    CPMutableArray _textContainers;
    CPMutableArray _textFragments;
}
+(void)initialize
{
    /*
        FIXME: this is wrong.
            but who should give us default attributes ? [CPViextView typingAttributes] ?
    */
    _CPLayoutManagerDefaultAttibutes = [CPDictionary dictionaryWithObjects:[ [CPFont systemFontOfSize:12.0],[CPColor blackColor] ] forKeys: [CPFontAttributeName,CPForegroundColorAttributeName] ];
}
- (id) init
{
    self = [super init];
    if (self)
    {
        _textContainers = [[CPMutableArray alloc] init];
        _textFragments = [[CPMutableArray alloc] init];
    }
    return self;
}

- (void)setTextStorage:(CPTextStorage)textStorage
{
    if (_textStorage === textStorage)
        return;
    _textStorage = textStorage;
}

-(CPTextStorage)textStorage
{
    return _textStorage;
}

- (void)insertTextContainer:(CPTextContainer)aContainer atIndex:(int)index
{
    [_textContainers insertObject:aContainer atIndex:index];
    [aContainer setLayoutManager:self];
}

- (void)addTextContainer:(CPTextContainer)aContainer
{
    [_textContainers addObject:aContainer];
    [aContainer setLayoutManager:self];
}

- (void)removeTextContainerAtIndex:(int)index
{
    var container = [_textContainers objectAtIndex:index];
    [container setLayoutManager:nil];
    [_textContainers removeObjectAtIndex:index];
}

- (CPArray)textContainers
{
    return _textContainers;
}

- (int)numberOfGlyphs
{
    return [_textStorage length];
}

- (CPTextView)firstTextView
{
    return [[_textContainers objectAtIndex:0] textView];
}

- (BOOL)layoutManagerOwnsFirstResponderInWindow:(CPWindow)aWindow
{
    var firstResponder = [aWindow firstResponder],
        c = [_textContainers count];
    for (var i = 0; i < c; i++)
    {
        if ([[_textContainers objectAtIndex:i] textView] === firstResponder)
            return YES;
    }
    return NO;
}

- (CPRect)boundingRectForGlyphRange:(CPRange)aRange inTextContainer:(CPTextContainer)container
{
    var rect = nil,
        parsed = 0;
    do {
        var fragment = _textFragmentWithLocation(_textFragments, aRange.location + parsed);
        if (!fragment)
        {
            return (rect)?rect:CPRectMakeZero();
        }
        
        var frames = nil,
            i = 0,
            c = fragment._textContainerElements.length;
        /* find container element */
        for (var j = 0; j < c; j++)
        {
            if (CPLocationInRange(aRange.location + parsed, fragment._textContainerElements[j]._fragmentRange))
            {
                frames = [fragment._textContainerElements[j] glyphsFrames];
                i = (aRange.location + parsed) - fragment._textContainerElements[j]._fragmentRange.location;
                break;
            }
        }
        
        c = frames.length;
        
        for (; i < c; i++)
        {
            if (!rect)
                rect = CPRectCreateCopy(frames[i]);
            else
                rect = CPRectUnion(rect, frames[i]);
            parsed++;
            if (aRange.length == parsed)
                return rect;
        }
    } while (aRange.length != parsed);
    return rect;
}

- (CPRange)glyphRangeForTextContainer:(CPTextContainer)aTextContainer
{
    return CPMakeRange(0, [self numberOfGlyphs]);
}

/* 
    FIXME: update only specified range
        dirtify and layout only wanted elements.
        Need to review messaging chain :
            textStorage:edited:range:changeInLength:invalidatedRange:
                invalidateLayoutForCharacterRange:isSoft:actualCharacterRange:
                    _coalesceTextFragments
                    _layoutElementsForTextContainer
                invalidateDisplayForGlyphRange:
                    setNeedsLayout
                    setNeedsDisplayInRect:
*/
- (void) _coalesceTextFragments
{
    var current = 0,
        end = _textFragments.length -1;
        
    while (current < end)
    {
        var a = _textFragments[current],
            b = _textFragments[current+1];
            
        if ([a._cachedAttributes isEqualToDictionary:b._cachedAttributes] && ![a hasNewline])
        {
            [a setRange:CPMakeRange(a._range.location, a._range.length + b._range.length)];
            _textFragments.splice(current+1, 1);
            end--;
        }
        else
            current++;
    }
    /* clean empty range fragment if any */
    current = 0;
    end = _textFragments.length;
    while (current < end)
    {
        if (CPEmptyRange(_textFragments[current]._range))
        {
            _textFragments.splice(current, 1);
            end--;
        }
        else current++;
    }
}

- (void)_layoutElementsForTextContainer:(CPTextContainer)container
{
    var line = [[_CPTextContainerLine alloc] initWithFrame:CPRectMake(0, 0, 0, 1)];
    var i, c = _textFragments.length;
    
    for (i = 0; i < c; i++)
        line = [_textFragments[i] layoutLineElementsInTextContainer:container currentLine:line];

    [container _appendLine:line display:YES];
}

- (void)invalidateDisplayForGlyphRange:(CPRange)range
{
    [self _coalesceTextFragments];

    /* as we support only one text container for now */
    var textContainer = [_textContainers objectAtIndex:0];
    
    [[textContainer _containerLines] makeObjectsPerformSelector:@selector(markDirty)];
    
    [self _layoutElementsForTextContainer:textContainer]
    
    var textView = [textContainer textView];
    [textView setNeedsLayout];
    [textView setNeedsDisplay:YES];
}

- (void)invalidateLayoutForCharacterRange:(CPRange)aRange isSoft:(BOOL)flag actualCharacterRange:(CPRangePointer)actualCharRange
{
}

- (void)textStorage:(CPTextStorage)textStorage edited:(unsigned)mask range:(CPRange)charRange changeInLength:(int)delta invalidatedRange:(CPRange)invalidatedRange
{    
    if (mask & CPTextStorageEditedCharacters)
    {
        if (![textStorage length])
        {
            [_textFragments removeAllObjects];
        }
        else
        {
            var textFragment = _textFragmentWithLocation(_textFragments, charRange.location);
            if (textFragment)
            {
                var absRange = CPMakeRange(charRange.location, Math.abs(delta)),
                    locationPlusDelta = charRange.location + delta;
                
                if ( (delta < 0 && ((locationPlusDelta >= textFragment._range.location && CPMaxRange(absRange) <= CPMaxRange(textFragment._range)))
                                    || (Math.abs(delta) <= textFragment._range.length && CPMaxRange(absRange) <= CPMaxRange(textFragment._range)))
                    || (delta >= 0 && (locationPlusDelta < CPMaxRange(textFragment._range))) )
                {
                    [textFragment setRange:CPMakeRange(textFragment._range.location, textFragment._range.length + delta)];

                    var nextIndex = _indexOfTextFragmentWithLocation(_textFragments, CPMaxRange(textFragment._range));
                    if (nextIndex != CPNotFound)
                    {
                        var c = [_textFragments count];
                        for (var i = nextIndex; i < c; i++)
                        {
                            _textFragments[i]._range.location += delta;
                            [_textFragments[i] reset];
                        }
                    }
                }
                else
                {
                    var absRange = CPMakeRange(charRange.location, Math.abs(delta)), 
                        removeSet = [[CPIndexSet alloc] init];

                    [textFragment divideAtLocation:charRange.location];
                    var startIndex = [_textFragments indexOfObject:textFragment],                    
                        i = startIndex+1,
                        c = _textFragments.length;

                    for (; i < c; i++)
                    {
                        if (CPRangeInRange(absRange, _textFragments[i]._range))
                            [removeSet addIndex:i];
                        else if (CPMaxRange(absRange) < CPMaxRange(_textFragments[i]._range))
                        {
                            var newFragment = [_textFragments[i] divideAtLocation:CPMaxRange(absRange)];
                            [_textFragments replaceObjectAtIndex:i withObject:newFragment];
                            break;
                        }
                    }
                    for (; i < c; i++)
                    {
                        _textFragments[i]._range.location += delta;
                        [_textFragments[i] reset];
                    }
                    if ([removeSet count])
                        [_textFragments removeObjectsAtIndexes:removeSet];
                }
            }
            else
            {
                var textFragment = [_CPTextFragment textFragmentWithRange:CPCopyRange(charRange) textStorage:_textStorage],
                    nextIndex = _indexOfTextFragmentWithLocation(_textFragments, CPMaxRange(charRange));
                if (nextIndex == CPNotFound)
                    [_textFragments addObject:textFragment];
                else
                {
                    [_textFragments insertObject:textFragment atIndex:nextIndex];
                    var c = [_textFragments count];
                    for (var i = nextIndex + 1; i < c; i++)
                    {
                        _textFragments[i]._range.location += delta;
                        [_textFragments[i] reset];
                    }
                }
                /* divide text fragment if there's new lines inside */
                var current = textFragment;
                while ([current hasNewline] && ([current string].indexOf('\n') != [current string].length - 1))
                {
                    var newFragment = [current divideAtLocation:[current string].indexOf('\n')+1+current._range.location];
                    [_textFragments insertObject:newFragment atIndex:[_textFragments indexOfObject:current]+1];
                    current = newFragment;
                }
            }
        }
    }
    if (mask & CPTextStorageEditedAttributes)
    {
        var location = invalidatedRange.location,
            length = 0;
        do {
            var textFragmentIndex = _indexOfTextFragmentWithLocation(_textFragments, location);
            if (textFragmentIndex != CPNotFound)
            {
                var textFragment = _textFragments[textFragmentIndex];
                if (CPEmptyRange(invalidatedRange))
                {
                 //   CPLog.trace(_cmd+" invalidatedRange is empty. mask="+mask+" delta="+delta);
                }
                else if (CPRangeInRange(invalidatedRange, textFragment._range))
                {
                    [textFragment reset];
                    location += textFragment._range.length;
                    length += textFragment._range.length;
                }
                else if (location == textFragment._range.location && CPMaxRange(textFragment._range) > CPMaxRange(invalidatedRange))
                {
                    var newFragment = [textFragment divideAtLocation:CPMaxRange(invalidatedRange)];
                    if ([_textFragments count] == textFragmentIndex+1)
                        [_textFragments addObject:newFragment];
                    else
                        [_textFragments insertObject:newFragment atIndex:textFragmentIndex+1];
                    location += textFragment._range.length;
                    length += textFragment._range.length;
                }
                else
                {
                    var newFragment = [textFragment divideAtLocation:location];
                    if ([_textFragments count] == textFragmentIndex+1)
                        [_textFragments addObject:newFragment];
                    else
                        [_textFragments insertObject:newFragment atIndex:textFragmentIndex+1];

                    if (newFragment._range.length < invalidatedRange.length)
                    {
                        location += newFragment._range.length;
                        length += newFragment._range.length;
                    }
                    else
                    {
                        var nextFragment = [newFragment divideAtLocation:location + invalidatedRange.length],
                        newFragmentIndex = [_textFragments indexOfObject:newFragment];

                        if ([_textFragments count] == newFragmentIndex+1)
                            [_textFragments addObject:nextFragment];
                        else
                            [_textFragments insertObject:nextFragment atIndex:newFragmentIndex+1];

                        length = invalidatedRange.length;
                    }
                }
            }
            else break;
        } while (length != invalidatedRange.length);
    }
    [self invalidateDisplayForGlyphRange:invalidatedRange];
}

- (CPRange)glyphRangeForBoundingRect:(CPRect)aRect inTextContainer:(CPTextContainer)container
{    
    var range = CPMakeRange(0,0),
    i, c = [_textFragments count];

    for (i = 0; i < c; i++)
    {
        var fragment = [_textFragments objectAtIndex:i],
            elementsCount = fragment._textContainerElements.length;
        
        for (var j = 0; j < elementsCount; j++)
            if (CGRectContainsRect(aRect, fragment._textContainerElements[j]._displayFrame))
                range = CPUnionRange(range, fragment._textContainerElements[j]._fragmentRange);

        /* FIXME: per glyphs frame */
    }
    return range;
}

- (void)drawBackgroundForGlyphRange:(CPRange)aRange atPoint:(CPPoint)origin
{
    /* FIXME: stub */
}

- (void)drawGlyphsForGlyphRange:(CPRange)aRange atPoint:(CPPoint)origin
{
    [[_textContainers objectAtIndex:0] _displayLinesAtPoint:origin];
 
    var fragmentsToDisplay = _fragmentsInRange(_textFragments, aRange),
        c = fragmentsToDisplay.length;
        
    for (var i = 0; i < c; i++)
        [fragmentsToDisplay[i]._textContainerElements makeObjectsPerformSelector:@selector(display)];
}

- (unsigned)glyphIndexForPoint:(CPPoint)point inTextContainer:(CPTextContainer)container fractionOfDistanceThroughGlyph:(FloatArray)partialFraction
{
    var element = [container _elementAtPoint:point];
    if (element)
    {
        var frames = [element glyphsFrames],
            c = frames.length;
        for (var i = 0; i < c; i++)
        {
            if (CPRectContainsPoint(frames[i], point))
            {
                if (partialFraction)
                    partialFraction[0] = (point.x - frames[i].origin.x) / frames[i].size.width;
                return element._fragmentRange.location + i;
            }
        }
    }
    return CPNotFound;
}

- (unsigned)glyphIndexForPoint:(CPPoint)point inTextContainer:(CPTextContainer)container
{
    return [self glyphIndexForPoint:point inTextContainer:container fractionOfDistanceThroughGlyph:nil];
}

- (void)setTemporaryAttributes:(CPDictionary)attributes forCharacterRange:(CPRange)charRange
{
    /* FIXME: stub */
}

- (void)textContainerChangedTextView:(CPTextContainer)aContainer
{
    /* FIXME: stub */
}
@end
