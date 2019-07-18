
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "Stdafx.h"
#include "UniformGrid.h"
#include "ObjectLoader.h"
//#include "glut.h"

#define SCREEN_X 100 //Max x size of the grid
#define SCREEN_Y 100 //Max y size of the grid
#define SCREEN_Z 100 //Max z size of the grid

float cameraX = SCREEN_X / 2;
float cameraY = SCREEN_Y / 2;
float cameraZ = SCREEN_Z / 2;
float totalAngleX = 0.0;
float totalAngleY = 0.0;

int col = 0;
bool red = true, green = true, gridShown = true; //Used to toggle the red object, the green objects, and the cell on or off

ObjectLoader obj;
UniformGrid grids;

grid*** cell;

int* x;
int* y;
int* z;

int setgCO = 0;
int collisions = 0;

cudaError_t colDetCuda(grid* outputCel, int cellX, int cellY, int cellZ, int* coordX, int* dev_coordY, int* coordZ, unsigned int size, int pass);

__device__ int collisionChecker(grid* dev_cell, int x, int y, int z, int x2, int y2, int z2, int dev_cellX, int dev_cellY, int dev_cellZ)
{
	int collisionCount = 0; //Temporary count for the number of collisions found in the cell

	float distance = 0; //Used to store the distance between the objects being checked
	float comRadius = 0; //Used to store the combined radius of the two objects and then gets squared

	//Loop for the number of object in the cell
	for (int i = 0; i < dev_cell[(x * dev_cellX + y) * dev_cellZ + z].objCount; i++)
	{
		//Loop for the number of objects in the adjacent cell that hasn't been checked yet
		for (int j = 0; j < dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].objCount; j++)
		{
			//Calculate the distance between the two objects using pythagoras without the square root to work in square space
			distance = (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].x - dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].object[j].x) * (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].x - dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].object[j].x)
				+ (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].y - dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].object[j].y) * (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].y - dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].object[j].y)
				+ (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].z - dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].object[j].z) * (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].z - dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].object[j].z);

			//Add the radiuses of the two objects together
			comRadius = dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].r + dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].object[j].r;

			//Square the radius to work in square space
			comRadius *= comRadius;

			//Check if distance is less than or equal to the calculated radius - means a collision has occured
			if (distance <= comRadius)
			{
				collisionCount++; //increment the collision counter by 1
				dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].collided = true; //Set the bool the tells the object it's collided to true
				dev_cell[(x2 * dev_cellX + y2) * dev_cellZ + z2].object[j].collided = true; //Set the bool the tells the object it's collided to true
			}
		}
	}

	if (collisionCount > 0)
		return collisionCount; //Return the collision count found in this cell
	else
		return 0;
}

__device__ int currentCellCollisionDetection(grid* dev_cell, int x, int y, int z, int dev_cellX, int dev_cellY, int dev_cellZ)
{
	int collisionCount = 0; //Temporary count for the number of collisions found in the cell

	float distance = 0; //Used to store the distance between the objects being checked
	float comRadius = 0; //Used to store the combined radius of the two objects and then gets squared

	//Loop for the number of object in the cell
	if (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].objCount > 1)
	{
		//Loop for the number of object in the cell
		for (int i = 0; i < dev_cell[(x * dev_cellX + y) * dev_cellZ + z].objCount; i++)
		{
			//Loop for the number of objects in the cell that haven't been checked yet
			for (int j = i + 1; j < dev_cell[(x * dev_cellX + y) * dev_cellZ + z].objCount; j++)
			{
				//Calculate the distance between the two objects using pythagoras without the square root to work in square space
				distance = (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].x - dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[j].x) * (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].x - dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[j].x)
					+ (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].y - dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[j].y) * (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].y - dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[j].y)
					+ (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].z - dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[j].z) * (dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].z - dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[j].z);

				//Add the radiuses of the two objects together
				comRadius = dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].r + dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[j].r;

				//Square the radius to work in square space
				comRadius *= comRadius;

				//Check if distance is less than or equal to the calculated radius - means a collision has occured
				if (distance <= comRadius)
				{
					collisionCount++; //increment the collision counter by 1
					dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[i].collided = true; //Set the bool the tells the object it's collided to true
					dev_cell[(x * dev_cellX + y) * dev_cellZ + z].object[j].collided = true; //Set the bool the tells the object it's collided to true
				}
			}
		}
	}

	if (collisionCount > 0)
		return collisionCount; //Return the collision count found in this cell
	else
		return 0;
}

__global__ void colDetKernel(grid* dev_cell, gridsConObj* dev_gCO, int dev_cellX, int dev_cellY, int dev_cellZ, int* dev_coordX, int* dev_coordY, int* dev_coordZ, int dev_collision, unsigned int size)
{
	int i = threadIdx.x;

	//Stores if collision detections are needed
	bool ful = false, fum = false, fur = false, fml = false, fmm = false, fmr = false, fdl = false, fdm = false, fdr = false;
	bool mul = false, mum = false, mur = false, mml = false, mmr = false, mdl = false, mdm = false, mdr = false;
	bool bul = false, bum = false, bur = false, bml = false, bmm = false, bmr = false, bdl = false, bdm = false, bdr = false;

	//Check if collision detection is needed for the 9 cells infront of the current cell
	//Check if the cell being looked at isn't at the very front of the grid
	if (dev_gCO[dev_coordZ[i]].z > 0)
	{
		//Check if the cell being looked at is below the top of the grid
		if (dev_gCO[dev_coordY[i]].y < dev_cellY - 1)
		{
			//Check if cell being looked at isn't on the far left of the grid
			if (dev_gCO[dev_coordX[i]].x > 0)
			{
				if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
					ful = true;
			}

			//Check if a collision detection is needed
			if (dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
				fum = true;

			//Check if cell being looked at isn't on the far right of the grid
			if (dev_gCO[dev_coordX[i]].x < dev_cellX - 1)
			{
				if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
					fur = true;
			}
		}

		//Check if cell being looked at isn't on the far left of the grid
		if (dev_gCO[dev_coordX[i]].x > 0)
		{
			if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
				fml = true;
		}

		//Check if a collision detection is needed
		if (dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
			fmm = true;

		//Check if cell being looked at isn't on the far right of the grid
		if (dev_gCO[dev_coordX[i]].x < dev_cellX - 1)
		{
			if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
				fmr = true;
		}

		//Check if the cell being looked at is above the bottom of the grid
		if (dev_gCO[dev_coordY[i]].y > 0)
		{
			//Check if cell being looked at isn't on the far left of the grid
			if (dev_gCO[dev_coordX[i]].x > 0)
			{
				if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
					fdl = true;
			}
			if (dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
				fdm = true;

			//Check if cell being looked at isn't on the far right of the grid
			if (dev_gCO[dev_coordX[i]].x < dev_cellX - 1)
			{
				//+1 -1 -1
				if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z - 1))].objCount > 0)
					fdr = true;
			}
		}
	}
	//Check if collision detection is needed for the 9 cells infront of the current cell

	//Check if collision detection is needed for the 8 cells around the current cell
	//Check if the cell being looked at is below the top of the grid
	if (dev_gCO[dev_coordY[i]].y < dev_cellY - 1)
	{
		//Check if cell being looked at isn't on the far left of the grid
		if (dev_gCO[dev_coordX[i]].x > 0)
		{
			if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].objCount > 0)
				mul = true;
		}

		//Check if a collision detection is needed
		if (dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].objCount > 0)
			mum = true;

		//Check if cell being looked at isn't on the far right of the grid
		if (dev_gCO[dev_coordX[i]].x < dev_cellX - 1)
		{
			if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].objCount > 0)
				mur = true;
		}
	}

	//Check if cell being looked at isn't on the far left of the grid
	if (dev_gCO[dev_coordX[i]].x > 0)
	{
		if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].objCount > 0)
			mml = true;
	}

	//Check if cell being looked at isn't on the far right of the grid
	if (dev_gCO[dev_coordX[i]].x < dev_cellX - 1)
	{
		if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].objCount > 0)
			mmr = true;
	}

	//Check if the cell being looked at is above the bottom of the grid
	if (dev_gCO[dev_coordY[i]].y > 0)
	{
		//Check if cell being looked at isn't on the far left of the grid
		if (dev_gCO[dev_coordX[i]].x > 0)
		{
			if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].objCount > 0)
				mdl = true;
		}
		if (dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].objCount > 0)
			mdm = true;

		//Check if cell being looked at isn't on the far right of the grid
		if (dev_gCO[dev_coordX[i]].x < dev_cellX - 1)
		{
			if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].objCount > 0)
				mdr = true;
		}
	}
	//Check if collision detection is needed for the 8 cells around the current cell

	//Check if collision detection is needed for the 9 cells behind the current cell
	//Check if the cell being looked at isn't at the very back of the grid
	if (dev_gCO[dev_coordZ[i]].z != dev_cellZ - 1)
	{
		//Check if the cell being looked at is below the top of the grid
		if (dev_gCO[dev_coordY[i]].y != dev_cellY - 1)
		{
			//Check if cell being looked at isn't on the far left of the grid
			if (dev_gCO[dev_coordX[i]].x > 0)
			{
				if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
					bul = true;
			}
			if (dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
				bum = true;

			//Check if cell being looked at isn't on the far right of the grid
			if (dev_gCO[dev_coordX[i]].x != dev_cellX - 1)
			{
				if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y + 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
					bur = true;
			}
		}

		//Check if cell being looked at isn't on the far left of the grid
		if (dev_gCO[dev_coordX[i]].x > 0)
		{
			if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
				bml = true;
		}

		if (dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
			bmm = true;

		//Check if cell being looked at isn't on the far right of the grid
		if (dev_gCO[dev_coordX[i]].x != dev_cellX - 1)
		{
			if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
				bmr = true;
		}

		//Check if the cell being looked at is above the bottom of the grid
		if (dev_gCO[dev_coordY[i]].y != 0)
		{
			//Check if cell being looked at isn't on the far left of the grid
			if (dev_gCO[dev_coordX[i]].x != 0)
			{
				if (dev_cell[((dev_gCO[dev_coordX[i]].x - 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
					bdl = true;
			}
			if (dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
				bdm = true;

			//Check if cell being looked at isn't on the far right of the grid
			if (dev_gCO[dev_coordX[i]].x != dev_cellX - 1)
			{
				if (dev_cell[((dev_gCO[dev_coordX[i]].x + 1) * dev_cellX + ((dev_gCO[dev_coordY[i]].y - 1)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z + 1))].objCount > 0)
					bdr = true;
			}
		}

	}
	//Check if collision detection is needed for the 9 cells behind the current cell

	//Actual Collision Detection
	//Front 9 cells
	if (ful)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);
	if (fum)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);
	if (fur)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);

	if (fml)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);
	if (fmm)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);
	if (fmr)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);

	if (fdl)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);
	if (fdm)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);
	if (fdr)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z - 1, dev_cellX, dev_cellY, dev_cellZ);
	//Front 9 cells

	//Middle 8 cells
	if (mul)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);
	if (mum)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);
	if (mur)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);

	if (mml)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);
	if (mmr)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);

	if (mdl)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);
	if (mdm)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);
	if (mdr)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);
	//Middle 8 cells

	//Back 9 cells
	if (bul)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);
	if (bum)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);
	if (bur)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y + 1, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);

	if (bml)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);
	if (bmm)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);
	if (bmr)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);

	if (bdl)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x - 1, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);
	if (bdm)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);
	if (bdr)
		dev_collision += collisionChecker(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_gCO[dev_coordX[i]].x + 1, dev_gCO[dev_coordY[i]].y - 1, dev_gCO[dev_coordZ[i]].z + 1, dev_cellX, dev_cellY, dev_cellZ);
	//Back 9 cells

	dev_collision += currentCellCollisionDetection(dev_cell, dev_gCO[dev_coordX[i]].x, dev_gCO[dev_coordY[i]].y, dev_gCO[dev_coordZ[i]].z, dev_cellX, dev_cellY, dev_cellZ);

	dev_cell[((dev_gCO[dev_coordX[i]].x) * dev_cellX + ((dev_gCO[dev_coordY[i]].y)) * dev_cellZ + (dev_gCO[dev_coordZ[i]].z))].collisions = dev_collision;
}

void init()
{
	int objCount; //Stores the number of objects read from a file

	objCount = obj.objectCounter(); //Counts the number of objects to be loaded in

	grids.setobj(objCount); //Reads in the objects from the file

	float rad; //Stores the radius of the largest object

	rad = obj.objLoader(grids);

	grids.objCounter /= 4; //Divide the object counter by 4 since each object has four variables read in, making the count 4 times larger than it should be

	grids.setGrid(SCREEN_X, SCREEN_Y, SCREEN_Z, rad); //Creates the grid and cells

	grids.setObjectsInGrid(); //Add the objects to the cells they belong to

	x = new int[grids.objCounter]; //Set the size of the x array
	y = new int[grids.objCounter]; //Set the size of the y array
	z = new int[grids.objCounter]; //Set the size of the z array

	cell = grids.getGrid();

	int itemCount = 0;

	//Loop for the number of cells in the X
	for (int i = 0; i < grids.getCellNumX(); i++)
	{
		//Loop for the number of cells in the Y
		for (int j = 0; j < grids.getCellNumY(); j++)
		{
			//Loop for the number of cells in the Z
			for (int k = 0; k < grids.getCellNumZ(); k++)
			{
				//Check if the object count for the cell being looked at isn't 0
				if (cell[i][j][k].objCount != 0)
				{
					//Set the corresponding gCO x, y, z values to i, j, and k
					grids.gCO[setgCO].x = i;
					grids.gCO[setgCO].y = j;
					grids.gCO[setgCO].z = k;

					setgCO++; //Increment setgCO by 1

							  //Loop for the number of objects in the cell being looked at
					for (int l = 0; l < cell[i][j][k].objCount; l++)
					{
						x[itemCount] = i;
						y[itemCount] = j;
						z[itemCount] = k;

						itemCount++; //Increment itemCount by 1
					}
				}
			}
		}
	}

	//Output initialisation values - DEBUGGING
	cout << "CELL X: " << grids.getCellNumX() << endl;
	cout << "CELL Y: " << grids.getCellNumY() << endl;
	cout << "CELL Z: " << grids.getCellNumZ() << endl;
	cout << "SIZE OF GRID: " << grids.getCellNumX() * grids.getCellNumY() * grids.getCellNumZ() << endl;
	cout << "OBJECTS IN CELLS: " << grids.objCounter << endl;
	cout << "OBJECTS SAVED: " << itemCount << endl;
	cout << "CELLS CONTAINING OBJECTS: " << setgCO << endl;
	cout << "FINISHED INITIALISING" << endl;

	//collisionDetection();

	//glutMain(argc, argv);
}

int main()
{
	grid* outputCel; //Used to store the grid to be output from the kernel

	init(); //Handles initialising the objects and grid

	//Handles storing the number of threads to be used in each pass
	int passArray[27] = { 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 };

	//Loop for the number of cells in the x
	for (int i = 0; i < grids.cellNumX; i++)
	{
		//Loop for the number of cells in the y
		for (int j = 0; j < grids.cellNumY; j++)
		{
			//Loop for the number of cells in the z
			for (int k = 0; k < grids.cellNumZ; k++)
			{
				//Increment the pass being looked at's counter by 1
				passArray[cell[i][j][k].pass - 1]++;
			}
		}
	}

	//Dynamically allocate the size of the outputCel
	outputCel = new grid[grids.getCellNumX() * grids.getCellNumY() * grids.getCellNumZ()];

	//Loop for the number of passes to be done
	for (int l = 1; l < 28; l++)
	{
		int* xCoords; //Used to store the x position of the cells for whatever pass being looked at
		int* yCoords; //Used to store the y position of the cells for whatever pass being looked at
		int* zCoords; //Used to store the z position of the cells for whatever pass being looked at

		//Dynamically allocate the size of xCoords, yCoords, and zCoords
		xCoords = new int[passArray[l - 1]];
		yCoords = new int[passArray[l - 1]];
		zCoords = new int[passArray[l - 1]];

		int coordCount = 0;

		//Loop for the number of cells in the x
		for (int i = 0; i < grids.cellNumX; i++)
		{
			//Loop for the number of cells in the y
			for (int j = 0; j < grids.cellNumY; j++)
			{
				//Loop for the number of cells in the z
				for (int k = 0; k < grids.cellNumZ; k++)
				{
					//Check if the pass of the cell being looked at matches the pass being looked at
					if (cell[i][j][k].pass == l)
					{
						//Set the coordinates of the cell
						xCoords[coordCount] = i;
						yCoords[coordCount] = j;
						zCoords[coordCount] = k;

						coordCount++; //Increment the coordCount by 1
					}
				}
			}
		}

		//Call the colDetCuda function which handles setting up the kernels to be used
		cudaError_t cudaStatus = colDetCuda(outputCel, grids.getCellNumX(), grids.getCellNumY(), grids.getCellNumZ(), xCoords, yCoords, zCoords, passArray[l - 1], l);
		if (cudaStatus != cudaSuccess)
		{
			fprintf(stderr, "addWithCuda failed!");
			return 1;
		}
		
		//Loop for the number of cells in the x
		for (int i = 0; i < grids.getCellNumX(); i++)
		{
			//Loop for the number of cells in the y
			for (int j = 0; j < grids.getCellNumY(); j++)
			{
				//Loop for the number of cell in the z
				for (int k = 0; k < grids.getCellNumZ(); k++)
				{
					//Check if the pass value in the outputCel is the same as the current pass
					if (outputCel[(i * grids.getCellNumX() + j) * grids.getCellNumZ() + k].pass = l)
					{
						//Add the number of collisions done to the total number of collisions
						collisions += outputCel[(i * grids.getCellNumX() + j) * grids.getCellNumZ() + k].collisions;
					}
				}
			}
		}

		// cudaDeviceReset must be called before exiting in order for profiling and
		// tracing tools such as Nsight and Visual Profiler to show complete traces.
		cudaStatus = cudaDeviceReset();
		if (cudaStatus != cudaSuccess)
		{
			fprintf(stderr, "cudaDeviceReset failed!");
			return 1;
		}
	}

	//cout << "Test Value: " << cellC << endl;
	cout << "Collisions: " << collisions << endl;
    return 0;
}

// Helper function for using CUDA to perform uniform grid collision detection in parallel
cudaError_t colDetCuda(grid* outputCel, int cellX, int cellY, int cellZ, int* coordX, int* coordY, int* coordZ, unsigned int size, int pass)
{
    int *dev_coordX = 0; //coordX to be used on the device
    int *dev_coordY = 0; //coordY to be used on the device
    int *dev_coordZ = 0; //coordZ to be used on the device
	int dev_cellX = cellX; //cellX to be used on the device
	int dev_cellY = cellY; //cellY to be used on the device
	int dev_cellZ = cellZ; //cellZ to be used on the device
	int dev_collision = 0; //collision to be used on the device

	gridsConObj* dev_gCO; //gCO to be used on the device
	grid* cel; //cel to be used on the device
	grid* dev_cell; //cell to be used on the device

    cudaError_t cudaStatus;

	//Dynamically allocate the size of the cel
	cel = new grid[cellX * cellY * cellZ];

	//Loop for the number of cells in the x
	for (int i = 0; i < cellX; i++)
	{
		//Loop for the number of cells in the y
		for (int j = 0; j < cellY; j++)
		{
			//Loop for the number of cells in the z
			for (int k = 0; k < cellZ; k++)
			{
				//Copy the values in cell to cel
				cel[(i * cellX + j) * cellZ + k] = cell[i][j][k];
			}
		}
	}

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

	cudaStatus = cudaMalloc((void**)&dev_cell, size * sizeof(grid));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	//Loop for the number of cells in the x
	for (int i = 0; i < cellX; i++)
	{
		//Loop for the number of cells in the y
		for (int j = 0; j < cellY; j++)
		{
			//Loop for the number of cells in the z
			for (int k = 0; k < cellZ; k++)
			{
				cudaStatus = cudaMalloc((void**)&cel[(i * cellX + j) * cellZ + k].object, size * sizeof(objects));
				if (cudaStatus != cudaSuccess) {
					fprintf(stderr, "cudaMalloc failed!");
					goto Error;
				}

				cudaStatus = cudaMemcpy(cel[(i * cellX + j) * cellZ + k].object, cell[i][j][k].object, size * sizeof(objects), cudaMemcpyHostToDevice);
				if (cudaStatus != cudaSuccess) {
					fprintf(stderr, "cudaMemcpy failed!");
					goto Error;
				}
			}
		}
	}

	cudaStatus = cudaMalloc((void**)&dev_gCO, size * sizeof(gridsConObj));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

    cudaStatus = cudaMalloc((void**)&dev_coordX, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_coordY, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_coordZ, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(dev_cell, cel, size * sizeof(grid), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(&dev_cell->object, &cel->object, size * sizeof(objects), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_gCO, grids.gCO, size * sizeof(gridsConObj), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_coordX, coordX, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_coordY, coordY, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

	cudaStatus = cudaMemcpy(dev_coordZ, coordZ, size * sizeof(int), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

    // Launch a kernel on the GPU with one thread for each element.
    colDetKernel<<<1, size>>>(dev_cell, dev_gCO, dev_cellX, dev_cellY, dev_cellZ, dev_coordX, dev_coordY, dev_coordZ, dev_collision, size);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(&outputCel->object, &dev_cell->object, size * sizeof(objects), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(outputCel, dev_cell, size * sizeof(grid), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}
	
Error:
	cudaFree(dev_coordX);
	cudaFree(dev_coordY);
	cudaFree(dev_coordZ);

	cudaFree(dev_cell);
	cudaFree(dev_gCO);
	cudaFree(cel->object);
    return cudaStatus;
}