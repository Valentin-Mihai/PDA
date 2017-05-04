#pragma once

#ifndef __REDUCTION_H__
#define __REDUCTION_H__

template <class T>
void reduce(int size, int threads, int blocks,
	int whichKernel, T *d_idata, T *d_odata);

#endif