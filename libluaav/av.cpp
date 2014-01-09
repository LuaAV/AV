#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#ifdef AV_WINDOWS
	#include <windows.h>
	#define AV_PATH_MAX MAX_PATH
	#define AV_GETCWD _getcwd
	#define AV_SNPRINTF _snprintf

#else
	#include <unistd.h>
	#include <sys/time.h>
	#include <sys/stat.h>
	#include <time.h>
	#include <libgen.h>
	#include <utime.h>
	#define AV_PATH_MAX PATH_MAX
	#define AV_GETCWD getcwd
	#define AV_SNPRINTF snprintf
#endif

#include "av.hpp"

#ifdef AV_WINDOWS
	#include < time.h >
	#if defined(_MSC_VER) || defined(_MSC_EXTENSIONS)
	  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000Ui64
	#else
	  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000ULL
	#endif
	 
	struct timezone 
	{
	  int  tz_minuteswest; /* minutes W of Greenwich */
	  int  tz_dsttime;     /* type of dst correction */
	};
	 
	int gettimeofday(struct timeval *tv, struct timezone *tz)
	{
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
#endif

AV_EXPORT double av_time() {
		timeval t;
		gettimeofday(&t, NULL);
		return (double)t.tv_sec + (((double)t.tv_usec) * 1.0e-6);
}	

AV_EXPORT void av_sleep(double seconds) {
	#ifdef AV_WINDOWS
		Sleep((DWORD)(seconds * 1.0e3));
	#else
		time_t sec = (time_t)seconds;
		long long int nsec = 1.0e9 * (seconds - (double)sec);
		timespec tspec = { sec, nsec };
		while (nanosleep(&tspec, &tspec) == -1) {
			continue;
		}
	#endif
}