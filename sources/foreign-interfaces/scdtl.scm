
(declare (unit scdtl))

(foreign-declare "

#include <time.h>

// allocates a calendar time on the heap
struct tm* malloc_scdtl_tm()
{
  struct tm* tm = malloc(sizeof(struct tm));
  return tm;
}

// frees a calendar time
void free_scdtl_tm(struct tm* tm)
{
  free(tm);
}

// returns the year of a calendar time
int scdtl_tm_year(struct tm* tm)
{
  return tm->tm_year;
}

// returns the month of a calendar time
int scdtl_tm_mon(struct tm* tm)
{
  return tm->tm_mon;
}

// returns the day of a calendar time
int scdtl_tm_mday(struct tm* tm)
{
  return tm->tm_mday;
}

// returns the hour of a calendar time
int scdtl_tm_hour(struct tm* tm)
{
  return tm->tm_hour;
}

// returns the minute of a calendar time
int scdtl_tm_min(struct tm* tm)
{
  return tm->tm_min;
}

// returns the second of a calendar time
int scdtl_tm_sec(struct tm* tm)
{
  return tm->tm_sec;
}

// sets the values of a calendar time
void scdtl_assign_tm(struct tm* tm, int year, int month, int day, int hour, int minute, int second)
{
  tm->tm_year = year;
  tm->tm_mon = month;
  tm->tm_mday = day;
  tm->tm_hour = hour;
  tm->tm_min = minute;
  tm->tm_sec = second;
}

// wraps the time function
// takes care of the time pointer
time_t scdtl_time_wrapped()
{
  return time(NULL);
}

// wraps the gmtime function
// takes care of the time pointer
struct tm* scdtl_gmtime_wrapped(time_t time)
{
  const time_t* time_ptr = &time;
  return gmtime(time_ptr);
}

// wraps the strptime function
// confirms all the source characters were consumed
int scdtl_strptime_wrapped(char* source, char* format, struct tm* tm)
{
  char* first_unconsumed_character = strptime(source, format, tm);
  if (first_unconsumed_character == NULL)
  {
    return 0;
  }

  if (first_unconsumed_character == (source + strlen(source)))
  {
    return 1;
  }

  return 0;
}

// the result of the wrapped strftime function
struct scdtl_strftime_result_t
{
  char* value;
};

// wraps the strftime function
// returns an opaque heap pointer to scheme
struct scdtl_strftime_result_t* scdtl_strftime_wrapped(struct tm* tm, char* format)
{
  char* output = malloc(sizeof(char) * 50);
  if (output == NULL)
  {
    return NULL;
  }

  int result = strftime(output, 50, format, tm);
  if (result == 0)
  {
    free(output);
    return NULL;
  }

  struct scdtl_strftime_result_t* scdtl_strftime_result = malloc(sizeof(struct scdtl_strftime_result_t));
  if (scdtl_strftime_result == NULL)
  {
    free(output);
    return NULL;
  }

  scdtl_strftime_result->value = output;
  return scdtl_strftime_result;
}

// returns the value of a scdtl_strftime_result
// allows scheme to take a copy of the string
char* scdtl_strftime_result_value(struct scdtl_strftime_result_t* scdtl_strftime_result)
{
  char* value = scdtl_strftime_result->value;
  return value;
}

// frees a scdtl_strftime_result
// as well as the value it points to
void free_scdtl_strftime_result(struct scdtl_strftime_result_t* scdtl_strftime_result)
{
  free(scdtl_strftime_result->value);
  free(scdtl_strftime_result);
}

")

;; calendar time pointers definitions
(define-foreign-type scdtl-tm "struct tm")
(define-foreign-type scdtl-tm* (c-pointer scdtl-tm))

;; scdtl-strftime-result pointers definitions
(define-foreign-type scdtl-strftime-result "struct scdtl_strftime_result_t")
(define-foreign-type scdtl-strftime-result* (c-pointer scdtl-strftime-result))

;; calendar time pointers memory management
(define malloc-scdtl-tm (foreign-lambda scdtl-tm* "malloc_scdtl_tm"))
(define free-scdtl-tm (foreign-lambda void "free_scdtl_tm" scdtl-tm*))

;; gets the values of a calendar time
(define scdtl-tm-year (foreign-lambda int "scdtl_tm_year" scdtl-tm*))
(define scdtl-tm-mon (foreign-lambda int "scdtl_tm_mon" scdtl-tm*))
(define scdtl-tm-mday (foreign-lambda int "scdtl_tm_mday" scdtl-tm*))
(define scdtl-tm-hour (foreign-lambda int "scdtl_tm_hour" scdtl-tm*))
(define scdtl-tm-min (foreign-lambda int "scdtl_tm_min" scdtl-tm*))
(define scdtl-tm-sec (foreign-lambda int "scdtl_tm_sec" scdtl-tm*))

;; sets the values of a calendar time
(define scdtl-assign-tm (foreign-lambda void "scdtl_assign_tm" scdtl-tm* int int int int int int))

;; returns the current time since epoch
(define scdtl-time (foreign-lambda long "scdtl_time_wrapped"))

;; converts a time since epoch to calendar time
(define scdtl-gmtime (foreign-lambda scdtl-tm* "scdtl_gmtime_wrapped" long))

;; converts a calendar time to time since epoch
(define scdtl-timegm (foreign-lambda long "timegm" scdtl-tm*))

;; converts a string into a calendar time
(define scdtl-strptime (foreign-lambda int "scdtl_strptime_wrapped" c-string c-string scdtl-tm*))

;; converts a calendar time into a string
(define scdtl-strftime-wrapped (foreign-lambda scdtl-strftime-result* "scdtl_strftime_wrapped" scdtl-tm* c-string))
(define scdtl-strftime-result-value (foreign-lambda c-string "scdtl_strftime_result_value" scdtl-strftime-result*))
(define free-scdtl-strftime-result (foreign-lambda void "free_scdtl_strftime_result" scdtl-strftime-result*))
