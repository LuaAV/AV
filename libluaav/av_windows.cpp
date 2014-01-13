
#include <windows.h>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

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


AV_EXPORT int av_init() {
	static bool initialized = 0;
	if (!initialized) {
		initialized = 1;
	}
	return 0;
}
AV_EXPORT int av_run();
AV_EXPORT int av_run_once(int blocking);

AV_EXPORT av_Window * av_window_create(const char * title, int x, int y, int w, int h);
AV_EXPORT int av_window_flush(av_Window * avwindow);
AV_EXPORT int av_window_sync(av_Window * avwindow, int enable);
AV_EXPORT int av_window_cursor(av_Window * avwindow, int enable);
AV_EXPORT int av_window_fullscreen(av_Window * avwindow, int enable);
AV_EXPORT int av_window_destroy(av_Window * window);

AV_EXPORT int av_screens_count() {
	return 1;
}
AV_EXPORT av_PixelRect av_screens_main();
AV_EXPORT av_PixelRect av_screens_deepest();
AV_EXPORT av_PixelRect av_screens_index(int idx);