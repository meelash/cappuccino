/*
 *  CTFont.j
 *  CoreText
 *
 *  Created by Emmanuel Maillard on 25/03/10.
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
@import <AppKit/CGPath.j>
@import <AppKit/CPFont.j>
@import "CTFontManager.j"

var _CPFontGlyphBase = 1;

@implementation CTFont : CPFont
{   
    unsigned _glyphBase;
    int _pointSize;
    _CTFontMetrics _fontMetrics;
    CGAffineTransform _sizeMatrix;
    CGAffineTransform _transformMatrix;
    
    float _xHeight;
    float _capHeight;
}
- (id)_initWithFontDescriptor:(CPFontDescriptor)fontDescriptor
{
    self = [super _initWithFontDescriptor:fontDescriptor];
    if (self)
    {
        try {
            _pointSize = [_fontDescriptor pointSize];
            _glyphBase = _CPFontGlyphBase;
            _fontMetrics = [[CTFontManager sharedFontManager] fontMetricsForFontFamily:[_fontDescriptor objectForKey:CPFontNameAttribute]];
            _CPFontGlyphBase += _fontMetrics._glyphs.length;
            
            var scale = 1.0 / _fontMetrics._unitsPerEm * _pointSize;
            _sizeMatrix = CGAffineTransformMakeScale(scale, scale);
            _transformMatrix = NULL;
        }
        catch(e) {
            CPLog.debug(_cmd+ " raised:" +e);
            return nil;
        }
    }
    return self;
}

- (float)ascender
{
    return [_fontMetrics ascentWithSize:_pointSize];
}

- (float)descender
{
    return [_fontMetrics descentWithSize:_pointSize];
}

- (float)xHeight
{
    if (_xHeight)
        return _xHeight;
    
    var xGlyph = [_fontMetrics glyphWithUnicode:@"x"] + _glyphBase,
        xBound = [self boundingRectForGlyph:xGlyph];
    _xHeight = xBound.size.height;
    return _xHeight;
}

- (float)capHeight
{
    if (_capHeight)
        return _capHeight;
    
    var glyph = [_fontMetrics glyphWithUnicode:@"H"] + _glyphBase,
        bound = [self boundingRectForGlyph:glyph];
    _capHeight = bound.size.height;
    return _capHeight;
}

- (CPSize)advancementForGlyph:(CPGlyph)glyph
{
    if (glyph === CPNullGlyph)
        return [_fontMetrics advancementForGlyph:CPNullGlyph withSize:_pointSize];
    return [_fontMetrics advancementForGlyph:(glyph - _glyphBase) withSize:_pointSize];
}

- (CPRect)boundingRectForGlyph:(CPGlyph)aGlyph
{
    var rect = _glyphBoundsCache[aGlyph];
    if (rect)
        return rect;
    
    if (aGlyph === CPNullGlyph)
    {
        var size = [_fontMetrics advancementForGlyph:CPNullGlyph withSize:_pointSize];
        rect = CPRectMake(0, 0, size.width, size.height);
    }
    else
    {
        rect = [_fontMetrics boundingRectForGlyph:(aGlyph - _glyphBase) withSize:_pointSize];
    }
    _glyphBoundsCache[aGlyph] = rect;
    return rect;
}

- (float)underlinePosition
{
    return [_fontMetrics underlinePositionWithSize:_pointSize];
}
@end

/*!
    Returns the scaled font ascent of the given font.
*/
function CTFontGetAscent(/* CTFont */font)
{
    return [font ascender];
}

/*!
    Returns the scaled font descent of the given font.
*/
function CTFontGetDescent(/* CTFont */font)
{
    return [font descender];
}

/*!
    Returns the units-per-em of the given font.
*/
function CTFontGetUnitsPerEm(/* CTFont */font)
{
    return font._fontMetrics._unitsPerEm;
}

/*!
    Returns the number of glyphs of the given font.
*/
function CTFontGetGlyphCount(/* CTFont */font)
{
    return font._fontMetrics._glyphs.length;
}

function CTFontGetGlyphsForCharacters(/* CTFont */font, /* CPString */characters, /* CPArray */glyphs, /*IntPointer*/count)
{
    var c = characters.length,
        glyphCount = 0;
    for (var i = 0; i < c; i++)
    {
        var glyphFound = [font._fontMetrics glyphWithUnicode:characters.charAt(i)];
        if (glyphFound != CPNullGlyph)
        {
            glyphs.push((glyphFound + font._glyphBase));
            glyphCount++;
        }
        else
        {
            glyphs.push(CPNullGlyph);
        }
    }
    if (count)
        count[0] = glyphs.length;
    return (glyphCount == characters.length);
}

function CTFontGetGlyphWithName(/* CTFont */font, /* CPString */glyphName)
{
    var glyph = [font._fontMetrics glyphWithName:glyphName];
    if (glyph !== CPNullGlyph)
        return glyph + font._glyphBase;
    return CPNullGlyph;
}

function CTFontGetLeading(/* CTFont */font)
{
    /* TODO: */ 
    return 0.0;
}

function CTFontGetUnderlinePosition(/* CTFont */font)
{
    return [font underlinePosition];
}

function CTFontCreatePathForGlyph(/* CTFont */font, /* CPGlyph */glyph, /* CGAffineTransform */transform)
{
    if (glyph === CPNullGlyph) /* FIXME: missing-glyph path ? */
        return NULL;

    var g = glyph - font._glyphBase;
    if (g < 0 || g >= font._fontMetrics._glyphs.length)
        return NULL;
    
    var path = [font._fontMetrics._glyphs[g] pathWithSizeMatrix:font._sizeMatrix];    
    if (!path)
        return NULL;
    /* 
        FIXME: we need to apply transform matrix of font too
        before the given transform.
    */
    if (!transform)
        return path;

    var transformedPath = CGPathCreateMutable();
    CGPathAddPath(transformedPath, transform, path);

    return transformedPath;
}

function CTFontGetMatrix(font)
{
    return font._matrix;
}

function CTFontGetSize(font)
{
    return [font size];
}

function CTFontGetSymbolicTraits(/* CTFont */font)
{
    return [[font fontDescriptor] symbolicTraits];
}

function CTFontGetCapHeight(/* CTFont */ font)
{
    return [font capHeight];
}

function CTFontGetXHeight(/* CTFont */font)
{
    return [font xHeight];
}
