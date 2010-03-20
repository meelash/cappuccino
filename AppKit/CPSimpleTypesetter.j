/*
 *  CPSimpleTypesetter.j
 *  AppKit
 *
 *  Created by Emmanuel Maillard on 17/03/2010.
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

@import "CPTypesetter.j"

var _sharedSimpleTypesetter = nil;

@implementation CPSimpleTypesetter : CPTypesetter
{
    CPLayoutManager _layoutManager; /* current layout manager */
    CPTextContainer _currentTextContainer;
    CPTextStorage _textStorage;
    
    CPRange _attributesRange;
    CPDictionary _currentAttributes;
    CPFont _currentFont;
}
+(id)sharedInstance
{
    if (_sharedSimpleTypesetter === nil)
        _sharedSimpleTypesetter = [[CPSimpleTypesetter alloc] init];
    return _sharedSimpleTypesetter;
}

- (CPLayoutManager)layoutManager
{
    return _layoutManager;
}
- (CPTextContainer)currentTextContainer
{
    return _currentTextContainer;
}
- (CPArray)textContainers
{
    return [_layoutManager textContainers];
}

- (unsigned) _layoutTextFragmentFromGlyphIndex:(unsigned)glyphIndex maxGlyphIndex:(unsigned)maxGlyphIndex
{
    var containerSize = [_currentTextContainer containerSize],
        fragmentRange = CPMakeRange(glyphIndex, 0),
        fragmentWidth = 0,
        nextGlyphIndex = glyphIndex,
        wrapRange = CPMakeRange(0, 0),
        wrapWidth = 0,
        isNewline = NO,
        isWordWrapped = NO;
        
    while ((nextGlyphIndex = CPMaxRange(fragmentRange)) < CPMaxRange(_attributesRange))
    {
        var exitFragment = NO;
        fragmentRange.length++;
        
        var currentChar = [[_textStorage string] characterAtIndex:nextGlyphIndex],
            glyphBound = [_currentFont boundingRectForGlyph:currentChar];
        
        if (currentChar == ' ')
        {
            wrapRange = CPCopyRange(fragmentRange);
            wrapWidth = fragmentWidth;
        }
        else if (currentChar == '\n') /* FIXME: should send actionForControlCharacterAtIndex: */
        {
            isNewline = YES;
            exitFragment = YES;
        }
        
        if (_lineRect.origin.x + fragmentWidth + glyphBound.size.width > containerSize.width)
        {
            if (wrapWidth)
            {
                fragmentRange = wrapRange;
                fragmentWidth = wrapWidth;
            }
            else
            {
                /* FIXME: this is wrong */
                fragmentRange.length--;
            }
            isNewline = YES;
            exitFragment = YES;
            isWordWrapped = YES;
        }
        _lineRect.size.height = Math.max(_lineRect.size.height, glyphBound.size.height);
        fragmentWidth += glyphBound.size.width;
        if (exitFragment)
            break;
    }
    if (fragmentRange.length)
    {
        nextGlyphIndex = CPMaxRange(fragmentRange);
        
        [_layoutManager setTextContainer:_currentTextContainer forGlyphRange:fragmentRange];
        var fragmentRect = CPRectCreateCopy(_lineRect);
        fragmentRect.size.width = fragmentWidth;
        [_layoutManager setLineFragmentRect:_lineRect forGlyphRange:fragmentRange usedRect:fragmentRect];
        [_layoutManager setLocation:_lineRect.origin forStartOfGlyphRange:fragmentRange];
    }
    if (isNewline)
    {    
        _lineRect.origin.x = 0;
        _lineRect.origin.y += _lineRect.size.height;
        _lineRect.size.width = [_currentTextContainer containerSize].width;
        _lineRect.size.height = 0;
        if (!isWordWrapped)
            [_layoutManager setExtraLineFragmentRect:_lineRect usedRect:_lineRect textContainer:_currentTextContainer];
    }
    else
    {
        _lineRect.origin.x += fragmentWidth;
        _lineRect.size.width -= fragmentWidth;
    }
    return nextGlyphIndex;
}

-(void)layoutGlyphsInLayoutManager:(CPLayoutManager)layoutManager startingAtGlyphIndex:(unsigned)glyphIndex
            maxNumberOfLineFragments:(unsigned)maxNumLines nextGlyphIndex:(UIntegerArray)nextGlyph
{
    _layoutManager = layoutManager;
    _textStorage = [_layoutManager textStorage];
    _currentTextContainer = [[_layoutManager textContainers] objectAtIndex: 0];
    _attributesRange = CPMakeRange(0, 0);
    
    /* reset extra line fragment */
    [_layoutManager setExtraLineFragmentRect:CPRectMakeZero() usedRect:CPRectMakeZero() textContainer:nil];

    if (glyphIndex > 0)
    {
        var prevRect = [_layoutManager extraLineFragmentUsedRect];
        if (CGRectEqualToRect(prevRect, CPRectMakeZero()))
        {
            prevRect = [_layoutManager lineFragmentUsedRectForGlyphAtIndex:glyphIndex-1 effectiveRange:nil];
            /*
                FIXME: check new line to avoid a bug while editing the whole next line
            */
            if ([_textStorage._string characterAtIndex:glyphIndex-1] == '\n')
                _lineRect = CPMakeRect(0, prevRect.origin.y + prevRect.size.height, [_currentTextContainer containerSize].width, 0);
            else
                _lineRect = CPMakeRect(prevRect.origin.x + prevRect.size.width, prevRect.origin.y, 
                        [_currentTextContainer containerSize].width - prevRect.size.width, prevRect.size.height);
        }
        else
            _lineRect = CPRectCreateCopy(prevRect);
    }
    else
    {
        _lineRect = CPMakeRect(0, 0, [_currentTextContainer containerSize].width, 0);
    }
    var nextGlyphIndex = glyphIndex,
        maxGlyphIndex = [_textStorage length];

    while (nextGlyphIndex < maxGlyphIndex)
    {
        if (!CPLocationInRange(nextGlyphIndex, _attributesRange))
        {
            _currentAttributes = [_textStorage attributesAtIndex:nextGlyphIndex effectiveRange:_attributesRange];
            _currentFont = [_currentAttributes objectForKey:CPFontAttributeName];
            if (!_currentFont)
                _currentFont = [_textStorage font];
        }
        nextGlyphIndex = [self _layoutTextFragmentFromGlyphIndex:nextGlyphIndex maxGlyphIndex:maxGlyphIndex];
    }
    if (!maxGlyphIndex)
        [_layoutManager setExtraLineFragmentRect:_lineRect usedRect:_lineRect textContainer:_currentTextContainer];
}
@end
