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
	// the dimensions of the window when restoring from exiting full-screen:
	av_PixelRect restore_dim;

	bool shift, ctrl, alt, cmd;
	
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

int av_init();
int av_run();
int av_run_once(int blocking);

double av_time();
void av_sleep(double seconds);

av_Audio * av_audio_get();
void av_audio_start();

av_Window * av_window_create(const char * title, int x, int y, int w, int h);
int av_window_flush(av_Window * avwindow);
int av_window_sync(av_Window * avwindow, int enable);
int av_window_cursor(av_Window * avwindow, int enable);
int av_window_fullscreen(av_Window * avwindow, int enable);
int av_window_destroy(av_Window * window);

int av_screens_count();
av_PixelRect av_screens_main();
av_PixelRect av_screens_deepest();
av_PixelRect av_screens_index(int idx);
