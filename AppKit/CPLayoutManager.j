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
@import "CPTypesetter.j"

function _lineFragmentWithLocation(aList, aLocation)
{
    var i, c = aList.length;
    for (i = 0; i < c; i++)
    {
        if (CPLocationInRange(aLocation, aList[i]._range))
            return aList[i];
    }
    return nil;
}

function _indexOfLineFragmentWithLocation(aList, aLocation)
{
    var i, c = aList.length;
    for (i = 0; i < c; i++)
    {
        if (CPLocationInRange(aLocation, aList[i]._range))
            return i;
    }
    return CPNotFound;
}

function _lineFragmentsInRange(aList, aRange)
{
    var list = [],
        c = aList.length,
        location = aRange.location;

    for (var i = 0; i < c; i++)
    {
        if (CPLocationInRange(location, aList[i]._range))
        {
            list.push(aList[i]);
            if (CPMaxRange(aList[i]._range) <= CPMaxRange(aRange))
                location = CPMaxRange(aList[i]._range);
            else
                break;
        }
    }
    return list;
}

@implementation _CPLineFragment : CPObject
{
    CPRect _fragmentRect;
    CPRect _usedRect;
    CPPoint _location;
    CPRange _range;
    CPTextContainer _textContainer;
    BOOL _isInvalid;
        
    /* attributes caching */
    CPDictionary _attributes;
    CPFont _font;
    CPColor _textColor;
    CPColor _backgroundColor;
    
    /* 'Glyphs' frames */
    CPArray _glyphsFrames;
}
- (id) initWithRange:(CPRange)aRange textContainer:(CPTextContainer)aContainer
{
    self = [super init];
    if (self)
    {
        _fragmentRect = CPRectMakeZero();
        _usedRect = CPRectMakeZero();
        _location = CPPointMakeZero();
        _range = CPCopyRange(aRange);
        _textContainer = aContainer;
        _isInvalid = NO;
    }
    return self;
}
- (CPString)description
{
    return [super description] +
        "\n\t_fragmentRect="+CPStringFromRect(_fragmentRect) +
        "\n\t_usedRect="+CPStringFromRect(_usedRect) +
        "\n\t_location="+CPStringFromPoint(_location) +
        "\n\t_range="+CPStringFromRange(_range);
}
- (CPArray)glyphFramesWithTextStorage:(CPTextStorage)textStorage
{
    if (!_glyphsFrames)
    {
        _glyphsFrames = [];
        var substring = [textStorage._string substringWithRange:_range],
            c = _range.length,
            origin = CPPointMake(_location.x, _location.y);
            
        for (var i = 0; i < c; i++)
        {
            var size = [_font boundingRectForGlyph:substring.charAt(i)].size;
            _glyphsFrames.push(CPRectMake(origin.x, origin.y, size.width, _usedRect.size.height));
            origin.x += size.width;
        }
    }
    return _glyphsFrames;
}
@end

/*! 
    @ingroup appkit
    @class CPLayoutManager
*/
@implementation CPLayoutManager : CPObject
{
    CPTextStorage _textStorage;
    id _delegate;
    CPMutableArray _textContainers;
    CPTypesetter _typesetter;

    CPMutableArray _lineFragments;
    _CPLineFragment _extraLineFragment;
    
    BOOL _isValidatingLayoutAndGlyphs;
    
    CPMutableArray _textFragments;
}
- (id) init
{
    self = [super init];
    if (self)
    {
        _textContainers = [[CPMutableArray alloc] init];
        _textFragments = [[CPMutableArray alloc] init];
        _lineFragments = [[CPMutableArray alloc] init];
        _typesetter = [CPTypesetter sharedSystemTypesetter];
        _isValidatingLayoutAndGlyphs = NO;
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
    return [_textContainers[0] textView];
}

- (BOOL)layoutManagerOwnsFirstResponderInWindow:(CPWindow)aWindow
{
    var firstResponder = [aWindow firstResponder],
        c = [_textContainers count];
    for (var i = 0; i < c; i++)
    {
        if ([_textContainers[i] textView] === firstResponder)
            return YES;
    }
    return NO;
}

- (CPRect)boundingRectForGlyphRange:(CPRange)aRange inTextContainer:(CPTextContainer)container
{
    [self _validateLayoutAndGlyphs];

    var fragments = _lineFragmentsInRange(_lineFragments, aRange),
        rect = nil,
        c = [fragments count];
    for (var i = 0; i < c; i++)
    {
        var fragment = fragments[i];
        if (fragment._textContainer === container)
        {
            var frames = [fragment glyphFramesWithTextStorage:_textStorage];
            for (var j = 0; j < frames.length; j++)
            {
                if (CPLocationInRange(fragment._range.location + j, aRange))
                {
                    if (!rect)
                        rect = CPRectCreateCopy(frames[j]);
                    else
                        rect = CPRectUnion(rect, frames[j]);
                }
            }
        }
    }
    return (rect)?rect:CPRectMakeZero();
}

- (CPRange)glyphRangeForTextContainer:(CPTextContainer)aTextContainer
{
    [self _validateLayoutAndGlyphs];

    var range = nil,
        c = [_lineFragments count];
    for (var i = 0; i < c; i++)
    {
        var fragment = _lineFragments[i];
        if (fragment._textContainer === aTextContainer)
        {
           if (!range)
                range = CPCopyRange(fragment._range);
            else
                range = CPUnionRange(range, fragment._range);
        }
    }
    return (range)?range:CPMakeRange(CPNotFound, 0);
}

- (void)_validateLayoutAndGlyphs
{
    if (_isValidatingLayoutAndGlyphs)
        return;
    _isValidatingLayoutAndGlyphs = YES;
    
    var startIndex = CPNotFound,
        removeRange = CPMakeRange(0,0);

    /* TODO: add an invalid fragment counter instead of checking all fragments */
    if (_lineFragments.length)
    {
        for (var i = 0; i < _lineFragments.length; i++)
        {
            if (_lineFragments[i]._isInvalid)
            {
                startIndex = _lineFragments[i]._range.location;
                removeRange.location = i;
                removeRange.length = _lineFragments.length - i;
                break;
            }
        }
        if (startIndex == CPNotFound && CPMaxRange(_lineFragments[_lineFragments.length - 1]._range) < [_textStorage length])
            startIndex = CPMaxRange(_lineFragments[_lineFragments.length - 1]._range);
    }
    else
        startIndex = 0;

    /* nothing to validate and layout */
    if (startIndex == CPNotFound)
    {
        _isValidatingLayoutAndGlyphs = NO;
        return;
    }
    if (removeRange.length)    
        [_lineFragments removeObjectsInRange:removeRange];

    [_typesetter layoutGlyphsInLayoutManager:self startingAtGlyphIndex:startIndex maxNumberOfLineFragments:0 nextGlyphIndex:nil];
    
    _isValidatingLayoutAndGlyphs = NO;
}

- (void)invalidateDisplayForGlyphRange:(CPRange)range
{    
    var lineFragments = _lineFragmentsInRange(_lineFragments, range);
    for (var i = 0; i < lineFragments.length; i++)
        [[lineFragments[i]._textContainer textView] setNeedsDisplayInRect:lineFragments[i]._usedRect];
}

- (void)invalidateLayoutForCharacterRange:(CPRange)aRange isSoft:(BOOL)flag actualCharacterRange:(CPRangePointer)actualCharRange
{
    var firstFragmentIndex = _indexOfLineFragmentWithLocation(_lineFragments, aRange.location);   
    if (firstFragmentIndex == CPNotFound)
    {
        if (_lineFragments.length)
        {
            firstFragmentIndex = 0;
        }
        else
        {
            if (actualCharRange)
            {
                actualCharRange.length = CPNotFound;
                actualCharRange.location = 0;
            }
            return;
        }
    }
    var fragment = _lineFragments[firstFragmentIndex],
        range = CPCopyRange(fragment._range);
    fragment._isInvalid = YES;
    
    /* FIXME: invalidate all the fragments on the same line */
    
    /* invalidated all fragments that follows */
    for (var i = firstFragmentIndex + 1; i < _lineFragments.length; i++)
    {
        _lineFragments[i]._isInvalid = YES;
        range = CPUnionRange(range, _lineFragments[i]._range);
    }

    if (actualCharRange)
    {
        actualCharRange.length = range.length;
        actualCharRange.location = range.location;
    }
}

- (void)textStorage:(CPTextStorage)textStorage edited:(unsigned)mask range:(CPRange)charRange changeInLength:(int)delta invalidatedRange:(CPRange)invalidatedRange
{    
    var actualRange = CPMakeRange(CPNotFound,0);
    [self invalidateLayoutForCharacterRange:invalidatedRange isSoft:NO actualCharacterRange:actualRange];
    [self invalidateDisplayForGlyphRange:actualRange];
}

- (CPRange)glyphRangeForBoundingRect:(CPRect)aRect inTextContainer:(CPTextContainer)container
{    
    [self _validateLayoutAndGlyphs];

    var range = nil,
        i, c = [_lineFragments count];

    for (i = 0; i < c; i++)
    {
        var fragment = _lineFragments[i];
        if (fragment._textContainer === container)
        {
            var glyphRange = CPMakeRange(CPNotFound,0),
                frames = [fragment glyphFramesWithTextStorage:_textStorage];

            for (var j = 0; j < frames.length; j++)
            {
                if (CPRectIntersectsRect(aRect, frames[j]))
                {
                    if (glyphRange.location == CPNotFound)
                        glyphRange.location = fragment._range.location + j;
                    else
                        glyphRange.length++;
                }
            }
            if (glyphRange.location != CPNotFound)
            {
                if (!range)
                    range = CPCopyRange(glyphRange);
                else
                    range = CPUnionRange(range, glyphRange);
            }
        }
    }
    return (range)?range:CPMakeRange(0,0);
}

- (void)drawBackgroundForGlyphRange:(CPRange)aRange atPoint:(CPPoint)aPoint
{
    [self _validateLayoutAndGlyphs];
    var lineFragments = _lineFragmentsInRange(_lineFragments, aRange);
    if (!lineFragments.length)
        return;

    var ctx = [[CPGraphicsContext currentContext] graphicsPort],
        painted = 0,
        lineFragmentIndex = 0,
        currentFragment = lineFragments[lineFragmentIndex],
        frames = [currentFragment glyphFramesWithTextStorage:_textStorage],
        framesToPaint = Math.min(currentFragment._range.length, aRange.length);

    while (painted != aRange.length)
    {
        CGContextSaveGState(ctx);
        CGContextSetFillColor(ctx, currentFragment._backgroundColor);

        for (var i = 0; i < framesToPaint; i++)
            CGContextFillRect(ctx, CPRectMake(aPoint.x + frames[i].origin.x, aPoint.y + frames[i].origin.y, 
                                    frames[i].size.width, frames[i].size.height));

        CGContextRestoreGState(ctx);

        painted += framesToPaint;
        lineFragmentIndex++;
        if (lineFragmentIndex < lineFragments.length)
        {
            currentFragment = lineFragments[lineFragmentIndex];
            frames = [currentFragment glyphFramesWithTextStorage:_textStorage];
            framesToPaint = Math.min(currentFragment._range.length, aRange.length);
       }
        else
            break;
    }
}

/* 
    FIXME: underline drawing should used [CPLayoutManager underlineGlyphRange:underlineType:lineFragmentRect:lineFragmentGlyphRange:containerOrigin:]
*/
- (void)drawGlyphsForGlyphRange:(CPRange)aRange atPoint:(CPPoint)aPoint
{
    [self _validateLayoutAndGlyphs];
    var lineFragments = _lineFragmentsInRange(_lineFragments, aRange);
    if (!lineFragments.length)
        return;

    var ctx = [[CPGraphicsContext currentContext] graphicsPort],
        painted = 0,
        lineFragmentIndex = 0,
        currentFragment = lineFragments[lineFragmentIndex],
        frames = [currentFragment glyphFramesWithTextStorage:_textStorage];

    var string;
    if (aRange.location < currentFragment._range.location)
        string = [_textStorage._string substringWithRange:CPMakeRange(currentFragment._range.location, Math.min(currentFragment._range.length, aRange.length))],
    else
        string = [_textStorage._string substringWithRange:CPMakeRange(aRange.location, Math.min(currentFragment._range.length, aRange.length))],

    while (painted != aRange.length)
    {            
        CGContextSaveGState(ctx);
        CGContextSetFillColor(ctx, currentFragment._textColor);
        CGContextSetFont(ctx, currentFragment._font);

        var currentFrame = frames[aRange.location + painted - currentFragment._range.location];
        
        CGContextShowTextAtPoint(ctx, aPoint.x + currentFrame.origin.x, aPoint.y + currentFrame.origin.y + currentFrame.size.height, string, string.length);
        CGContextRestoreGState(ctx);

        painted += string.length;
        lineFragmentIndex++;
        if (lineFragmentIndex < lineFragments.length)
        {
            currentFragment = lineFragments[lineFragmentIndex];
            string = [_textStorage._string substringWithRange:CPMakeRange(currentFragment._range.location, Math.min(currentFragment._range.length, aRange.length))];
            frames = [currentFragment glyphFramesWithTextStorage:_textStorage];
        }
        else
            break;
    }
}

- (unsigned)glyphIndexForPoint:(CPPoint)point inTextContainer:(CPTextContainer)container fractionOfDistanceThroughGlyph:(FloatArray)partialFraction
{
    [self _validateLayoutAndGlyphs];

    var c = [_lineFragments count];
    for (var i = 0; i < c; i++)
    {
        var fragment = _lineFragments[i];
        if (fragment._textContainer === container)
        {
            var frames = [fragment glyphFramesWithTextStorage:_textStorage];
            for (var j = 0; j < frames.length; j++)
            {
                if (CPRectContainsPoint(frames[j], point))
                {
                    if (partialFraction)
                        partialFraction[0] = (point.x - frames[j].origin.x) / frames[j].size.width;
                    return fragment._range.location + j;
                }
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

- (CPTypesetter)typesetter
{
    return _typesetter;
}
- (void)setTypesetter:(CPTypesetter)aTypesetter
{
    _typesetter = aTypesetter;
}

- (CPFont)_fontForAttributes:(CPDictionary)attributes
{
    if ([attributes containsKey:CPFontAttributeName])
        return [attributes objectForKey:CPFontAttributeName];
        
    if ([_textStorage font])
        return [_textStorage font];
        
    return [CPFont systemFontWithSize:12.0];
}

- (CPColor)_textColorForAttributes:(CPDictionary)attributes
{
    if ([attributes containsKey:CPForegroundColorAttributeName])
        return [attributes objectForKey:CPForegroundColorAttributeName];
        
    if ([_textStorage foregroundColor])
        return [_textStorage foregroundColor];

    return [CPColor blackColor];
}

- (CPColor)_backgroundColorForAttributes:(CPDictionary)attributes
{
    if ([attributes containsKey:CPBackgroundColorAttributeName])
        return [attributes objectForKey:CPBackgroundColorAttributeName];
        
    /* FIXME: use [[lineFragment._textContainer textView] backgroundColor] as default value if textView is available */
    return [CPColor whiteColor];
}

- (void)setTextContainer:(CPTextContainer)aTextContainer forGlyphRange:(CPRange)glyphRange
{
    var lineFragment = [[_CPLineFragment alloc] initWithRange:glyphRange textContainer:aTextContainer];
    
    lineFragment._attributes = [_textStorage attributesAtIndex:glyphRange.location effectiveRange:nil];
    lineFragment._font = [self _fontForAttributes:lineFragment._attributes];
    lineFragment._textColor = [self _textColorForAttributes:lineFragment._attributes];
    lineFragment._backgroundColor = [self _backgroundColorForAttributes:lineFragment._attributes];

    _lineFragments.push(lineFragment);
}

- (void)setLineFragmentRect:(CPRect)fragmentRect forGlyphRange:(CPRange)glyphRange usedRect:(CPRect)usedRect
{
    var lineFragment = _lineFragmentWithLocation(_lineFragments, glyphRange.location);
    if (lineFragment)
    {
        lineFragment._fragmentRect = CPRectCreateCopy(fragmentRect);
        lineFragment._usedRect = CPRectCreateCopy(usedRect);
    }
}

- (void)setLocation:(CPPoint)aPoint forStartOfGlyphRange:(CPRange)glyphRange
{
    var lineFragment = _lineFragmentWithLocation(_lineFragments, glyphRange.location);
    if (lineFragment)
    {
        lineFragment._location = CPPointCreateCopy(aPoint);
    }
}

- (CPRect)extraLineFragmentRect
{
    if (_extraLineFragment)
        return CPRectCreateCopy(_extraLineFragment._fragmentRect);
    return CPRectMakeZero();
}

- (CPTextContainer)extraLineFragmentTextContainer
{
    if (_extraLineFragment)
        return _extraLineFragment._textContainer;
    return nil;
}

- (CPRect)extraLineFragmentUsedRect
{
    if (_extraLineFragment)
        return CPRectCreateCopy(_extraLineFragment._usedRect);
    return CPRectMakeZero();
}

- (void)setExtraLineFragmentRect:(CPRect)rect usedRect:(CPRect)usedRect textContainer:(CPTextContainer)textContainer
{
    if (textContainer)
    {
        _extraLineFragment = [[_CPLineFragment alloc] initWithRange:CPMakeRange(CPNotFound, 0) textContainer:textContainer];
        _extraLineFragment._fragmentRect = CPRectCreateCopy(rect);
        _extraLineFragment._usedRect = CPRectCreateCopy(usedRect);
    }
    else 
        _extraLineFragment = nil;
}

/*!
    NOTE: will not validate glyphs and layout
*/
- (CPRect)usedRectForTextContainer:(CPTextContainer)textContainer
{
    var rect = nil;
    for (var i = 0; i < _lineFragments.length; i++)
    {
        if (_lineFragments[i]._textContainer === textContainer)
        {
            if (rect)
                rect = CPRectUnion(rect, _lineFragments[i]._usedRect);
            else
                rect = CPRectCreateCopy(_lineFragments[i]._usedRect);
        }
    }
    return (rect)?rect:CPRectMakeZero();
}

- (CPRect)lineFragmentRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(CPRangePointer)effectiveGlyphRange
{
    [self _validateLayoutAndGlyphs];
    
    var lineFragment = _lineFragmentWithLocation(_lineFragments, glyphIndex);
    if (!lineFragment)
        return CPRectMakeZero();
 
    if (effectiveGlyphRange)
    {
        effectiveGlyphRange.location = lineFragment._range.location;
        effectiveGlyphRange.length = lineFragment._range.length;
    }
    return CPRectCreateCopy(lineFragment._fragmentRect);
}

- (CPRect)lineFragmentUsedRectForGlyphAtIndex:(unsigned)glyphIndex effectiveRange:(CPRangePointer)effectiveGlyphRange
{
    [self _validateLayoutAndGlyphs];
    
    var lineFragment = _lineFragmentWithLocation(_lineFragments, glyphIndex);
    if (!lineFragment)
        return CPRectMakeZero();

    if (effectiveGlyphRange)
    {
        effectiveGlyphRange.location = lineFragment._range.location;
        effectiveGlyphRange.length = lineFragment._range.length;
    }
    return CPRectCreateCopy(lineFragment._usedRect);
}

- (CPPoint)locationForGlyphAtIndex:(unsigned)index
{
    [self _validateLayoutAndGlyphs];
    var lineFragment = _lineFragmentWithLocation(_lineFragments, index);
    if (lineFragment)
    {
        if (index == lineFragment._range.location)
            return CPPointCreateCopy(lineFragment._location);
            
        var glyphFrames = [lineFragment glyphFramesWithTextStorage:_textStorage];
        return CPPointCreateCopy(glyphFrames[index - lineFragment._range.location].origin);
    }
    return CPPointMakeZero();
}
@end
