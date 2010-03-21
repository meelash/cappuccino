/*
 *  CPText.j
 *  AppKit
 *
 *  Created by Emmanuel Maillard on 28/02/2010.
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
 
CPTextDidBeginEditingNotification = @"CPTextDidBeginEditingNotification";
CPTextDidChangeNotification = @"CPTextDidChangeNotification";
CPTextDidEndEditingNotification = @"CPTextDidEndEditingNotification";

/*! 
    @ingroup appkit
    @class CPText
*/
@implementation CPText : CPView
{
}
- (void)changeFont:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)copy:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)copyFont:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)cut:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)delete:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (CPFont)font:(CPFont)aFont
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return nil;
}
- (BOOL)isHorizontallyResizable
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return NO;
}
- (BOOL)isRichText
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return NO;
}
- (BOOL)isRulerVisible
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return NO;
}
- (BOOL)isVerticallyResizable
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return NO;
}
- (CPSize)maxSize
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return CPMakeSize(0,0);
}
- (CPSize)minSize
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return CPMakeSize(0,0);
}
- (void)paste:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)pasteFont:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)replaceCharactersInRange:(CPRange)aRange withString:(CPString)aString
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)scrollRangeToVisible:(CPRange)aRange
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)selectedAll:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (CPRange)selectedRange
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return CPMakeRange(CPNotFound, 0);
}
- (void)setFont:(CPFont)aFont
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)setFont:(CPFont)aFont rang:(CPRange)aRange
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)setHorizontallyResizable:(BOOL)flag
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)setString:(CPString)aString
{
    [self replaceCharactersInRange:CPMakeRange(0, [[self string] length]) withString:aString];
}
- (void)setUsesFontPanel:(BOOL)flag
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (void)setVerticallyResizable:(BOOL)flag
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (CPString)string
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return nil;
}
- (void)underline:(id)sender
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
}
- (BOOL)usesFontPanel
{
    CPLog.error(@"-[CPText "+_cmd+"] subclass responsibility");
    return NO;
}
@end
