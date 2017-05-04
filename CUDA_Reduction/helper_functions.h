
// These are helper functions for the SDK samples (string parsing, timers, image helpers, etc)
#ifndef HELPER_FUNCTIONS_H
#define HELPER_FUNCTIONS_H

#ifdef WIN32
#pragma warning(disable:4996)
#endif

// includes, project
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <assert.h>
#include <exception.h>
#include <math.h>

#include <fstream>
#include <vector>
#include <iostream>
#include <algorithm>

// includes, timer, string parsing, image helpers
#include <helper_timer.h>   // helper functions for timers
#include <helper_string.h>  // helper functions for string parsing
#include <helper_image.h>   // helper functions for image compare, dump, data comparisons

#ifndef EXIT_WAIVED
#define EXIT_WAIVED 2
#endif

#endif //  HELPER_FUNCTIONS_H