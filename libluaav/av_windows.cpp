
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

typedef struct av_GLContextW32 {
	HDC       dc;              // Private GDI device context
    HGLRC     context;         // Permanent rendering context
} av_GLContextW32;
 
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
		hwnd = CreateWindowEx(
			0, //WS_EX_APPWINDOW,
			"LuaAV",
			title,
			WS_OVERLAPPEDWINDOW,
			x, y, width, height,
			NULL, //GetDesktopWindow(), // parent HWND
			NULL, // menu
			HIn,
			this);
		
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
	
	void getMods() {
		shift = (GetAsyncKeyState(VK_SHIFT) & (1 << 31));
		ctrl = (GetAsyncKeyState(VK_CONTROL) & (1 << 31));
		alt = (GetAsyncKeyState(VK_MENU) & (1 << 31));
		cmd = ((GetAsyncKeyState(VK_LWIN) | GetAsyncKeyState(VK_RWIN)) & (1 << 31));
	}
	
} av_WindowW32;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
	// not that this will be NULL until the WM_NCCREATE event is posted
    av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
	switch(msg) {
		case WM_CREATE:
		case WM_NCCREATE: {
			LONG_PTR userdata = (LONG_PTR)((LPCREATESTRUCT)lParam)->lpCreateParams;
			SetWindowLongPtr(hwnd, GWL_USERDATA, (LONG_PTR)userdata); 
			break;
		}
		case  WM_SIZE: {
			win->width = LOWORD(lParam);
			win->height = HIWORD(lParam);
			if (win && win->resize_callback) win->resize_callback(win, win->width, win->height);
			break;
		}
		case  WM_MOVE: {
			win->x = LOWORD(lParam);
			win->y = HIWORD(lParam);
			if (win && win->resize_callback) win->resize_callback(win, win->width, win->height);
			break;
		}
		
		case WM_ACTIVATE: {
			BOOL focused = LOWORD(wParam) != WA_INACTIVE;
            BOOL iconified = HIWORD(wParam) ? TRUE : FALSE;
			printf("WM_ACTIVATE\n");
			break;
		}
		//case WM_ACTIVATEAPP:
		case WM_SHOWWINDOW: {
			BOOL show = wParam ? 1 : 0;
			printf("WM_SHOWWINDOW\n");
			if (win && win->create_callback) win->create_callback(win);
			break;
		}
		case WM_SYSCOMMAND: {
			switch (wParam & 0xfff0) {
                case SC_SCREENSAVE:
                case SC_MONITORPOWER: 
					// if we are fullscreen, return 0 to prevent screensaver
				case SC_KEYMENU: {
					// alt click menu... bypass it
                    return 0;
				}
			}
			break;
		}
		case WM_CLOSE: {
			printf("WM_CLOSE\n");
			break;
		}
		case WM_DESTROY: {
			printf("WM_DESTROY\n");
			break;
		}
		case WM_MOUSELEAVE: {
			printf("WM_MOUSELEAVE\n");
			break;
		}
		case WM_PAINT: {
			printf("WM_PAINT\n");
			// dirty the scene
			break;
		}
		case WM_DEVICECHANGE: {
			printf("WM_DEVICECHANGE\n"); // monitor setup?
			break;
		}
		default: {
			break;
		}
	}
	
	//SwapBuffers(window->wgl.dc);
	
	return DefWindowProc(hwnd, msg, wParam, lParam);
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

// http://msdn.microsoft.com/en-us/library/windows/desktop/ms646276(v=vs.85).aspx
union keystate {
	LPARAM lParam;
	struct {
		unsigned nRepeatCount : 16;
		unsigned nScanCode : 8;
		unsigned nExtended : 1;
		unsigned nReserved : 4;
		unsigned nContext : 1;
		unsigned nPrev : 1;
		unsigned nTrans : 1;
	};
};

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
			case WM_QUIT: {
				PostQuitMessage(0);
				break;
			}
			// consider using RAWMOUSE for mouse handling
			// http://stackoverflow.com/questions/14113303/raw-input-device-rawmouse-usage
			// (this should give better handling for games etc.)
			case WM_LBUTTONDOWN: {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->mouseX = msg.pt.x;
				win->mouseY = msg.pt.y;
				win->getMods();
				win->mouse_callback(win, AV_EVENT_MOUSEDOWN, 0, msg.pt.x, msg.pt.y, 0, 0);
				break;
			}
			case WM_RBUTTONDOWN:  {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->mouseX = msg.pt.x;
				win->mouseY = msg.pt.y;
				win->getMods();
				win->mouse_callback(win, AV_EVENT_MOUSEDOWN, 1, msg.pt.x, msg.pt.y, 0, 0);
				break;
			}
			case WM_MBUTTONDOWN:  {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->mouseX = msg.pt.x;
				win->mouseY = msg.pt.y;
				win->getMods();
				win->mouse_callback(win, AV_EVENT_MOUSEDOWN, 2, msg.pt.x, msg.pt.y, 0, 0);
				break;
			}
			case WM_LBUTTONUP: {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->mouseX = msg.pt.x;
				win->mouseY = msg.pt.y;
				win->getMods();
				win->mouse_callback(win, AV_EVENT_MOUSEUP, 0, msg.pt.x, msg.pt.y, 0, 0);
				break;
			}
			case WM_RBUTTONUP:  {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->mouseX = msg.pt.x;
				win->mouseY = msg.pt.y;
				win->getMods();
				win->mouse_callback(win, AV_EVENT_MOUSEUP, 1, msg.pt.x, msg.pt.y, 0, 0);
				break;
			}
			case WM_MBUTTONUP:  {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->mouseX = msg.pt.x;
				win->mouseY = msg.pt.y;
				win->getMods();
				win->mouse_callback(win, AV_EVENT_MOUSEUP, 2, msg.pt.x, msg.pt.y, 0, 0);
				break;
			}
			// TODO: calculate dx, dy (e.g. via global), or remove dx, dy from the mouse handling in LuaAV?
			// or just do it all in window.lua instead (useful anyway to have mouse.x, mouseX whatever available)
			case WM_MOUSEMOVE:  {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				int dx = msg.pt.x - win->mouseX;
				int dy = msg.pt.y - win->mouseY;
				win->mouseX = msg.pt.x;
				win->mouseY = msg.pt.y;
				win->getMods();
				if (msg.wParam & MK_LBUTTON) {
					win->mouse_callback(win, AV_EVENT_MOUSEDRAG, 0, msg.pt.x, msg.pt.y, dx, dy);
				} else if (msg.wParam & MK_RBUTTON) {
					win->mouse_callback(win, AV_EVENT_MOUSEDRAG, 1, msg.pt.x, msg.pt.y, dx, dy);
				} else if (msg.wParam & MK_MBUTTON) {
					win->mouse_callback(win, AV_EVENT_MOUSEDRAG, 2, msg.pt.x, msg.pt.y, dx, dy);
				} else {
					win->mouse_callback(win, AV_EVENT_MOUSEMOVE, 0, msg.pt.x, msg.pt.y, dx, dy);
				}
				break;
			}
			
			case WM_MOUSEWHEEL: {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->mouse_callback(win, AV_EVENT_MOUSESCROLL, 0, win->mouseX, win->mouseY, 0, (SHORT) HIWORD(msg.wParam) / (double) WHEEL_DELTA);
				break;
			}
			case WM_MOUSEHWHEEL: {
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->mouse_callback(win, AV_EVENT_MOUSESCROLL, 0, win->mouseX, win->mouseY, (SHORT) HIWORD(msg.wParam) / (double) WHEEL_DELTA, 0);
				break;
			}
			// TODO: entered, exited
			
			/*
			case WM_CHAR: {
				// these are the ASCII key codes (not all keys generate them)
				keystate * ks = (keystate *)(&msg.lParam);
				printf("chardown %d %d\n", msg.wParam, ks->nPrev);
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->key_callback(win, AV_EVENT_KEYDOWN, msg.wParam);
				break;
			}	
			*/
			case WM_SYSKEYDOWN:
			case WM_KEYDOWN: {
				//wParam has virtual key code http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->getMods();
				if (msg.wParam == VK_SHIFT) {
					win->modifiers_callback(win, AV_EVENT_KEYDOWN, AV_MODIFIERS_SHIFT);
				} else if (msg.wParam == VK_CONTROL) {
					win->modifiers_callback(win, AV_EVENT_KEYDOWN, AV_MODIFIERS_CTRL);
				} else if (msg.wParam == VK_MENU) {
					win->modifiers_callback(win, AV_EVENT_KEYDOWN, AV_MODIFIERS_ALT);
				} else if (msg.wParam == VK_LWIN || msg.wParam == VK_RWIN) {
					win->modifiers_callback(win, AV_EVENT_KEYDOWN, AV_MODIFIERS_CMD);
				} else {
					win->key_callback(win, AV_EVENT_KEYDOWN, msg.wParam);
				}
				break;
			}	
			case WM_SYSKEYUP:
			case WM_KEYUP: {
				//wParam has virtual key code http://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx				
				av_WindowW32 * win = (av_WindowW32 *)GetWindowLongPtr(hwnd, GWL_USERDATA);
				win->getMods();
				if (msg.wParam == VK_SHIFT) {
					win->modifiers_callback(win, AV_EVENT_KEYUP, AV_MODIFIERS_SHIFT);
				} else if (msg.wParam == VK_CONTROL) {
					win->modifiers_callback(win, AV_EVENT_KEYUP, AV_MODIFIERS_CTRL);
				} else if (msg.wParam == VK_MENU) {
					win->modifiers_callback(win, AV_EVENT_KEYUP, AV_MODIFIERS_ALT);
				} else if (msg.wParam == VK_LWIN || msg.wParam == VK_RWIN) {
					win->modifiers_callback(win, AV_EVENT_KEYUP, AV_MODIFIERS_CMD);
				} else {
					win->key_callback(win, AV_EVENT_KEYUP, msg.wParam);
				}
				break;
			}	
			default: {
				//printf("app event\n");
				DispatchMessage(&msg);
				break;
			}
		}
		
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
	fprintf(stderr, "NYI\n");
	return 0;
}
AV_EXPORT int av_window_sync(av_Window * avwindow, int enable) {
	fprintf(stderr, "NYI\n");
	return 0;
}
AV_EXPORT int av_window_cursor(av_Window * avwindow, int enable) {
	if (enable) {
		SetCursor(NULL);
	} else {
		SetCursor(LoadCursor(NULL, IDC_ARROW));
	}
	return 0;
}
AV_EXPORT int av_window_fullscreen(av_Window * avwindow, int enable) {
	fprintf(stderr, "NYI\n");
	return 0;
}
AV_EXPORT int av_window_destroy(av_Window * window) {
	fprintf(stderr, "NYI\n");
	return 0;
}

// see http://msdn.microsoft.com/en-us/library/dd144901.aspx
AV_EXPORT int av_screens_count() {
	fprintf(stderr, "NYI\n");
	return 1;
}
AV_EXPORT av_PixelRect av_screens_main() {
	LPRECT lpRect;
	GetWindowRect(GetDesktopWindow(), lpRect);
	av_PixelRect result;
	result.x = lpRect->left;
	result.y = lpRect->top;
	result.width = lpRect->right - lpRect->left;
	result.height = lpRect->bottom - lpRect->top; // or the other way?
	return result;
}
AV_EXPORT av_PixelRect av_screens_deepest();
AV_EXPORT av_PixelRect av_screens_index(int idx);