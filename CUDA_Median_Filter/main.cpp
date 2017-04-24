#include<stdio.h>
#include<iostream>
#include "MedianFilter.h"
#include "Bitmap.h"
#include <ctime> // time(), clock()

const int window_size = WINDOW_SIZE;
#define ITERATIONS ( 1 )


//Compare function for comparing two images.

int CompareBitmaps(Bitmap* inputA, Bitmap* inputB) {
	int differentpixels = 0;               //Initializing the diffrerce Variable.
	if ((inputA->Height() != inputB->Height()) || (inputA->Width() != inputB->Width()))  // Check the condition for height and width matching. 
		return -1;
	for (int height = 1; height<inputA->Height() - 1; height++) {
		for (int width = 1; width<inputA->Width() - 1; width++) {
			if (inputA->GetPixel(width, height) != inputB->GetPixel(width, height))
				differentpixels++;   // increment the differences.
		}
	}
	return differentpixels;
}



//CPU function for Median Filtering.

void MedianFilterCPU(Bitmap* image, Bitmap* outputImage)
{
	unsigned char filterVector[9] = { 0,0,0,0,0,0,0,0,0 };   //Taking the filter initialization. 
	for (int row = 0; row<image->Height(); row++) {
		for (int col = 0; col<image->Width(); col++) {
			if ((row == 0) || (col == 0) || (row == image->Height() - 1) || (col == image->Width() - 1))   //Check the boundry condition.
				outputImage->SetPixel(col, row, 0);
			else {
				for (int x = 0; x < WINDOW_SIZE; x++) {
					for (int y = 0; y < WINDOW_SIZE; y++) {
						filterVector[x*WINDOW_SIZE + y] = image->GetPixel((col + y - 1), (row + x - 1));     //Fill the Filter Vector 
					}
				}
				// logic for bubble sort. 
				for (int i = 0; i < 9; i++) {
					for (int j = i + 1; j < 9; j++) {
						if (filterVector[i] > filterVector[j]) {
							//Logic for swap
							char tmp = filterVector[i];
							filterVector[i] = filterVector[j];
							filterVector[j] = tmp;
						}
					}
				}
				outputImage->SetPixel(col, row, filterVector[4]);  //Finally assign value to output pixels

			}
		}
	}
}


//main method


int main()
{
	//Initilize images. 
	Bitmap* originalImage = new Bitmap();
	Bitmap* resultImageCPU = new Bitmap();
	Bitmap* resultImageGPU = new Bitmap();
	Bitmap* resultImageSharedGPU = new Bitmap();

	float tcpu, tgpu, tgpushared;   //timing variables.
	clock_t start, end;

	//Set the images.
	originalImage->Load("chineseguy.bmp");
	resultImageCPU->Load("chineseguy.bmp");
	resultImageGPU->Load("chineseguy.bmp");
	resultImageSharedGPU->Load("chineseguy.bmp");

	std::cout  << "\nDimensiunea imaginii: " <<  originalImage->Width() << " x " << originalImage->Height() <<" px"<< std::endl;

	start = clock();  //Stat the clock
	for (int i = 0; i < ITERATIONS; i++)
	{
		MedianFilterCPU(originalImage, resultImageCPU);
	}
	end = clock();  //End the clock
	tcpu = (float)(end - start) * 1000 / (float)CLOCKS_PER_SEC / ITERATIONS;

	//Check the GPU wakeup
	int success = MedianFilterGPU(originalImage, resultImageGPU, false);    //Kernel calling without shared memory.
	if (!success) {
		std::cout << "\n * Device Error! * \n" << "\n" << std::endl;
		return 1;
	}

	start = clock();
	for (int i = 0; i < ITERATIONS; i++)
	{
		MedianFilterGPU(originalImage, resultImageGPU, false);
	}
	end = clock();
	tgpu = (float)(end - start) * 1000 / (float)CLOCKS_PER_SEC / ITERATIONS;

	success = MedianFilterGPU(originalImage, resultImageGPU, true);
	if (!success) {
		std::cout << "\n * Device Error! * \n" << "\n" << std::endl;
		return 1;
	}
	start = clock();   //Start timer again
	for (int i = 0; i < ITERATIONS; i++)
	{
		MedianFilterGPU(originalImage, resultImageSharedGPU, true);    //GPU call for median Filtering with shared Kernel.
	}
	end = clock();
	tgpushared = (float)(end - start) * 1000 / (float)CLOCKS_PER_SEC / ITERATIONS;

	std::cout << "Timpul mediu al unei iteratii pe CPU: " << tcpu << " ms" << std::endl << std::endl;

	std::cout << "Timpul mediu al unei iteratii pe GPU cu memorie partajata: " << tgpushared << " ms" << std::endl;			//Compare bitmaps for GPU shared and CPU.
	std::cout << CompareBitmaps(resultImageCPU, resultImageSharedGPU) << " pixeli diferiti fata de rularea pe CPU" << std::endl << std::endl; 

	std::cout << "Timpul mediu al unei iteratii pe GPU cu memorie globala: " << tgpu << " ms" << std::endl;					//Compare bitmaps for GPU and CPU.
	std::cout << CompareBitmaps(resultImageCPU, resultImageGPU) << " pixeli diferiti fata de rularea pe CPU" << std::endl;    


																															//Save the images.
	resultImageCPU->Save("lessNoise.bmp");
	resultImageGPU->Save("lessNoise.bmp");
	resultImageSharedGPU->Save("lessNoise.bmp");
}