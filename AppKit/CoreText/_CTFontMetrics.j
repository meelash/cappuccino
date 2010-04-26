/*
 *  _CTFontMetrics.j
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

@import "_CTGlyph.j"

/* Should used [CPCharacterSet controlCharacterSet] */
var _controlCharacterRangeL = CPMakeRange(0, 32),
    _controlCharacterRangeH = CPMakeRange(127, 33);

#define _isControlCharacter(cc) ((CPLocationInRange(cc, _controlCharacterRangeL)) || (CPLocationInRange(cc, _controlCharacterRangeH)))

@implementation _CTFontMetrics : CPObject
{
    SVGFontFaceElement _fontFaceElement;

    int _horizAdvX;
    int _ascent;
    int _descent;
    int _unitsPerEm;
    CPMutableArray _glyphs;

    int _xHeight;
    int _capHeight;
}

- (id)initWithFontID:(CPString)aFontID
{
    self = [super init];
    if (self)
    {
        var objectElement = document.getElementById(aFontID),
            svgElement = objectElement.contentDocument,
            fontElement = svgElement.getElementsByTagName("font"),
            fontFace = svgElement.getElementsByTagName("font-face");

        _fontFaceElement = fontFace[0];

        _horizAdvX = parseInt(fontElement[0].getAttribute("horiz-adv-x"), 10);

        _unitsPerEm = parseInt(_fontFaceElement.getAttribute("units-per-em"), 10);
        _ascent = parseInt(_fontFaceElement.getAttribute("ascent"), 10);
        _descent = parseInt(_fontFaceElement.getAttribute("descent"), 10);

        _glyphs = [[CPMutableArray alloc] init];

        /* add missing-glyph first */
        var missingGlyph = svgElement.getElementsByTagName("missing-glyph");
        [_glyphs addObject:[[_CTGlyph alloc] initWithSVGGlyphElement:missingGlyph[0] advancement:_horizAdvX]];

        var svgGlyphs = svgElement.getElementsByTagName("glyph");
        for (var i = 0; i < svgGlyphs.length; i++)
            [_glyphs addObject:[[_CTGlyph alloc] initWithSVGGlyphElement:svgGlyphs[i] advancement:_horizAdvX]];
    }
    return self;
}

- (CPString) description
{
    return [super description] + "\n\t_horizAdvX="+_horizAdvX
        + "\n\t_ascent="+_ascent
        + "\n\t_descent="+_descent
        + "\n\t_unitsPerEm="+_unitsPerEm
        + "\n\t_glyphs="+[_glyphs description];
}

- (float)ascentWithSize:(float)size
{
    return (1.0 / _unitsPerEm * _ascent * size);
}

- (float)descentWithSize:(float)size
{
    return (1.0 / _unitsPerEm * _descent * size);
}

- (CPSize)advancementForGlyph:(CPGlyph)glyph withSize:(float)pointSize
{
    return CPMakeSize((1.0 / _unitsPerEm * pointSize * _glyphs[glyph]._horizAdvX), 0);
}

- (float)maxAdvancementWithSize:(float)size
{
    return (1.0 / _unitsPerEm * _horizAdvX * size);
}

- (CPGlyph)glyphWithUnicode:(CPString)unicode
{
    /* check for control glyph */
   if (_isControlCharacter(unicode.charCodeAt(0)))
        return CPControlGlyph;

    var c = _glyphs.length;
    for (var i = 1; i < c; i++)
    {
        if ([_glyphs[i] unicode] === unicode)
            return i;
    }
    return CPNullGlyph;
}

- (CPGlyph)glyphWithName:(CPString)glyphName
{
    var c = _glyphs.length;
    for (var i = 1; i < c; i++)
    {
        if ([_glyphs[i] glyphName] === glyphName)
            return i;
    }
    /* Possible CPControlGlyph ? with which name ?? */
    return CPNullGlyph;
}

- (CPRect)boundingRectForGlyph:(CPGlyph)aGlyph withSize:(float)size
{
    var bbox = [_glyphs[aGlyph] boundingBox],
        scale = (1.0 / _unitsPerEm * size);
    bbox.origin.x *= scale;
    bbox.origin.y *= scale;
    bbox.size.width *= scale;
    bbox.size.height *= scale;
    return bbox;
}

- (float)underlinePositionWithSize:(float)size
{
    if (_fontFaceElement.getAttribute("underline-position"))
        return (1.0 / _unitsPerEm * size * parseInt(_fontFaceElement.getAttribute("underline-position"), 10));

    /* Not correct but should be not so bad */
    return [self descentWithSize:size] / 2.0;
}
@end
