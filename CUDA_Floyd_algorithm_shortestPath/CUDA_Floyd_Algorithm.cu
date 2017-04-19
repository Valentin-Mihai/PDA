#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include  <time.h>
#include <sys/time.h>
#define inf 99999

__global__ void funct1(int n, int k, float* x, int* qx) {

	__shared__ float dBlock[1024];
	__shared__ float QBlock[1024];
	int i = (threadIdx.x >> 5);
	int j = threadIdx.x & 31;

	int index1 = (k * 32 + i) * n + k * 32 + j;
	dBlock[threadIdx.x] = x[index1];
	QBlock[threadIdx.x] = qx[index1];
	int k1 = k * 32;

	for (int l = 0; l < 32; l++) {
		syncthreads();
		float temp2 = dBlock[(i << 5) + l] + dBlock[(l << 5) + j];
		if (dBlock[threadIdx.x] > temp2) {
			dBlock[threadIdx.x] = temp2;
			QBlock[threadIdx.x] = l + k1;
		}
	}
	x[index1] = dBlock[threadIdx.x];
	qx[index1] = QBlock[threadIdx.x];
}

__global__ void funct2(int n, int k, float* x, int* qx) {
	if (blockIdx.y == 0) {

		int i = (threadIdx.x >> 5);
		int j = threadIdx.x & 31;
		int k1 = k * 32;
		__shared__ float dBlock[1024];
		__shared__ float QcBlock[1024];
		__shared__ float cBlock[1024];
		dBlock[threadIdx.x] = x[(k1 + i) * n + k1 + j];
		int add = 0;

		if (blockIdx.x >= k) { //jumping over central block
			add = 1;
		}

		int index1 = (k1 + i) * n + (blockIdx.x + add) * 32 + j;
		cBlock[threadIdx.x] = x[index1];
		QcBlock[threadIdx.x] = qx[index1];

		for (int l = 0; l < 32; l++) {
			syncthreads();
			float temp2 = dBlock[i * 32 + l] + cBlock[l * 32 + j];
			if (cBlock[threadIdx.x] > temp2) {
				cBlock[threadIdx.x] = temp2;
				QcBlock[threadIdx.x] = l + k1;
			}
		}
		x[index1] = cBlock[threadIdx.x];
		qx[index1] = QcBlock[threadIdx.x];

	}
	else {

		int i = (threadIdx.x >> 5);
		int j = threadIdx.x & 31;
		int k1 = k * 32;
		__shared__ float dBlock[1024];
		__shared__ float QcBlock[1024];
		__shared__ float cBlock[1024];
		dBlock[threadIdx.x] = x[(k1 + i) * n + k1 + j];
		int add = 0;

		if (blockIdx.x >= k) { //jumping over central block        
			add = 1;
		}

		int index1 = ((blockIdx.x + add) * 32 + i) * n + k1 + j;
		cBlock[threadIdx.x] = x[index1];
		QcBlock[threadIdx.x] = qx[index1];

		for (int l = 0; l < 32; l++) {
			syncthreads();
			float temp2 = cBlock[i * 32 + l] + dBlock[l * 32 + j];

			if (cBlock[threadIdx.x] > temp2) {
				cBlock[threadIdx.x] = temp2;

				QcBlock[threadIdx.x] = l + k1;
			}
		}
		x[index1] = cBlock[threadIdx.x];
		qx[index1] = QcBlock[threadIdx.x];
	}
}

__global__ void funct3(int n, int k, float* x, int* qx) {
	int i = (threadIdx.x >> 5);
	int j = threadIdx.x & 31;
	int k1 = k * 32;
	int addx = 0;
	int addy = 0;

	__shared__ float dyBlock[1024];
	__shared__ float dxBlock[1024];
	__shared__ float QcBlock[1024];
	__shared__ float cBlock[1024];

	if (blockIdx.x >= k) {
		addx = 1;

	}
	if (blockIdx.y >= k) {
		addy = 1;

	}

	dxBlock[threadIdx.x] = x[((k << 5) + i) * n + ((blockIdx.y + addy) << 5) + j];
	dyBlock[threadIdx.x] = x[(((blockIdx.x + addx) << 5) + i) * n + (k << 5) + j];
	int index1 = (((blockIdx.x + addx) << 5) + i) * n + ((blockIdx.y + addy) << 5) + j;
	cBlock[threadIdx.x] = x[index1];
	QcBlock[threadIdx.x] = qx[index1];

	for (int l = 0; l < 32; l++) {
		syncthreads();
		float temp2 = dyBlock[i * 32 + l] + dxBlock[l * 32 + j];
		if (cBlock[threadIdx.x] > temp2) {
			cBlock[threadIdx.x] = temp2;
			QcBlock[threadIdx.x] = l + k1;
		}
	}
	x[index1] = cBlock[threadIdx.x];
	qx[index1] = QcBlock[threadIdx.x];
}


int main(int argc, char **argv) {

	struct timeval first, second, lapsed, third, fourth, lapsed2;
	struct timezone tzp, tzp2;
	float *host_A, *host_D;
	int *host_Q;
	float *dev_x;
	int *dev_qx;
	float *A;
	int *Q;
	float *D;

	int i, j;
	int k = 0;
	float tolerance = 0.001;
	int n = atoi(argv[1]);

	printf("\n");
	printf("RUNNING WITH %d VERTICES \n", n);
	printf("\n");
	cudaMalloc(&dev_x, n * n * sizeof(float));
	cudaMalloc(&dev_qx, n * n * sizeof(float));

	//CPU arrays
	A = (float *)malloc(n * n * sizeof(float));
	D = (float *)malloc(n * n * sizeof(float));
	Q = (int *)malloc(n * n * sizeof(int));

	//GPU arrays
	host_A = (float *)malloc(n * n * sizeof(float));
	host_D = (float *)malloc(n * n * sizeof(float));
	host_Q = (int *)malloc(n * n * sizeof(int));

	srand(time(NULL));

	for (i = 0; i < n; i++) {
		for (j = 0; j < n; j++) {
			Q[i * n + j] = -1;
		}
	}
	for (i = 0; i < n; i++) {
		for (j = 0; j < n; j++) {
			if (i == j) {
				A[i * n + j] = 0;
			}
			else {
				A[i * n + j] = 1200 * (float)rand() / RAND_MAX + 1;
			
				if (A[i * n + j] > 1000) {
					A[i * n + j] = inf;
					Q[i * n + j] = -2;
				}
			}
		}
	}
	for (i = 0; i < n; i++) {
		for (j = 0; j < n; j++) {
			D[i * n + j] = A[i * n + j];
		}

	}
	for (i = 0; i < n; i++) {
		for (j = 0; j < n; j++) {
			host_A[i * n + j] = A[i * n + j];
		}

	}
	for (i = 0; i < n; i++) {
		for (j = 0; j < n; j++) {
			host_Q[i * n + j] = Q[i * n + j];
		}

	}

	printf("GPU running... \n");
	gettimeofday(&third, &tzp2);
	////////////////////////////First Mem Copy////////////////////
	gettimeofday(&first, &tzp);
	cudaMemcpy(dev_x, host_A, n * n * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_qx, host_Q, n * n * sizeof(int), cudaMemcpyHostToDevice);
	gettimeofday(&second, &tzp);
	if (first.tv_usec > second.tv_usec) {
		second.tv_usec += 1000000;
		second.tv_sec--;
	}
	lapsed.tv_usec = second.tv_usec - first.tv_usec;
	lapsed.tv_sec = second.tv_sec - first.tv_sec;
	printf("First Transfer CPU to GPU  Time elapsed: %lu,%06lu s\n", lapsed.tv_sec, lapsed.tv_usec);
	printf("\n");
	////////////////////////////////////////////////////GPU Calculation////////////////////////////////
	gettimeofday(&first, &tzp);
	dim3 bk2(n / 32 - 1, 2);
	dim3 bk3(n / 32 - 1, n / 32 - 1);
	int gputhreads = 1024;
	for (k = 0; k < n / 32; k++) {
		funct1 << <1, gputhreads >> >(n, k, dev_x, dev_qx);
		funct2 << <bk2, gputhreads >> >(n, k, dev_x, dev_qx);
		funct3 << <bk3, gputhreads >> >(n, k, dev_x, dev_qx);
	}
	cudaThreadSynchronize();
	gettimeofday(&second, &tzp);
	if (first.tv_usec > second.tv_usec) {
		second.tv_usec += 1000000;
		second.tv_sec--;
	}

	lapsed.tv_usec = second.tv_usec - first.tv_usec;
	lapsed.tv_sec = second.tv_sec - first.tv_sec;
	printf("GPU Calculation Time elapsed: %lu,%06lu s\n", lapsed.tv_sec, lapsed.tv_usec);
	printf("\n");
	//////////////////////////////////////////////////////////////////////////Second Mem Copy////////////////////
	gettimeofday(&first, &tzp);
	cudaMemcpy(host_D, dev_x, n * n * sizeof(float), cudaMemcpyDeviceToHost);
	cudaMemcpy(host_Q, dev_qx, n * n * sizeof(int), cudaMemcpyDeviceToHost);
	gettimeofday(&second, &tzp);
	if (first.tv_usec > second.tv_usec) {
		second.tv_usec += 1000000;
		second.tv_sec--;
	}
	lapsed.tv_usec = second.tv_usec - first.tv_usec;
	lapsed.tv_sec = second.tv_sec - first.tv_sec;
	printf("Second Transfer GPU to CPU  Time elapsed: %lu,%06lu s\n", lapsed.tv_sec, lapsed.tv_usec);
	printf("\n");
	//////////////////////////////////////////////////////////////////////

	gettimeofday(&fourth, &tzp2); //total time
	if (third.tv_usec > fourth.tv_usec) {
		fourth.tv_usec += 1000000;
		fourth.tv_sec--;
	}
	lapsed2.tv_usec = fourth.tv_usec - third.tv_usec;
	lapsed2.tv_sec = fourth.tv_sec - third.tv_sec;
	printf("TOTAL GPU + TRANSFERS  Time elapsed: %lu,%06lu s\n", lapsed2.tv_sec, lapsed2.tv_usec);
	printf("\n");
	//////////////////////////////////////////////////////////////
	//CPU RUN 

	printf("\n");
	printf("\n");
	printf(" Now running on CPU... \n");
	printf("\n");
	gettimeofday(&first, &tzp);
	for (k = 0; k < n; k++) {
		for (i = 0; i < n; i++) {
			for (j = 0; j < n; j++) {

				if ((D[i * n + k] + D[k * n + j]) < D[i * n + j]) {
					D[i * n + j] = D[i * n + k] + D[k * n + j];
					Q[i * n + j] = k;
				}
				if (D[i * n + j] == inf) {
					//Q[i*n+j]=-2;
				}
			}
		}
	}
	/////////////////////////////////////////////////////////////////
	gettimeofday(&second, &tzp);
	if (first.tv_usec > second.tv_usec) {
		second.tv_usec += 1000000;
		second.tv_sec--;
	}
	lapsed.tv_usec = second.tv_usec - first.tv_usec;
	lapsed.tv_sec = second.tv_sec - first.tv_sec;
	printf("CPU Time elapsed: %lu,%06lu s\n", lapsed.tv_sec, lapsed.tv_usec);
	/////////////////////////////////////////////////////
	printf(" \n");
	printf(" \n");
	/////////////FROM HERE AND UNDER ARE VALIDATION RUNS

	printf("VALIDATING THAT D array from CPU and host_D array from GPU match... \n");
	for (i = 0; i < n; i++) {
		for (j = 0; j < n; j++) {
			if (abs(D[i * n + j] - host_D[i * n + j]) > tolerance) {

				printf("ERROR MISMATCH in array D i %d j %d CPU SAYS %f and GPU SAYS %f \n", i, j, D[i * n + j], host_D[i * n + j]);
			}
		}
	}
	printf("OK \n");

	printf("ALL OK WE ARE DONE \n");
	return 0;
}
