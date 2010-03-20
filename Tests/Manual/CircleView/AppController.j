/*
 * AppController.j
 * CircleView
 *
 * Created by Emmanuel Maillard on March 18, 2010.
 * Based on CircleView Sample from Apple : http://developer.apple.com/mac/library/samplecode/CircleView/
 */
 
@import <AppKit/CPTextView.j>

@implementation CircleView : CPView
{
    CPPoint center;
    float radius;
    float startingAngle;
    float angularVelocity;
    CPTextStorage textStorage;
    CPLayoutManager layoutManager;
    CPTextContainer textContainer;
}
- (id) initWithFrame:(CPRect) frame
{
    [super initWithFrame:frame];
    // First, we set default values for the various parameters.
    
    center = CPPointMake(frame.size.width / 2,frame.size.height / 2);
    radius = 115.0;
    startingAngle = Math.PI / 2.0;
    angularVelocity = Math.PI / 2.0;
    
    // Next, we create and initialize instances of the three
    // basic non-view components of the text system:
    // an NSTextStorage, an NSLayoutManager, and an NSTextContainer.
    textStorage = [[CPTextStorage alloc] initWithString:@"Here's to the crazy ones, the misfits, the rebels, the troublemakers, the round pegs in the square holes, the ones who see things differently."];

    [textStorage setFont:[CPFont systemFontOfSize:12.0]];
   
    layoutManager = [[CPLayoutManager alloc] init];
    textContainer = [[CPTextContainer alloc] init];
    [layoutManager addTextContainer:textContainer];
    
    [textStorage addLayoutManager:layoutManager];
        
    return self;
}

- (void) drawRect: (NSRect) rect
{
    var glyphIndex,
        glyphRange,
        usedRect;
    var ctx = [[CPGraphicsContext currentContext] graphicsPort];

    CGContextSaveGState(ctx);
        
    CGContextSetFillColor(ctx, [CPColor whiteColor]);
    CGContextFillRect(ctx, [self bounds]);
    CGContextRestoreGState(ctx);
    
    // Note that usedRectForTextContainer: does not force layout, so it must
    // be called after glyphRangeForTextContainer:, which does force layout.
    glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
    usedRect = [layoutManager usedRectForTextContainer:textContainer];
    for ( glyphIndex = glyphRange.location; glyphIndex < CPMaxRange(glyphRange); glyphIndex++ )
    {
        var lineFragmentRect = [layoutManager lineFragmentRectForGlyphAtIndex:glyphIndex effectiveRange:nil];
        var viewLocation = CPMakePoint(0,0),
            layoutLocation = [layoutManager locationForGlyphAtIndex:glyphIndex];
        var angle, distance;
            
        
        // Here layoutLocation is the location (in container coordinates) where the glyph was laid out.
        layoutLocation.x += lineFragmentRect.origin.x;
        layoutLocation.y += lineFragmentRect.origin.y;
            
        // We then use the layoutLocation to calculate an appropriate position for the glyph
        // around the circle (by angle and distance, or viewLocation in rectangular coordinates).
        distance = radius + usedRect.size.height - layoutLocation.y;
        angle = startingAngle + layoutLocation.x / distance;
		
        viewLocation.x = center.x + distance *Math.sin(angle);
        viewLocation.y = center.y + distance *Math.cos(angle);
		
        CGContextSaveGState(ctx);
        // We use a different affine transform for each glyph, to position and rotate it
        // based on its calculated position around the circle.
        CGContextTranslateCTM(ctx, viewLocation.x, viewLocation.y);
        CGContextRotateCTM(ctx, -angle);
		
        // drawGlyphsForGlyphRange: draws the glyph at its laid-out location in container coordinates.
        // Since we are using the transform to place the glyph, we subtract the laid-out location here.
        [layoutManager drawGlyphsForGlyphRange:CPMakeRange(glyphIndex, 1) atPoint:CPMakePoint(-layoutLocation.x, -layoutLocation.y)];
        CGContextRestoreGState(ctx);
    }
}
- (void) mouseDown:(CPEvent) event
{
    center = [self convertPoint:[event locationInWindow] fromView:nil];
    [self setNeedsDisplay:YES];
}

- (void) mouseDragged:(CPEvent) event
{
    center = [self convertPoint:[event locationInWindow] fromView:nil];
    [self setNeedsDisplay:YES];
}
- (void)setRadius:(float)distance
{
    radius = distance;
    [self setNeedsDisplay:YES];
}
- (void) takeRadiusFrom:(id)sender
{
    [self setRadius:[sender doubleValue]];
}
- (void) setStartingAngle:(float) angle
{
    startingAngle = angle;
    [self setNeedsDisplay:YES];
}
- (void)takeStartingAngleFrom: (id) sender
{
    [self setStartingAngle:[sender doubleValue]];
}
- (void) setString:(CPString) string {
    [textStorage replaceCharactersInRange:CPMakeRange(0,[textStorage length]) withString:string];
    [self setNeedsDisplay:YES];
}

- (void) takeStringFrom: (id) sender {
    [self setString:[sender stringValue]];
}

- (void)setColor:(CPColor)color
{
    [textStorage addAttribute:CPForegroundColorAttributeName value:color range:CPMakeRange(0, [textStorage length])];
    [self setNeedsDisplay:YES];
}

- (void) takeColorFrom: (id) sender {
    [self setColor:[sender color]];
}
@end

@implementation AppController : CPObject
{
    CircleView _circleView;    
}
- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    CPLogRegister(CPLogConsole);
      
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];
    
    [contentView setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];
    
    _circleView = [[CircleView alloc] initWithFrame:CGRectMake(10,10,500,500)];   
    [contentView addSubview:_circleView];
    
    var control = [[CPSlider alloc] initWithFrame:CGRectMake(10,510,400,32)];
    [control setMinValue:1.0];
    [control setMaxValue:400.0];
    [control setDoubleValue:115.0];
    [control setContinuous:YES];
    [control setTarget:_circleView];
    [control setAction:@selector(takeRadiusFrom:)];
    
    [contentView addSubview:control];
    
    control = [[CPSlider alloc] initWithFrame:CGRectMake(10,542,400,32)];
    [control setMinValue:0.0];
    [control setMaxValue:6.3];
    [control setDoubleValue:1.6];
    [control setContinuous:YES];
    [control setTarget:_circleView];
    [control setAction:@selector(takeStartingAngleFrom:)];
    
    [contentView addSubview:control];
    
    control = [[CPTextField alloc] initWithFrame:CGRectMake(10,580,500,32)];
    [control setEditable:YES];
    [control setSelectable:YES];
    [control setBordered:YES];
    [control setBezeled:YES];
    [control setStringValue:[_circleView.textStorage string]];
    [control setTarget:_circleView];
    [control setAction:@selector(takeStringFrom:)];
    
    [contentView addSubview:control];

    
    control = [[CPColorWell alloc] initWithFrame:CGRectMake(430,542,70,32)];
    [control setColor:[CPColor blackColor]];
    [control setTarget:_circleView];
    [control setAction:@selector(takeColorFrom:)];
    
    [contentView addSubview:control];

    
    [theWindow orderFront:self];
}
@end
