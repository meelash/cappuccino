@import <AppKit/CPFontDescriptor.j>

@implementation CPFontDescriptorTest : OJTestCase
{
    CPDictionary attributes;
}
- (void)setUp
{
    attributes = [CPDictionary dictionaryWithObjects:[@"Arial",@"12.0"] forKeys:[CPFontNameAttribute,CPFontSizeAttribute]];
}
- (void) testInitWithFontAttributes
{
    var fontDescriptor = [[CPFontDescriptor alloc] initWithFontAttributes:nil];
    [self assertNotNull:fontDescriptor];
    [self assertNotNull:[fontDescriptor fontAttributes]];
    [self assert:[[[fontDescriptor fontAttributes] allKeys] count] equals:0];
    
    fontDescriptor = [[CPFontDescriptor alloc] initWithFontAttributes:attributes];
    [self assertNotNull:fontDescriptor];
    [self assertTrue:[[fontDescriptor fontAttributes] isEqualToDictionary:[attributes copy]]];
}

- (void)testFontDescriptorWithName
{
    var fontDescriptor = [CPFontDescriptor fontDescriptorWithName:@"Arial" size:12.0];
    [self assertNotNull:fontDescriptor];
    [self assertNotNull:[fontDescriptor fontAttributes]];
    [self assert:[[[fontDescriptor fontAttributes] allKeys] count] equals:2];
    
    var value = [fontDescriptor objectForKey:CPFontNameAttribute];
    [self assertNotNull:value];
    [self assertTrue:[value isKindOfClass:[CPString class]]];
    [self assertTrue:(value === @"Arial")];
    
    value = [fontDescriptor objectForKey:CPFontSizeAttribute];
    [self assertNotNull:value];
    [self assertTrue:[value isKindOfClass:[CPString class]]];
    [self assert:[value floatValue] equals:12.0];
    
    fontDescriptor = [CPFontDescriptor fontDescriptorWithName:@"Marker Felt" size:12.0];
    [self assert:[fontDescriptor fontFamilyCSSString] equals:@"\"Marker Felt\""];

    fontDescriptor = [CPFontDescriptor fontDescriptorWithName:@"Marker Felt, Lucida Grande, Helvetica" size:12.0];
    [self assert:[fontDescriptor fontFamilyCSSString] equals:@"\"Marker Felt\", \"Lucida Grande\", Helvetica"];
}
- (CPFontDescriptor)testFontDescriptorByAddingAttributes
{
    var additionalAttributes = [CPDictionary dictionaryWithObjects:[@"Helvetica",[CPDictionary dictionaryWithObject:@"400" forKey:CPFontWeightTrait]] forKeys:[CPFontNameAttribute,CPFontTraitsAttribute]],
        fontDescriptor = [[CPFontDescriptor alloc] initWithFontAttributes:attributes],
        newDescriptor = [fontDescriptor fontDescriptorByAddingAttributes:additionalAttributes];

    /* original still the same */
    [self assertTrue:[[fontDescriptor fontAttributes] isEqualToDictionary:[attributes copy]]];

    [self assertNotNull:newDescriptor];
    [self assert:[[[newDescriptor fontAttributes] allKeys] count] equals:3];

    var value = [newDescriptor objectForKey:CPFontNameAttribute];
    [self assertNotNull:value];
    [self assertTrue:[value isKindOfClass:[CPString class]]];
    [self assertTrue:(value === @"Helvetica")];
    
    value = [newDescriptor objectForKey:CPFontSizeAttribute];
    [self assertNotNull:value];
    [self assertTrue:[value isKindOfClass:[CPString class]]];
    [self assert:[value floatValue] equals:12.0];
    
    value = [newDescriptor objectForKey:CPFontTraitsAttribute];
    [self assertNotNull:value];
    [self assertTrue:[value isKindOfClass:[CPDictionary class]]];
    [self assertTrue:([value objectForKey:CPFontWeightTrait] === @"400")];
}
- (void)testFontDescriptorWithSize
{
    var fontDescriptor = [[CPFontDescriptor alloc] initWithFontAttributes:attributes],
        newDescriptor = [fontDescriptor fontDescriptorWithSize:18.0];
    
    /* original still the same */
    [self assertTrue:[[fontDescriptor fontAttributes] isEqualToDictionary:[attributes copy]]];

    [self assertNotNull:newDescriptor];
        
    var value = [newDescriptor objectForKey:CPFontNameAttribute];
    [self assertNotNull:value];
    [self assertTrue:[value isKindOfClass:[CPString class]]];
    [self assertTrue:(value === @"Arial")];
    
    value = [newDescriptor objectForKey:CPFontSizeAttribute];
    [self assertNotNull:value];
    [self assertTrue:[value isKindOfClass:[CPString class]]];
    [self assert:[value floatValue] equals:18.0];
}

- (void)testFontDescriptorWithSymbolicTraits
{
    var fontDescriptor = [[CPFontDescriptor alloc] initWithFontAttributes:attributes],
        newDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:CPFontSansSerifClass];
        
    [self assert:[fontDescriptor symbolicTraits] equals:0];

    var symbolicTraits = [newDescriptor symbolicTraits];
    [self assertTrue:((symbolicTraits & CPFontFamilyClassMask) & CPFontSansSerifClass)];
    [self assertTrue:([newDescriptor fontFamilyCSSString] === @"Arial, sans-serif")];
    
    newDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:CPFontSerifClass];
        
    symbolicTraits = [newDescriptor symbolicTraits];
    [self assertTrue:((symbolicTraits & CPFontFamilyClassMask) & CPFontSerifClass)];
    [self assertTrue:([newDescriptor fontFamilyCSSString] === @"Arial, serif")];
    
    newDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:CPFontSansSerifClass|CPFontBoldTrait];
        
    symbolicTraits = [newDescriptor symbolicTraits];
    [self assertTrue:((symbolicTraits & CPFontFamilyClassMask) & CPFontSansSerifClass)];
    [self assertTrue:(symbolicTraits & CPFontBoldTrait)];
    [self assertTrue:([newDescriptor fontFamilyCSSString] === @"Arial, sans-serif")];
    [self assertTrue:([newDescriptor fontWeightCSSString] === @"bold")];
}
@end
