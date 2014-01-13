
#include <windows.h>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <gl\gl.h>                                // Header File For The OpenGL32 Library
#include <gl\glu.h>                               // Header File For The GLu32 Library

#include "av.hpp"

#if defined(_MSC_VER) || defined(_MSC_EXTENSIONS)
  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000Ui64
#else
  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000ULL
#endif

#define AV_PATH_MAX MAX_PATH
#define AV_GETCWD _getcwd
#define AV_SNPRINTF _snprintf

struct timezone {
  int  tz_minuteswest; /* minutes W of Greenwich */
  int  tz_dsttime;     /* type of dst correction */
};
 
int gettimeofday(struct timeval *tv, struct timezone *tz) {
  FILETIME ft;
  unsigned __int64 tmpres = 0;
  static int tzflag;
  if (NULL != tv)
  {
	GetSystemTimeAsFileTime(&ft);
 
	tmpres |= ft.dwHighDateTime;
	tmpres <<= 32;
	tmpres |= ft.dwLowDateTime;
 
	/*converting file time to unix epoch*/
	tmpres -= DELTA_EPOCH_IN_MICROSECS; 
	tmpres /= 10;  /*convert into microseconds*/
	tv->tv_sec = (long)(tmpres / 1000000UL);
	tv->tv_usec = (long)(tmpres % 1000000UL);
  }
  if (NULL != tz)
  {
	if (!tzflag)
	{
	  _tzset();
	  tzflag++;
	}
	tz->tz_minuteswest = _timezone / 60;
	tz->tz_dsttime = _daylight;
  }
  return 0;
}


AV_EXPORT double av_time() {
	timeval t;
	gettimeofday(&t, NULL);
	return (double)t.tv_sec + (((double)t.tv_usec) * 1.0e-6);
}	

AV_EXPORT void av_sleep(double seconds) {
	Sleep((DWORD)(seconds * 1.0e3));
}


static HMODULE HIn;


typedef struct av_WindowW32 : public av_Window {

	HWND hwnd;
	
	av_WindowW32(const char * title, int x, int y, int w, int h) {
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
		
		hwnd = 0;
	}
	
	~av_WindowW32() {
		close();
		free(this->title);
	}	
	
	int open() {
		hwnd = CreateWindowEx(WS_EX_TOPMOST,"LuaAV","",WS_OVERLAPPEDWINDOW,
							  x, y, width, height,
							  GetDesktopWindow(),NULL,HIn,this);
		
		if(hwnd==NULL) {
			printf("failed to create window\n");
			return 1;
		} else {
			printf("created window\n");
		}
		
		ShowWindow(hwnd, SW_SHOW); 
		UpdateWindow(hwnd); 
		SetFocus(hwnd);
		return 0;
	}
	
	int close() {
	
	}
	
} av_WindowW32;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	// not that this will be NULL until the WM_NCCREATE event is posted
    av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
	switch(msg) {
		case WM_NCCREATE: {
			LONG_PTR userdata = (LONG_PTR)((LPCREATESTRUCT)lParam)->lpCreateParams;
			SetWindowLongPtr(hwnd, GWL_USERDATA, (LONG_PTR)userdata); 
			return DefWindowProc(hwnd, msg, wParam, lParam);
		}
		case WM_LBUTTONDOWN: {
			printf("window mousedown %p\n", win);
			//win->mouse_callback(win, AV_EVENT_MOUSEDOWN, 0, event_location.x, event_location.y, [theEvent deltaX], [theEvent deltaY]);
			break;
		}
		//  case WM_RBUTTONDOWN:
		default: {
			printf("window event\n");
			return DefWindowProc(hwnd, msg, wParam, lParam);
		}
	}
	return 0L;
}

BOOL Register(HINSTANCE HIn) {
    WNDCLASSEX Wc;

    Wc.cbSize=sizeof(WNDCLASSEX);
    Wc.style=0;
    Wc.lpfnWndProc=WndProc;
    Wc.cbClsExtra=0;
    Wc.cbWndExtra=0;
    Wc.hInstance=HIn;
    Wc.hIcon=LoadIcon(NULL,IDI_APPLICATION);
    Wc.hCursor=LoadCursor(NULL,IDC_ARROW);
    Wc.hbrBackground=(HBRUSH)GetStockObject(BLACK_BRUSH);
    Wc.lpszMenuName=NULL;
    Wc.lpszClassName="LuaAV";
    Wc.hIconSm=LoadIcon(NULL,IDI_APPLICATION);

    return RegisterClassEx(&Wc);
}



AV_EXPORT int av_init() {
	static bool initialized = 0;
	if (!initialized) {
		initialized = 1;
		
		HIn = GetModuleHandle(NULL);
		if (!HIn) {
			printf("failed to create HMODULE\n");
			return 0;
		}
		
		if(!Register(HIn)) {
			printf("failed to register HINSTANCE\n");
			return 0;
		}
	}
	return 0;
}
AV_EXPORT int av_run() {
	return 0;
}
AV_EXPORT int av_run_once(int blocking) {
	MSG msg;
	HWND hWnd = NULL;	// get messages for all windows
	
	BOOL todo = false;
	if (todo) {
		todo = GetMessage(&msg, hWnd, 0, 0);
	} else {
		todo = PeekMessage(&msg,hWnd, 0,0, PM_REMOVE);
	}
	
	while (todo) {
		HWND   hwnd = msg.hwnd;
		UINT message = msg.message;
		/*
			WPARAM wParam;
			LPARAM lParam;
			DWORD  time;
			POINT  pt; (long x, y)*/
		//printf("%d\n", message);
		TranslateMessage(&msg);
		switch (msg.message) {
			case WM_LBUTTONDOWN: {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				printf("mousedown %p %p\n", win, win->mouse_callback);
				win->mouse_callback(win, AV_EVENT_MOUSEDOWN, 0, msg.pt.x, msg.pt.y, 0, 0);
				break;
			}
			//  case WM_RBUTTONDOWN:
			case WM_CHAR: {
				printf("keydown %d\n", msg.wParam);
				break;
			}	
			case WM_KEYDOWN: {
				//wParam has virtual key code http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
				printf("keydown %d \n", msg.wParam);
				break;
			}	
			case WM_DESTROY: {
				// hwnd is being destroyed...
				break;
			}
			default: {
				break;
			}
		}
		DispatchMessage(&msg);
		
		// next one:
		todo = PeekMessage(&msg,NULL,0,0,PM_REMOVE);
	}
	return 0;
}

AV_EXPORT av_Window * av_window_create(const char * title, int x, int y, int w, int h) {
	if (!title) {
		title = "LuaAV";
	}
	av_WindowW32 * win = new av_WindowW32(title, x, y, w, h);	
	win->open();
	return win;
}
AV_EXPORT int av_window_flush(av_Window * avwindow) {
	return 0;
}
AV_EXPORT int av_window_sync(av_Window * avwindow, int enable) {
	return 0;
}
AV_EXPORT int av_window_cursor(av_Window * avwindow, int enable) {
	return 0;
}
AV_EXPORT int av_window_fullscreen(av_Window * avwindow, int enable) {
	return 0;
}
AV_EXPORT int av_window_destroy(av_Window * window) {
	return 0;
}

AV_EXPORT int av_screens_count() {
	return 1;
}
AV_EXPORT av_PixelRect av_screens_main();
AV_EXPORT av_PixelRect av_screens_deepest();
AV_EXPORT av_PixelRect av_screens_index(int idx);