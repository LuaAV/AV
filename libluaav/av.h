typedef enum {
	AV_EVENT_NONE = 0,
	AV_EVENT_MOUSEENTER,
	AV_EVENT_MOUSEEXIT,
	AV_EVENT_MOUSEDOWN,
	AV_EVENT_MOUSEDRAG,
	AV_EVENT_MOUSEUP,
	AV_EVENT_MOUSEMOVE,
	AV_EVENT_MOUSESCROLL,
	AV_EVENT_KEYDOWN,
	AV_EVENT_KEYUP,
	
	AV_EVENT_COUNT
} AV_EVENT;

typedef enum {
	AV_MODIFIERS_SHIFT,
	AV_MODIFIERS_CTRL,
	AV_MODIFIERS_ALT,
	AV_MODIFIERS_CMD,
	AV_MODIFIERS_COUNT
} AV_MODIFIERS;

typedef struct av_PixelRect {
	int x, y, width, height;
} av_PixelRect;

typedef struct av_Window {
	int x, y, width, height;
	// the last recorded position of the mouse:
	int mouseX, mouseY;
	
	// the current frame (since creation):
	int frame, padding;
	
	// the last recorded state of the modifiers:
	bool shift, ctrl, alt, cmd;
	
	// the dimensions of the window when restoring from exiting full-screen:
	av_PixelRect restore_dim;
	
	// whether to clear the window before each frame (true by default)
	bool autoclear;	
	bool isfullscreen;
	
	char * title;

	void (*create_callback)(struct av_Window * self);
	void (*draw_callback)(struct av_Window * self, double dt);
	void (*resize_callback)(struct av_Window * self, int w, int h);
	void (*mouse_callback)(struct av_Window * self, AV_EVENT event, int btn, int x, int y, int dx, int dy);
	void (*key_callback)(struct av_Window * self, AV_EVENT event, int key);
	void (*modifiers_callback)(struct av_Window * self, AV_EVENT event, AV_MODIFIERS key);
} av_Window;

typedef struct av_Audio {
	unsigned int blocksize;
	unsigned int frames;	
	unsigned int indevice, outdevice;
	unsigned int inchannels, outchannels;		
	
	double time;					// in seconds
	double samplerate;				// in samples
	double latency_seconds;			// in seconds
	
	// a big buffer for main-thread audio generation
	float * buffer;
	float * inbuffer;
	
	int blocks, blockread, blockwrite, blockstep;
	int block_io_latency, dummy;
	
	// only access from audio thread:
	float * input;
	float * output;	
	void (*onframes)(struct av_Audio * self, double sampletime, float * inputs, float * outputs, int frames);
	
} av_Audio;

AV_EXPORT int av_init();
AV_EXPORT int av_run();
AV_EXPORT int av_run_once(int blocking);

AV_EXPORT double av_time();
AV_EXPORT void av_sleep(double seconds);

AV_EXPORT av_Audio * av_audio_get();
AV_EXPORT void av_audio_start();

AV_EXPORT av_Window * av_window_create(const char * title, int x, int y, int w, int h);
AV_EXPORT int av_window_flush(av_Window * avwindow);
AV_EXPORT int av_window_sync(av_Window * avwindow, int enable);
AV_EXPORT int av_window_cursor(av_Window * avwindow, int enable);
AV_EXPORT int av_window_fullscreen(av_Window * avwindow, int enable);
AV_EXPORT int av_window_destroy(av_Window * window);

AV_EXPORT int av_screens_count();
AV_EXPORT av_PixelRect av_screens_main();
AV_EXPORT av_PixelRect av_screens_deepest();
AV_EXPORT av_PixelRect av_screens_index(int idx);
