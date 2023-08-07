// mac_view.m
#import "MAC/mac_view.h"
#import "MAC/mac_window.h"


@implementation DrawableShape

- (instancetype)init {
    self = [super init];
    if (self) {
        _path = NULL;
        _color = (Mac_Color){0, 0, 0, 1}; // Default to black color
        _lineWidth = 1.0;
        _filled = NO;
    }
    return self;
}

- (void)updateLineWithInitPos:(Mac_FPoint)init_pos endPos:(Mac_FPoint)end_pos {
    CGMutablePathRef newPath = CGPathCreateMutable();
    CGPathMoveToPoint(newPath, NULL, init_pos.x, init_pos.y);
    CGPathAddLineToPoint(newPath, NULL, end_pos.x, end_pos.y);

    if (_path) {
        CGPathRelease(_path);
    }

    _path = newPath;
}

- (void)dealloc {
    [super dealloc];
    if (_path) {
        CGPathRelease(_path);
    }
}

@end

@implementation Mac_NSView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _shapes = [NSMutableArray array];
        _drawingCommands = [NSMutableArray array];
    }
    return self;
}

- (void)setLineWithInitPos:(Mac_FPoint)init_pos endPos:(Mac_FPoint)end_pos lineWidth:(float)line_width color:(Mac_Color)color {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, init_pos.x, init_pos.y);
    CGPathAddLineToPoint(path, NULL, end_pos.x, end_pos.y);

    DrawableShape* shape = [[DrawableShape alloc] init];
    shape.path = path;
    shape.color = color;
    shape.lineWidth = line_width;
    shape.filled = NO;

    [self.shapes addObject:shape];

    DrawingCommand command = {init_pos, end_pos, line_width, color};
    [self.drawingCommands addObject:[NSValue valueWithBytes:&command objCType:@encode(DrawingCommand)]];

    [self setNeedsDisplay:YES];
}

- (void)updateView {
    [self.shapes removeAllObjects];
    for (NSValue* value in self.drawingCommands) {
        DrawingCommand command;
        [value getValue:&command];
        [self setLineWithInitPos:command.init_pos endPos:command.end_pos lineWidth:command.line_width color:command.color];
    }
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetShouldAntialias(context, YES);

    for (DrawableShape* shape in self.shapes) {
        CGContextSetLineWidth(context, shape.lineWidth);
        CGContextSetRGBStrokeColor(context, shape.color.r, shape.color.g, shape.color.b, shape.color.a);
        if (shape.filled) {
            CGContextSetRGBFillColor(context, shape.color.r, shape.color.g, shape.color.b, shape.color.a);
            CGContextAddPath(context, shape.path);
            CGContextFillPath(context);
        } else {
            CGContextAddPath(context, shape.path);
            CGContextStrokePath(context);
        }
    }
}


@end

Mac_View* addSubView(Mac_View* parent, int width, int height, int x, int y, Mac_Color background_color) {
    Mac_View* view = (Mac_View*)malloc(sizeof(Mac_View));
    view->parent_view = parent;
    view->window_parent = parent->window_parent;
    view->width = width;
    view->height = height;
    view->x = x;
    view->y = y;
    view->background_color = background_color;
    view->is_root = false;
    view->is_metal_view = false;

    Mac_NSView* nsView = [[Mac_NSView alloc] initWithFrame:NSMakeRect(x, y, width, height)];
    [nsView setWantsLayer:YES];
    [nsView.layer setBackgroundColor:CGColorCreateGenericRGB(background_color.r, background_color.g, background_color.b, background_color.a)];

    // Assign the Mac_NSView instance to the _this member of the Mac_View struct
    view->_this = (__bridge void *)(nsView);

    NSView* parentNSView = nil;
    if (parent->is_root) {
        Mac_WindowDelegate* delegate = (__bridge Mac_WindowDelegate*)parent->window_parent->delegate;
        parentNSView = delegate.contentView;
    } else {
        parentNSView = (__bridge NSView*)parent->parent_view;
    }
    [parentNSView addSubview:nsView];

    if (g_viewCount < MAX_VIEWS) {
        g_views[g_viewCount++] = view;
    }

    return view;
}

Mac_View* addContentView(Mac_Window* parent, Mac_Color background_color) {
    Mac_View* view = (Mac_View*)malloc(sizeof(Mac_View));
    view->parent_view = NULL;
    view->window_parent = parent;
    view->width = parent->width;
    view->height = parent->height;
    view->x = 0;
    view->y = 0;
    view->background_color = background_color;
    view->is_root = true;
    view->is_metal_view = false;

    Mac_NSView* nsView = [[Mac_NSView alloc] initWithFrame:NSMakeRect(0, 0, view->width, view->height)];
    [nsView setWantsLayer:YES];
    [nsView.layer setBackgroundColor:CGColorCreateGenericRGB(background_color.r, background_color.g, background_color.b, background_color.a)];

    // Assign the Mac_NSView instance to the _this member of the Mac_View struct
    view->_this = (__bridge void *)(nsView);

    Mac_WindowDelegate* delegate = (__bridge Mac_WindowDelegate*)parent->delegate;
    [delegate.contentView addSubview:nsView];
    [nsView setNeedsDisplay:YES];

    if (g_viewCount < MAX_VIEWS) {
        g_views[g_viewCount++] = view;
    }

    return view;
}

void updateView(Mac_View* view) {
    Mac_NSView* nsView = (__bridge Mac_NSView*)view->_this;
    [nsView updateView];
}


void destroyView(Mac_View* view) {
    Mac_WindowDelegate* delegate = (__bridge Mac_WindowDelegate*)view->window_parent->delegate;
    for (NSView* subview in delegate.contentView.subviews) {
        if ([subview isKindOfClass:[Mac_NSView class]]) {
            [subview removeFromSuperview];
        }
    }
    free(view);
}

void destroyViews(Mac_View* views[], int count) {
    for (int i = 0; i < count; i++) {
        destroyView(views[i]);
    }
}