#import <Cocoa/Cocoa.h>

#include <unistd.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <time.h>
#include <libgen.h>
#include <utime.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define AV_PATH_MAX PATH_MAX
#define AV_GETCWD getcwd
#define AV_SNPRINTF snprintf

/*
	One goal here is to see if we can drive a Cocoa mainloop from the Lua command line. That implies: no app, no nib, no Info.plist etc. The script must create the NSApp, the menubar, window, handle events etc. all from within a dylib.
	
	It is also useful to have the runloop driven from Lua too, rather than from [NSApp run], in order to get better performance from LuaJIT (since callbacks are NYI for JIT), and to integrate it with other event loops.
	
	Ultimately, on the command line, a script will need to end with av.run() to prevent it simply terminating. (If the script was loaded from within av or av.app etc, then we are already inside NSApp run when the script starts, so av.run() is not necessary and should become a no-op.) 
*/

// @see http://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html		
// @see http://stackoverflow.com/questions/6732400/cocoa-integrate-nsapplication-into-an-existing-c-mainloop


#include "av.hpp"

static int nextid = 0;

struct av_WindowCocoa;

// this is rather ridiculous; you need to subclass NSWindow to implement 
// canBecomeKeyWindow() in order that a fullscreen window can receive key events!
@interface AVWindow : NSWindow {
}
@end
@implementation AVWindow : NSWindow
- (BOOL)canBecomeKeyWindow { return YES; }
@end


@interface AVOpenGLView : NSOpenGLView <NSWindowDelegate> {
@public
	NSTimer * timer;
	av_WindowCocoa * AVWindow;
	double t;
	int idx;
}
-(void) animate : (NSTimer *) timer;
@end

typedef struct av_WindowCocoa : public av_Window {
	AVWindow * window;
	AVOpenGLView * glview;
	
	av_WindowCocoa(const char * title, int x, int y, int w, int h) {
		this->x = x;
		this->y = y;
		this->width = w;
		this->height = h;
	
		shift = ctrl = alt = cmd = 0;
		autoclear = 1;
		create_callback = 0;
		resize_callback = 0;
		draw_callback = 0;
		mouse_callback = 0;
		key_callback = 0;
		modifiers_callback = 0;
		
		isfullscreen = 0;
		
		this->title = (char *)malloc(strlen(title)+1);
		strcpy(this->title, title);
		
		window = 0;
		glview = 0;
	}
	
	~av_WindowCocoa() {
		close();
		free(this->title);
	}	
	
	void open();
	void close();
	
} av_WindowCocoa;

@interface AVAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
}
- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
@end

static int initialized = 0;
static int running = 0;

static id pool;
static id appMenuItem;
static id appMenu;
static id appName;

static NSApplication * app = 0;
static AVAppDelegate * appDelegate = 0;


@implementation AVOpenGLView : NSOpenGLView
- (id) initWithFrame:(NSRect)frameRect {
	NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		// Must specify the 3.2 Core Profile to use OpenGL 3.2
		//NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		//    NSOpenGLPFAColorSize,     24,
		//    NSOpenGLPFAAlphaSize,     8,
		//    NSOpenGLPFAAccelerated,
		0
	};
	
	NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
	if (!pixelFormat) { NSLog(@"No OpenGL pixel format"); }
	
	//NSOpenGLContext *context = [[[NSOpenGLContext alloc]initWithFormat:pixelFormat shareContext:nil]autorelease];
	//[self setPixelFormat:pixelFormat];
	//[self setOpenGLContext:context];
	
	self = [super initWithFrame:frameRect pixelFormat:pixelFormat];
	
	// install render timer:
	self->timer = [NSTimer timerWithTimeInterval:(1.0f/60.0f)
			target:self
			selector:@selector(animate:)
			userInfo:nil
			repeats:YES];
	self->t = av_time();
	self->idx = nextid++;
	
	NSLog(@"created view %d", self->idx);

	[[NSRunLoop currentRunLoop] addTimer:self->timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:self->timer forMode:NSEventTrackingRunLoopMode];
	
	self->AVWindow = 0;
	
	return self;
}

// identify thsi NSView as the primary recipient of events in the window
// overrides the default behavior of NSView
- (BOOL)acceptsFirstResponder {
	// say that we accept mousemoved events:
	[[self window] setAcceptsMouseMovedEvents:YES];
    return YES;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}


- (BOOL)isOpaque
{
    return YES;
}

-(void) animate : (NSTimer *) timer {
	//printf("%d\n", self->idx);
	[self setNeedsDisplay: YES];
}

- (void)mouseDown:(NSEvent *)theEvent {
	//NSLog(@"mouseDown");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEDOWN, AVWindow->ctrl, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
		//NSUInteger mod = [theEvent modifierFlags];
		// [theEvent modifierFlags] & NSCommandKeyMask //NSShiftKeyMask NSAlphaShiftKeyMask
		//NSWindow * window = [theEvent window];
		//NSTimeInterval timestamp = [theEvent timestamp];
		//NSEventType type = [theEvent type];
		// CGEventRef cgref = [theEvent CGEvent];
		//int nclicks = [theEvent clickCount];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
    //NSLog(@"mouseDrag");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEDRAG, AVWindow->ctrl, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
    //NSLog(@"mouseUp");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEUP, AVWindow->ctrl, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)mouseMoved:(NSEvent *)theEvent {
   	//NSLog(@"mouseMoved");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEMOVE, AVWindow->ctrl, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    NSLog(@"rightMouseDown");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEDOWN, 1, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)rightMouseDragged:(NSEvent *)theEvent {
    //NSLog(@"mouseDrag");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEDRAG, 1, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)rightMouseUp:(NSEvent *)theEvent {
    //NSLog(@"mouseUp");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEUP, 1, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)rightMouseMoved:(NSEvent *)theEvent {
   	//NSLog(@"mouseMoved");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEMOVE, 1, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)otherMouseDown:(NSEvent *)theEvent {
    NSLog(@"rightMouseDown");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEDOWN, 2, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)otherMouseDragged:(NSEvent *)theEvent {
    //NSLog(@"mouseDrag");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEDRAG, 2, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)otherMouseUp:(NSEvent *)theEvent {
    //NSLog(@"mouseUp");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEUP, 2, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)otherMouseMoved:(NSEvent *)theEvent {
   	//NSLog(@"mouseMoved");// determine if I handle theEvent
    if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
   		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSEMOVE, 2, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

/*
– rightMouseDown:
– rightMouseDragged:
– rightMouseUp:
– otherMouseDown:
– otherMouseDragged:
– otherMouseUp:
*/

- (void)mouseEntered:(NSEvent *)theEvent
{
	NSLog(@"mouseEntered");//[self sendMouseEvent:theEvent action: luaav::Window::MOUSE_ENTER button:""];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	NSLog(@"mouseExited");
}

- (void)scrollWheel:(NSEvent *)theEvent {
	//NSLog(@"scrollWheel");
	if (AVWindow) {
		NSPoint event_location = [theEvent locationInWindow];
		AVWindow->mouse_callback(AVWindow, AV_EVENT_MOUSESCROLL, 0, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
	}
}

- (void)keyDown:(NSEvent *)theEvent {
    //NSLog(@"keyDown");// determine if I handle theEvent
    if (AVWindow) {
		NSString * characters = [theEvent charactersIgnoringModifiers]; 
		AVWindow->key_callback(AVWindow, AV_EVENT_KEYDOWN, [characters characterAtIndex:0]);
	}
    // pass key events up the hierarchy:
    [[self nextResponder] keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent {
    //NSLog(@"keyUp");// determine if I handle theEvent
    if (AVWindow) {
		NSString * characters = [theEvent charactersIgnoringModifiers]; 
		AVWindow->key_callback(AVWindow, AV_EVENT_KEYUP, [characters characterAtIndex:0]);
	}
    // pass key events up the hierarchy:
    [[self nextResponder] keyUp:theEvent];
}

// modifiers only
- (void)flagsChanged:(NSEvent *)theEvent {
    //NSLog(@"flagsChanged");// determine if I handle theEvent
    if (AVWindow) {
    	NSUInteger modifierFlags = [theEvent modifierFlags];
    	
    	bool shift = (modifierFlags & NSShiftKeyMask) ? true : false;
		bool ctrl = (modifierFlags & NSControlKeyMask) ? true : false;
		bool alt = (modifierFlags & NSAlternateKeyMask) ? true : false;
		bool cmd = (modifierFlags & NSCommandKeyMask) ? true : false;
		
    	if (shift != AVWindow->shift) {
    		AVWindow->shift = shift;
    		AVWindow->modifiers_callback(AVWindow, shift ? AV_EVENT_KEYDOWN : AV_EVENT_KEYUP, AV_MODIFIERS_SHIFT);
    	}
    	if (ctrl != AVWindow->ctrl) {
    		AVWindow->ctrl = ctrl;
    		AVWindow->modifiers_callback(AVWindow, ctrl ? AV_EVENT_KEYDOWN : AV_EVENT_KEYUP, AV_MODIFIERS_CTRL);
    	}
    	if (alt != AVWindow->alt) {
    		AVWindow->alt = alt;
    		AVWindow->modifiers_callback(AVWindow, alt ? AV_EVENT_KEYDOWN : AV_EVENT_KEYUP, AV_MODIFIERS_ALT);
    	}
    	if (cmd != AVWindow->cmd) {
    		AVWindow->cmd = cmd;
    		AVWindow->modifiers_callback(AVWindow, cmd ? AV_EVENT_KEYDOWN : AV_EVENT_KEYUP, AV_MODIFIERS_CMD);
    	}
    	
    	//NSShiftKeyMask NSAlphaShiftKeyMask
    }
    // pass key events up the hierarchy:
    [[self nextResponder] flagsChanged:theEvent];
}

/*
– cursorUpdate:
– tabletPoint:
– tabletProximity:
– helpRequested:
– scrollWheel:
– quickLookWithEvent:
– cancelOperation:

https://developer.apple.com/library/mac/documentation/cocoa/Reference/ApplicationKit/Classes/NSResponder_Class/Reference/Reference.html

*/

// trackpad gestures
// https://developer.apple.com/library/mac/documentation/cocoa/conceptual/eventoverview/HandlingTouchEvents/HandlingTouchEvents.html#//apple_ref/doc/uid/10000060i-CH13-SW10

// scroll not handled by specific handler, so we'd need a generic event handler
// NSScrollWheel
// possibly using addLocalMonitorForEventsMatchingMask:handler:.
// https://developer.apple.com/library/mac/documentation/cocoa/conceptual/eventoverview/MonitoringEvents/MonitoringEvents.html#//apple_ref/doc/uid/10000060i-CH15-SW3

/*
- (void)copyText {
	NSLog(@"copy");
}

- (void)cutText {
	NSLog(@"cut");
}

- (void)pasteText {
	NSLog(@"paste");
}

- (void)selectAllText {
	NSLog(@"selectAll");
}
*/

- (void)reshape {
	[super reshape];
	if (AVWindow && AVWindow->resize_callback) {
		NSRect dim = [[[self window] contentView] bounds];
		AVWindow->width = dim.size.width;
		AVWindow->height = dim.size.height;
		AVWindow->resize_callback(AVWindow, dim.size.width, dim.size.height);
	}
}

- (void)update {
	//NSLog(@"update");
	[super update];
}

float rot = 0.;
- (void)drawRect:(NSRect)bounds {
	//NSLog(@"drawRect %p", self->AVWindow);
	double t1 = av_time();
	double dt = t1 - t;
	t = t1;
	
	if (AVWindow) {
		[[self openGLContext] makeCurrentContext];
		
		//CGLLockContext(self.openGLContext.CGLContextObj);
	
		// now call our global window draw...
		NSRect dim = [[[self window] contentView] bounds];
		glViewport(0, 0, dim.size.width, dim.size.height);
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		if (AVWindow->autoclear) {
			glClearColor(0, 0, 0, 1);
			glClear(GL_COLOR_BUFFER_BIT);		
		} 
		if (AVWindow->draw_callback) AVWindow->draw_callback(AVWindow, dt);
		
	
		//glFlush();
		[[self openGLContext] flushBuffer];
		//CGLUnlockContext(self.openGLContext.CGLContextObj);
	}
}

- (void)prepareOpenGL {
	[super prepareOpenGL];
	NSLog(@"prepareOpenGL");
	
	[[self openGLContext] makeCurrentContext];
	GLint swapInt = 1;
    [self.openGLContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    //CGLLockContext(self.openGLContext.CGLContextObj);

    // all opengl prep goes here
	if (AVWindow && AVWindow->create_callback) AVWindow->create_callback(AVWindow);

    //CGLUnlockContext(self.openGLContext.CGLContextObj);
}

// Window delegate handlers:
// https://developer.apple.com/library/mac/documentation/cocoa/reference/NSWindowDelegate_Protocol/Reference/Reference.html

-(void)windowWillClose:(NSNotification *)note {
	NSLog(@"windowWillClose");
	[timer invalidate];
	[timer release];
}

@end

@implementation AVAppDelegate : NSObject
- (id)init {
    if (self = [super init]) {
        [NSApp setDelegate:self];
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSLog(@"will finish launching");
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	// Insert code here to initialize your application 
	NSLog(@"did finish launching");
	// this is the right moment to bring our application into focus:
	[app activateIgnoringOtherApps:YES];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *) fileName {
    NSLog(@"File dragged on: %@", fileName);
    //av_dofile([fileName UTF8String]);
    return 1;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
    return NSTerminateNow;
}

- (void)terminate:(id)sender{
    running = 0;
}
@end

void av_WindowCocoa::open() {
	// get new extents
	NSRect nsdim;
	if (isfullscreen) {
		// cache current dimension:
		av_PixelRect fullscreendim = av_screens_main();	// TODO: current screen?
		nsdim = NSMakeRect(fullscreendim.x, fullscreendim.y, fullscreendim.width, fullscreendim.height);
	} else {
		nsdim = NSMakeRect(x, y, width, height);
	}
	
	// close existing window
	close();
	
	NSLog(@"making new window");
	
	// create & configure NSWindow:
	if (isfullscreen) {
		window = [[AVWindow alloc]	initWithContentRect:nsdim 
									styleMask:NSBorderlessWindowMask 
									backing:NSBackingStoreBuffered 
									defer:YES];
		//[window setHidesOnDeactivate:YES];
		// set window to be above menu bar
		[window setLevel:NSMainMenuWindowLevel+1];
	} else {
		window = [[AVWindow alloc]	initWithContentRect:nsdim
									styleMask:NSTitledWindowMask | 								
											  NSResizableWindowMask |
											  NSClosableWindowMask | 
											  NSMiniaturizableWindowMask
									backing:NSBackingStoreBuffered 
									defer:NO];
		[window setTitle:[NSString stringWithUTF8String:title]];
		// rather annoyingly can't position the window accurately because of menubar. this is a hack to get us near.
		[window cascadeTopLeftFromPoint:NSMakePoint(0, 1)];	
	}
	[window setOpaque:YES];
	
	glview = [[AVOpenGLView alloc] initWithFrame:nsdim];
	glview->AVWindow = this;
    
    [window setContentView:glview];
    // using the glview as delegate:
	[window setDelegate: glview];
	[window makeFirstResponder: glview];
	
	// activate it:
	[window makeKeyAndOrderFront:window];
}

void av_WindowCocoa::close() {
	if (window) {
		[window close];
	}
}



av_Window * av_window_create(const char * title, int x, int y, int w, int h) {

	if (!title) {
		title = [appName UTF8String];
	}

	av_WindowCocoa * AVWindow = new av_WindowCocoa(title, x, y, w, h);
	
	AVWindow->open();
	
	return AVWindow;
} 

int av_window_fullscreen(av_Window * AVWindow, int enable) {
	av_WindowCocoa * win = (av_WindowCocoa *)AVWindow;
	if (win->isfullscreen != enable) {
		if (enable) {
			printf("caching %d %d\n", win->width, win->height);
			// cache current dimensions for when exiting fullscreen:
			
			NSRect dim = [[win->window contentView] bounds];
			win->restore_dim.width = dim.size.width;
			win->restore_dim.height = dim.size.height;
			AVWindow->resize_callback(AVWindow, dim.size.width, dim.size.height);
		} else {
			// restore them:
			win->width = win->restore_dim.width;
			win->height = win->restore_dim.height;
		}
		win->isfullscreen = enable;
		win->open();
	}
	return 0;
}

int av_window_sync(av_Window * AVWindow, int enable) {
	const GLint interval = enable ? 1 : 0;
	[[((av_WindowCocoa *)AVWindow)->glview openGLContext] setValues:&interval forParameter: NSOpenGLCPSwapInterval];
	return 0;
}

int av_window_cursor(av_Window * AVWindow, int enable) {
	static int cursorhides = 0;
	if (enable) {
		while (cursorhides < 0) {
			[NSCursor unhide];
			cursorhides++;
		}
	} else {
		[NSCursor hide];
		cursorhides--;
	}
	return 0;
}

/*
	switch(style) {
	case Window::ARROW:				[[NSCursor arrowCursor] set];				break;
	case Window::IBEAM:				[[NSCursor IBeamCursor] set];				break;
//	case Window::CONTEXTUAL_MENU:	[[NSCursor contextualMenuCursor] set];		break;
	case Window::CROSSHAIR:			[[NSCursor crosshairCursor] set];			break;
	case Window::CLOSED_HAND:		[[NSCursor closedHandCursor] set];			break;
//	case Window::DRAG_COPY:			[[NSCursor dragCopyCursor ] set];			break;
//	case Window::DRAG_LINK:			[[NSCursor dragLinkCursor ] set];			break;
//	case Window::NO_OP:				[[NSCursor operationNotAllowedCursor] set];	break;
	case Window::OPEN_HAND:			[[NSCursor openHandCursor] set];			break;
	case Window::POINTING_HAND:		[[NSCursor pointingHandCursor] set];		break;
	case Window::RESIZE_LEFT:		[[NSCursor resizeLeftCursor] set];			break;
	case Window::RESIZE_RIGHT:		[[NSCursor resizeRightCursor] set];			break;
	case Window::RESIZE_LEFTRIGHT:	[[NSCursor resizeLeftRightCursor] set];		break;
	case Window::RESIZE_UP:			[[NSCursor resizeUpCursor] set];			break;
	case Window::RESIZE_DOWN:		[[NSCursor resizeDownCursor] set];			break;
	case Window::RESIZE_UPDOWN:		[[NSCursor resizeUpDownCursor] set];		break;
	case Window::DISAPPEARING_ITEM:	[[NSCursor disappearingItemCursor] set];	break;
	}
}
*/



int av_window_flush(av_Window * AVWindow) {
	[[((av_WindowCocoa *)AVWindow)->glview openGLContext] flushBuffer];
	return 0;
}

int av_window_destroy(av_Window * AVWindow) {
	delete ((av_WindowCocoa *)AVWindow);
	return 0;
}

av_PixelRect av_PixelRect_from_NSScreen(NSScreen * screen) {
	av_PixelRect rect, mainrect;

	NSRect mainframe = [[NSScreen mainScreen] frame];
	NSRect frame = [screen frame];

	mainrect.x = mainframe.origin.x;
	mainrect.y = mainframe.origin.y;
	mainrect.width = mainframe.size.width;
	mainrect.height = mainframe.size.height;
	
	rect.x = frame.origin.x;
	rect.y = frame.origin.y;
	rect.width = frame.size.width;
	rect.height = frame.size.height;
	
	rect.y = mainrect.height - rect.y - rect.height;
	
	return rect;
}

int av_screens_count() {
    return [[NSScreen screens] count];
}

av_PixelRect av_screens_index(int idx) {
	return av_PixelRect_from_NSScreen([[NSScreen screens] objectAtIndex:(idx % av_screens_count())]);
}

av_PixelRect av_screens_deepest() {
	return av_PixelRect_from_NSScreen([NSScreen deepestScreen]);
}

av_PixelRect av_screens_main() {
	return av_screens_index(0);
}

double av_time() {
	timeval t;
	gettimeofday(&t, NULL);
	return (double)t.tv_sec + (((double)t.tv_usec) * 1.0e-6);
}	

void av_sleep(double seconds) {
	time_t sec = (time_t)seconds;
	long long int nsec = 1.0e9 * (seconds - (double)sec);
	timespec tspec = { sec, nsec };
	while (nanosleep(&tspec, &tspec) == -1) {
		continue;
	}
}

int av_init() {
	if (!initialized) {
		NSLog(@"%@", [[NSProcessInfo processInfo] arguments]);
		// use garbage collection:
   		pool = [NSAutoreleasePool new];
		// get/create the NSApplication
		app = [NSApplication sharedApplication];
		
		
		// In Snow Leopard, programs without application bundles and Info.plist files don't get a menubar and can't be brought to the front unless the presentation option is changed:
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
		// Next, we need to create the menu bar. You don't need to give the first item in the menubar a name (it will get the application's name automatically):
		id menubar = [[NSMenu new] autorelease];
		appMenuItem = [[NSMenuItem new] autorelease];
		[menubar addItem:appMenuItem];
		[NSApp setMainMenu:menubar];
		
		// Then we add the quit item to the menu. Fortunately the action is simple since terminate: is already implemented in NSApplication and the NSApplication is always in the responder chain.
		appMenu = [[NSMenu new] autorelease];
		appName = [[NSProcessInfo processInfo] processName];
		id quitTitle = [@"Quit " stringByAppendingString:appName];
		id quitMenuItem = [[[NSMenuItem alloc] initWithTitle:quitTitle
			action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
		[appMenu addItem:quitMenuItem];
		[appMenuItem setSubmenu:appMenu];
		
		// set delegate:
    	appDelegate = [[[AVAppDelegate alloc] init] autorelease];
		
		// apparently this is necessary:
		[app finishLaunching];
		
		initialized = 1;
		
	}
	return 0;
}

// clear the current event queue:
int av_run_once(int blocking) {
	// We need to handle the autorelease pool
	// because we are in our own loop
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSEvent * event = 0;
	
	if (blocking) {
		// wait for the next event: 
		event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];
	} else {
		// grab an existing event:
		event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
	}
	
	// Process events
	// (or NSEventTrackingRunLoopMode )
	while (event) {
		NSWindow * window = [event window];
		//[window sendEvent:event];
		
		// pass to app delegate (will also forward to windows):
		[app sendEvent:event];
		
		// grab any other existing events:
		event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
	}
	[app updateWindows];

	// Clean up any autoreleased objects that were created this time through the loop.
	[pool release];
	return 0;
}

// hand over control of the app to Cocoa:
// (This would be called in advance of the script from within LuaAV, but must be called manually from a LuaJIT command line script)
int av_run() {

    if (!running && av_init() == 0) {
    	running = true;
 	   	//[app run]; [pool drain];
 	   	// @see http://stackoverflow.com/questions/6732400/cocoa-integrate-nsapplication-into-an-existing-c-mainloop
 	   	// @see http://www.cocoawithlove.com/2009/01/demystifying-nsapplication-by.html
 	   	while (running) {
			av_run_once(1);
		}
	}
	return 0;
}