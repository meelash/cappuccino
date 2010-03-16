/*
 * CPFont.j
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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
 
@import "CPFontDescriptor.j"

var _CPFonts                    = {},
    _CPSystemFontDescriptor     = nil,
    _CPBoldSystemFontDescriptor = nil;

/*! 
    @ingroup appkit
    @class CPFont

    The CPFont class allows control of the fonts used for displaying text anywhere on the screen. The primary method for getting a particular font is through one of the class methods that take a name and/or size as arguments, and return the appropriate CPFont.
*/
@implementation CPFont : CPObject
{
    CPFontDescriptor _fontDescriptor;
    CPString _cssString;
    id _glyphBoundsCache;
}
+ (void) initialize
{
    var masterDescriptor = [CPFontDescriptor fontDescriptorWithName:@"Arial" size:12.0];
    _CPSystemFontDescriptor = [masterDescriptor fontDescriptorWithSymbolicTraits:CPFontSansSerifClass];
    _CPBoldSystemFontDescriptor = [masterDescriptor fontDescriptorWithSymbolicTraits:CPFontSansSerifClass|CPFontBoldTrait];
}
/*!
    Returns a font with the specified name and size.
    @param aName the name of the font
    @param aSize the size of the font (in points)
    @return the requested font
*/
+ (CPFont)fontWithName:(CPString)aName size:(float)aSize
{
    var fontDescriptor = [CPFontDescriptor fontDescriptorWithName:aName size:aSize];
    return _CPFonts[[fontDescriptor cssString]] || [[CPFont alloc] _initWithFontDescriptor:fontDescriptor];
}

/*!
    Returns a font with the specified descriptor and size.
    @param aDescriptor a font descriptor
    @param aSize the size of the font (in points), if \c aSize is 0.0 use descriptor font size, else change to \c aSize
    @return the requested font
*/
+ (CPFont)fontWithDescriptor:(CPFontDescriptor)aDescriptor size:(float)aSize
{
    var fontDescriptor = aDescriptor;
    if (aSize != 0.0)
        fontDescriptor = [fontDescriptor fontDescriptorWithSize:aSize];
    return _CPFonts[[fontDescriptor cssString]] || [[CPFont alloc] _initWithFontDescriptor:fontDescriptor];
}

/*!
    Returns a bold font with the specified name and size.
    @param aName the name of the font
    @param aSize the size of the font (in points)
    @return the requested bold font
*/
+ (CPFont)boldFontWithName:(CPString)aName size:(float)aSize
{
    var fontDescriptor = [[CPFontDescriptor fontDescriptorWithName:aName size:aSize] fontDescriptorWithSymbolicTraits:CPFontBoldTrait];
    return _CPFonts[[fontDescriptor cssString]] || [[CPFont alloc] _initWithFontDescriptor:fontDescriptor];
}

/*!
    Returns the system font scaled to the specified size
    @param aSize the size of the font (in points)
    @return the requested system font
*/
+ (CPFont)systemFontOfSize:(CPSize)aSize
{
    var fontDescriptor = [_CPSystemFontDescriptor fontDescriptorWithSize:aSize];
    return _CPFonts[[fontDescriptor cssString]] || [[CPFont alloc] _initWithFontDescriptor:fontDescriptor];
}

/*!
    Returns the bold system font scaled to the specified size
    @param aSize the size of the font (in points)
    @return the requested bold system font
*/
+ (CPFont)boldSystemFontOfSize:(CPSize)aSize
{
    var fontDescriptor = [_CPBoldSystemFontDescriptor fontDescriptorWithSize:aSize];
    return _CPFonts[[fontDescriptor cssString]] || [[CPFont alloc] _initWithFontDescriptor:fontDescriptor];
}

- (id)_initWithFontDescriptor:(CPFontDescriptor)fontDescriptor
{
    self = [super init];
    if (self)
    {
        _fontDescriptor = fontDescriptor;
        _cssString = [_fontDescriptor cssString];
        _CPFonts[_cssString] = self;
        _glyphBoundsCache = {};
    }
    return self;
}

/*!
    Returns the font size (in points)
*/
- (float)size
{
    return [_fontDescriptor pointSize];
}

/*!
    Returns the font as a CSS string
*/
- (CPString)cssString
{
    return _cssString;
}

/*!
    Returns the font's family name
*/
- (CPString)familyName
{
    return [_fontDescriptor objectForKey:CPFontNameAttribute];
}

/*!
    Returns the font descriptor.
*/
- (CPFontDescriptor)fontDescriptor
{
    return _fontDescriptor;
}

- (BOOL)isEqual:(id)anObject
{
    return [anObject isKindOfClass:[CPFont class]] && [anObject cssString] === [self cssString];
}

- (CPString)description
{
    return [CPString stringWithFormat:@"%@ %@ %f pt.", [super description], [self familyName], [self size]];
}

- (CPRect)boundingRectForGlyph:(CPGlyph)aGlyph
{
    var rect = _glyphBoundsCache[aGlyph];
    if (rect)
        return rect;
    
    var size = [aGlyph sizeWithFont:self];
    rect = CPRectMake(0, 0, size.width, size.height);
    _glyphBoundsCache[aGlyph] = rect;
    return rect;
}
@end

var CPFontDescriptorKey = @"CPFontDescriptorKey";

@implementation CPFont (CPCoding)

/*!
    Initializes the font from a coder.
    @param aCoder the coder from which to read the font data
    @return the initialized font
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [self _initWithFontDescriptor:[aCoder decodeObjectForKey:CPFontDescriptorKey]];
}

/*!
    Writes the font information out to a coder.
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_fontDescriptor forKey:CPFontDescriptorKey];
}
@end
