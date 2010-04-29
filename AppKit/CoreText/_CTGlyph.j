/*
 *  _CTGlyph.j
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

@import <Foundation/CPObject.j>
@import <AppKit/CGPath.j>

var _commandsRegExp = new RegExp("([a-zA-Z]\w*[0-9\-\. ]+)|([zZ])", "g");
var _valueRegExp = new RegExp("([0-9\-\.]+)", "g");

var _CTParseValues = function(cmd)
{
    var values = [],
        v;
    while ( (v = _valueRegExp.exec(cmd)) )
        values.push(v);
    return values;
}

@implementation _CTGlyph : CPObject
{
    SVGGlyphElement _SVGGlyphElement;

    int _horizAdvX;
    /*
        the path will be build on demand (then cached in glyph coordinate unit)
        cf : CTFontCreatePathForGlyph
            (NSGlyphGenerator will use CTFontCreatePathForGlyph)
        or for bbox.
    */
    CGPath _path;
    /*
        bounding box will be delayed too, because we will need _path to compute it.
    */
    CPRect _bbox;
}

/*
    @param aGlyphElement The DOM SVGGlyphElement that the instance represent.
    @param defaultAdvancement default glyph advancement provide by font metrics. Used only if the glyph doesn't have horiz-adv-x attribute.
*/
- (id) initWithSVGGlyphElement:(SVGGlyphElement)aGlyphElement advancement:(int)defaultAdvancement
{
    self = [super init];
    if (self)
    {
        _SVGGlyphElement = aGlyphElement;
        if (_SVGGlyphElement.getAttribute("horiz-adv-x"))
            _horizAdvX = parseInt(_SVGGlyphElement.getAttribute("horiz-adv-x"), 10);
        else
            _horizAdvX = defaultAdvancement;
    }
    return self;
}

-(CPString)glyphName
{
    return _SVGGlyphElement.getAttribute("glyph-name");
}

-(CPString)unicode
{
    return _SVGGlyphElement.getAttribute("unicode");
}

- (int)horizontalAdvancement
{
    return _horizAdvX;
}

- (CPString)pathData
{
    return _SVGGlyphElement.getAttribute("d");
}

- (CPRect)boundingBox
{
    if (_bbox)
        return _bbox;

    var path = [self pathWithSizeMatrix:NULL];
    _bbox = CGPathGetBoundingBox(path);
    return _bbox;
}

- (CGPath)pathWithSizeMatrix:(CGAffineTransform)transform
{
    var pathData = [self pathData];
    if (!pathData && !_path)
        _path = CGPathCreateMutable(); // No path data (space) just create an empty path

    if (!_path)
    {
        _path = CGPathCreateMutable();

        var commands = [],
            cmd;

        while ( (cmd = _commandsRegExp.exec(pathData)) )
            commands.push(cmd);

        var lastCmd,
            lastPoint = CPMakePoint(0,0),
            lastControlPoint = CPMakePoint(0,0),
            x, y, cx, cy;

        /* FIXME: any relative coordinates possible in a glyph path ?? */
        for (var i = 0; i < commands.length; i++)
        {
            cmd = commands[i][0][0];
            var values;
            switch (cmd)
            {
                case 'M':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 2)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];
                    /* FIXME: multiple pairs of coordinates -> LineTo */
                    x = parseFloat(values[0][0]);
                    y = parseFloat(values[1][0]);
                    lastPoint.x = x;
                    lastPoint.y = y;

                    CGPathMoveToPoint(_path, NULL, x, y);
                    break;

                case 'L':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 2)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];

                    for (var j = 0; j < values.length; j += 2)
                    {
                        x = parseFloat(values[0][0]);
                        y = parseFloat(values[1][0]);
                        lastPoint.x = x;
                        lastPoint.y = y;

                        CGPathAddLineToPoint(_path, NULL, x, y);
                    }
                    break;

                case 'l':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 2)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];

                    for (var j = 0; j < values.length; j += 2)
                    {
                        x = parseFloat(values[0][0]) + lastPoint.x;
                        y = parseFloat(values[1][0]) + lastPoint.y;
                        lastPoint.x = x;
                        lastPoint.y = y;

                        CGPathAddLineToPoint(_path, NULL, x, y);
                    }
                    break;

                case 'H':
                case 'V':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 1)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];

                    x = parseFloat(values[0][0]);

                    if (cmd == 'H')
                    {
                        CGPathAddLineToPoint(_path, NULL, x, lastPoint.y);
                        lastPoint.x = x;
                    }
                    else
                    {
                        CGPathAddLineToPoint(_path, NULL, lastPoint.x, x);
                        lastPoint.y = x;
                    }
                    break;

                case 'h':
                case 'v':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 1)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];

                    x = parseFloat(values[0][0]);

                    if (cmd == 'h')
                    {
                        CGPathAddLineToPoint(_path, NULL, x + lastPoint.x, lastPoint.y);
                        lastPoint.x = x + lastPoint.x;
                    }
                    else
                    {
                        CGPathAddLineToPoint(_path, NULL, lastPoint.x, x + lastPoint.y);
                        lastPoint.y = x + lastPoint.y;
                    }
                    break;

                case 'Q':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 4)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];

                    for (var j = 0; j < values.length; j += 4)
                    {
                        cx = parseFloat(values[0][0]);
                        cy = parseFloat(values[1][0]);

                        x = parseFloat(values[2][0]);
                        y = parseFloat(values[3][0]);

                        lastPoint.x = x;
                        lastPoint.y = y;
                        lastControlPoint.x = cx;
                        lastControlPoint.y = cy;

                        CGPathAddQuadCurveToPoint(_path, NULL, cx, cy, x, y);
                    }
                    break;

                case 'q':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 4)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];

                    for (var j = 0; j < values.length; j += 4)
                    {
                        cx = parseFloat(values[0][0]) + lastPoint.x;
                        cy = parseFloat(values[1][0]) + lastPoint.y;

                        x = parseFloat(values[2][0]) + lastPoint.x;
                        y = parseFloat(values[3][0]) + lastPoint.y;

                        lastPoint.x = x;
                        lastPoint.y = y;
                        lastControlPoint.x = cx;
                        lastControlPoint.y = cy;

                        CGPathAddQuadCurveToPoint(_path, NULL, cx, cy, x, y);
                    }
                    break;

                case 'T':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 2)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];

                    for (var j = 0; j < values.length; j += 2)
                    {
                        x = parseFloat(values[0][0]);
                        y = parseFloat(values[1][0]);

                        if (lastCmd && (lastCmd === 'Q' || lastCmd === 'T'))
                        {
                            lastPoint.x = x;
                            lastPoint.y = y;

                            CGPathAddQuadCurveToPoint(_path, NULL, lastControlPoint.x, lastControlPoint.y, x, y);
                        }
                        else
                        {                        
                            CGPathAddQuadCurveToPoint(_path, NULL, x, y, x, y);
                            lastPoint.x = x;
                            lastPoint.y = y;
                            lastControlPoint.x = x;
                            lastControlPoint.y = y;
                        }
                    }
                    break;    

                case 't':
                    values = _CTParseValues(commands[i][0]);
                    if (values.length < 2)
                        [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] incorrect data"];

                    for (var j = 0; j < values.length; j += 2)
                    {
                        x = parseFloat(values[0][0]) + lastPoint.x;
                        y = parseFloat(values[1][0]) + lastPoint.y;

                        if (lastCmd && (lastCmd === 'q' || lastCmd === 't'))
                        {
                            lastPoint.x = x;
                            lastPoint.y = y;

                            CGPathAddQuadCurveToPoint(_path, NULL, lastControlPoint.x, lastControlPoint.y, x, y);
                        }
                        else
                        {                        
                            CGPathAddQuadCurveToPoint(_path, NULL, x, y, x, y);
                            lastPoint.x = x;
                            lastPoint.y = y;
                            lastControlPoint.x = x;
                            lastControlPoint.y = y;
                        }
                    }
                    break; 

                case 'z':
                case 'Z':
                    CGPathCloseSubpath(_path);    
                    break;
                default:
                    [CPException raise:@"CoreText Exception" reason:@"-[_CTGlyph path] unknown command : "+cmd];
                    break;
            }
            lastCmd = cmd;
        }
    }
    var path = CGPathCreateMutable();
    CGPathAddPath(path, transform, _path);
    return path;
}

- (CPString) description
{
    return [super description] + "\n\t_horizAdvX="+_horizAdvX
        + "\n\tglyphName="+[self glyphName]
        + "\n\tunicode="+[self unicode]
        + "\n\tpathData="+[self pathData];
}
@end
