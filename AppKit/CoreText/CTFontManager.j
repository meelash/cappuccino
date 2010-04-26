/*
 *  CTFontManager.j
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
@import "_CTFontMetrics.j"

var _sharedFontManager = nil;

@implementation CTFontManager : CPFontManager
{
    CPMutableDictionary _registeredFonts;   /* key font id - value font family */
    CPMutableDictionary _fontMetrics;       /* key font family - value corresponding _CTFontMetrics */
}
+ (CTFontManager)sharedFontManager
{
    if (!_sharedFontManager)
        _sharedFontManager = [[CTFontManager alloc] init];
    return _sharedFontManager;
}
- (id) init
{
    self = [super init];
    if (self)
    {
        _registeredFonts = [[CPMutableDictionary alloc] init];
        _fontMetrics = [[CPMutableDictionary alloc] init];
    }
    return self;
}

- (void) _didLoadFontWithID:(CPString)sourceFile
{
    var objectElement = document.getElementById(sourceFile),
        fontFace = objectElement.contentDocument.getElementsByTagName("font-face");

    [_registeredFonts setObject:[CPString stringWithString:fontFace[0].getAttribute("font-family")] forKey:sourceFile];
}

- (void)registerFontWithContentsOfFile:(CPString)aFile
{
    var sourceFile = [aFile lastPathComponent];

    if ([[sourceFile pathExtension] caseInsensitiveCompare:@"svg"] == CPOrderedSame)
    {        
        var objectElement = document.createElement("object");
        objectElement.data = aFile;
        objectElement.id = sourceFile;
        objectElement.type ="image/svg+xml";
        objectElement.className = "cpdontremove";
        objectElement.setAttribute("style", "top:-1000px; left:-1000px; width:1px; height:1px;");

        objectElement.onload = function() { [self _didLoadFontWithID:sourceFile]; };

        [CPPlatform mainBodyElement].appendChild(objectElement);
    }
    else
    {
        [CPException raise:@"CoreText Exception" reason:@"Unsupported file format: "+[sourceFile pathExtension]];
    }
}

- (CPArray)createFontDescriptorsFromFile:(CPString)aFile
{
    var filename = [aFile lastPathComponent];
    if ([_registeredFonts containsKey:filename]) /* FIXME: this should create font descriptors for traits that can be used with the font */
        return [
            [CPFontDescriptor fontDescriptorWithFontAttributes:
                [CPDictionary dictionaryWithObject:[_registeredFonts objectForKey:filename] forKey:CPFontNameAttribute]]
            ];
    return nil;
}

- (CPArray)availableFonts
{
    var availableFonts = [_registeredFonts allValues];
    [availableFonts sortUsingSelector:@selector(compare:)];
    return availableFonts;
}

- (BOOL)hasRegisteredFontFile:(CPString)aFile
{
    return [_registeredFonts containsKey:[aFile lastPathComponent]];
}

- (_CTFontMetrics)fontMetricsForFontFamily:(CPString)fontFamily
{
    if ([_fontMetrics containsKey:fontFamily])
        return [_fontMetrics objectForKey:fontFamily];

    var fontID = nil,
        enumerator = [_registeredFonts keyEnumerator],
        nextObject = nil;
    /* lookup font ID for font family */
    while ( (nextObject = [enumerator nextObject]) )
    {
        if ([[_registeredFonts objectForKey:nextObject] isEqual:fontFamily])
        {
            fontID = nextObject;
            break;
        }
    }

    if (!fontID)
        [CPException raise:@"CoreText Exception" reason:@"Unregistered font family: "+fontFamily];

    var fontMetrics = [[_CTFontMetrics alloc] initWithFontID:fontID];
    [_fontMetrics setObject:fontMetrics forKey:fontFamily];
    return fontMetrics;
}
@end

kCTFontManagerErrorUnrecognizedFormat = 103;
kCTFontManagerErrorAlreadyRegistered = 105;

function CTFontManagerRegisterFontsForURL(/*CPURL*/fontURL, /* int (unused) */scope, /* IntArray */error)
{
    var result,
        file = [fontURL absoluteString],
        fontManager = [CTFontManager sharedFontManager];

    if ([fontManager hasRegisteredFontFile:file])
    {
        if (error)
            error[0] = kCTFontManagerErrorAlreadyRegistered;
        return NO;
    }
    try {
        [fontManager registerFontWithContentsOfFile:file];
        result = YES;
    }
    catch(e)
    {
        if (error)
            error[0] = kCTFontManagerErrorUnrecognizedFormat;
        result = NO;
    }
    return result;
}

function CTFontManagerRegisterFontsForURLs(/* CPArray */fontURLs, /* int (unused) */scope, /* IntArray */errors)
{
    var registerCount = 0;
    for (var i = 0; i < fontURLs.length; i++)
    {
        var status = [];
        if (CTFontManagerRegisterFontsForURL(fontURLs[i], scope, status))
        {
            registerCount++;
            if (errors)
                errors[i] = 0;
        }
        else
        {
            if (errors)
                errors[i] = status[0];
        }
    }
    return (registerCount == fontURLs.length);
}

function CTFontManagerCreateFontDescriptorsFromURL(/* CPURL */fontURL) 
{
    return [[CTFontManager sharedFontManager] createFontDescriptorsFromFile:[fontURL absoluteString]];
}

function CTFontManagerIsSupportedFont(/* CPURL */fontURL)
{
    return ([[[fontURL absoluteString] pathExtension] caseInsensitiveCompare:@"svg"] == CPOrderedSame);
}
