@import <AppKit/AppKit.j>

@implementation CPFontTest : OJTestCase
{
    CPFont _systemFont;
    CPFont _boldSystemFont;
    
    CPFont _customFont;
    CPFont _boldCustomFont;
}

- (void)setUp
{
    _systemFont = [CPFont systemFontOfSize:15];
    _boldSystemFont = [CPFont boldSystemFontOfSize:15];
    
    _customFont = [CPFont fontWithName:@"Marker Felt, Lucida Grande, Helvetica" size:30];
    _boldCustomFont = [CPFont boldFontWithName:@"Helvetica" size:30];
}

- (void)testSystemFontCSSString
{
    [self assert:[_systemFont cssString] equals:@"normal normal normal 15px Arial, sans-serif"];
}

- (void)testBoldSystemFontCSSString
{
    [self assert:[_boldSystemFont cssString] equals:@"normal normal bold 15px Arial, sans-serif"];
}

- (void)testCustomFontCSSString
{
    [self assert:[_customFont cssString] equals:@"normal normal normal 30px \"Marker Felt\", \"Lucida Grande\", Helvetica"];
}

- (void)testBoldCustomFontCSSString
{
    [self assert:[_boldCustomFont cssString] equals:@"normal normal bold 30px Helvetica"];
}

- (void)testIsEqual
{
    [self assert:_customFont equals:_customFont];
    [self assert:_systemFont equals:_systemFont];
    [self assert:_systemFont notEqual:_customFont];
    [self assert:_customFont notEqual:"a string"];
    [self assert:_customFont notEqual:nil];
}

@end
