#include "UniformGrid.h"

UniformGrid::UniformGrid()
{
	maxR = 0.0;
}

UniformGrid::~UniformGrid()
{
}

//Handles setting the size of the object structure
void UniformGrid::setobj(int objCount)
{
	object = new objects[(objCount)];
	objCounter = (objCount + 1);
}

//Handles storing the objects read in from the file
float UniformGrid::setObject(float x, float y, float z, float r, int objCount)
{
	//Set the values for the objects
	this->object[objCount].x = x;
	this->object[objCount].y = y;
	this->object[objCount].z = z;
	this->object[objCount].r = r;

	//objCounter = objCount + 1;

	//system("cls");
	//Store the largest radius
	if (r > maxR || maxR == 10)
		maxR = r;

	return maxR;
}

//Handles setting the grid values and cells
void UniformGrid::setGrid(int screenX, int screenY, int screenZ, float rad)
{
	//Holds the size of the cells - atleast as big as the largest object
	int cellSize = round((rad * 2));

	//Ensure the size of the cells is larger than the largest object
	if (cellSize < (rad * 2))
		cellSize++;

	//Calculate the number of cells to be made in the grid
	cellNumX = screenX / cellSize;
	cellNumY = screenY / cellSize;
	cellNumZ = screenZ / cellSize;

	//Set the size of the cells structure in the x dimension
	cells = new grid**[cellNumX];

	//Set the size of the cells structure in the y dimension
	for (int i = 0; i < cellNumX; i++)
	{
		cells[i] = new grid*[cellNumY];
	}

	//Set the size of the cells structure in the z dimension
	for (int i = 0; i < cellNumX; i++)
	{
		for (int j = 0; j < cellNumY; j++)
		{
			cells[i][j] = new grid[cellNumZ];
		}
	}

	//Set the coordinates of each cell
	//Loop for the number of cells in the X
	for (int i = 0; i < cellNumX; i++)
	{
		//Loop for the number of cells in the y
		for (int j = 0; j < cellNumY; j++)
		{	
			//Loop for the number of cells in the z
			for (int k = 0; k < cellNumZ; k++)
			{
				setCellNumber(i, j, k);

				cells[i][j][k].minX = i * cellSize;
				cells[i][j][k].maxX = (i + 1) * cellSize;

				cells[i][j][k].minY = j * cellSize;
				cells[i][j][k].maxY = (j + 1) * cellSize;

				cells[i][j][k].minZ = k * cellSize;
				cells[i][j][k].maxZ = (k + 1) * cellSize;

				cells[i][j][k].object = new objects[objCounter];
			}
		}
	}
}

void UniformGrid::setCellNumber(int i, int j, int k)
{
	//FRONT 9 CELLS
	//Pass 1
	if (i == 0 && j == 0 && k == 0
		|| i != 0 && i % 3 == 0 && j == 0 && k == 0
		|| j != 0 && i == 0 && j % 3 == 0 && k == 0
		|| i != 0 && j != 0 && i % 3 == 0 && j % 3 == 0 && k == 0
		|| k != 0 && i == 0 && j == 0 && k % 3 == 0
		|| j != 0 && k != 0 && i == 0 && j % 3 == 0 && k % 3 == 0
		|| i != 0 && k != 0 && i % 3 == 0 && j == 0 && k % 3 == 0
		|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % 3 == 0 && k % 3 == 0)
	{
		cells[i][j][k].pass = 1;
	}

	//Pass 2
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		if (i == 1 && j == 0 && k == 0
			|| i != 0 && i % checkerX == 0 && j == 0 && k == 0
			|| j != 0 && i == 1 && j % 3 == 0 && k == 0
			|| i != 0 && j != 0 && i % checkerX == 0 && j % 3 == 0 & k == 0
			|| k != 0 && i == 1 && j == 0 && k % 3 == 0
			|| j != 0 && k != 0 && i == 1 && j % 3 == 0 && k % 3 == 0
			|| i != 0 && k != 0 && i % checkerX == 0 && j == 0 && k % 3 == 0
			|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % 3 == 0 && k % 3 == 0)
		{
			cells[i][j][k].pass = 2;
		}
	}

	//Pass 3
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		if (i == 2 && j == 0 && k == 0
			|| i != 0 && i % checkerX == 0 && j == 0 && k == 0
			|| j != 0 && i == 2 && j % 3 == 0 && k == 0
			|| i != 0 && j != 0 && i % checkerX == 0 && j % 3 == 0 & k == 0
			|| k != 0 && i == 2 && j == 0 && k % 3 == 0
			|| j != 0 && k != 0 && i == 2 && j % 3 == 0 && k % 3 == 0
			|| i != 0 && k != 0 && i % checkerX == 0 && j == 0 && k % 3 == 0
			|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % 3 == 0 && k % 3 == 0)
		{
			cells[i][j][k].pass = 3;
		}
	}

	//Pass 4
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerY = 4 + (l * 3);

		if (i == 0 && j == 1 && k == 0
			|| i != 0 && i % 3 == 0 && j == 1 && k == 0
			|| j != 0 && i == 0 && j % checkerY == 0 && k == 0
			|| i != 0 && j != 0 && i % 3 == 0 && j % checkerY == 0 & k == 0
			|| k != 0 && i == 0 && j == 1 && k % 3 == 0
			|| j != 0 && k != 0 && i == 0 && j % checkerY == 0 && k % 3 == 0
			|| i != 0 && k != 0 && i % 3 == 0 && j == 1 && k % 3 == 0
			|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % checkerY == 0 && k % 3 == 0)
		{
			cells[i][j][k].pass = 4;
		}
	}

	//Pass 5
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 4 + (m * 3);

			if (i == 1 && j == 1 && k == 0
				|| i != 0 && i % checkerX == 0 && j == 1 && k == 0
				|| j != 0 && i == 1 && j % checkerY == 0 && k == 0
				|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 0
				|| k != 0 && i == 1 && j == 1 && k % 3 == 0
				|| j != 0 && k != 0 && i == 1 && j % checkerY == 0 && k % 3 == 0
				|| i != 0 && k != 0 && i % checkerX == 0 && j == 1 && k % 3 == 0
				|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % 3 == 0)
			{
				cells[i][j][k].pass = 5;
			}
		}
	}

	//Pass 6
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 4 + (m * 3);

			if (i == 2 && j == 1 && k == 0
				|| i != 0 && i % checkerX == 0 && j == 1 && k == 0
				|| j != 0 && i == 2 && j % checkerY == 0 && k == 0
				|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 0
				|| k != 0 && i == 2 && j == 1 && k % 3 == 0
				|| j != 0 && k != 0 && i == 2 && j % checkerY == 0 && k % 3 == 0
				|| i != 0 && k != 0 && i % checkerX == 0 && j == 1 && k % 3 == 0
				|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % 3 == 0)
			{
				cells[i][j][k].pass = 6;
			}
		}
	}

	//Pass 7
	for (int l = 0; l < cellNumY; l++)
	{
		int checkerY = 5 + (l * 3);

		if (i == 0 && j == 2 && k == 0
			|| i != 0 && i % 3 == 0 && j == 2 && k == 0
			|| j != 0 && i == 0 && j % checkerY == 0 && k == 0
			|| i != 0 && j != 0 && i % 3 == 0 && j % checkerY == 0 & k == 0
			|| k != 0 && i == 0 && j == 2 && k % 3 == 0
			|| j != 0 && k != 0 && i == 0 && j % checkerY == 0 && k % 3 == 0
			|| i != 0 && k != 0 && i % 3 == 0 && j == 2 && k % 3 == 0
			|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % checkerY == 0 && k % 3 == 0)
		{
			cells[i][j][k].pass = 7;
		}
	}

	//Pass 8
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 5 + (m * 3);

			if (i == 1 && j == 2 && k == 0
				|| i != 0 && i % checkerX == 0 && j == 2 && k == 0
				|| j != 0 && i == 1 && j % checkerY == 0 && k == 0
				|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 0
				|| k != 0 && i == 1 && j == 2 && k % 3 == 0
				|| j != 0 && k != 0 && i == 1 && j % checkerY == 0 && k % 3 == 0
				|| i != 0 && k != 0 && i % checkerX == 0 && j == 2 && k % 3 == 0
				|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % 3 == 0)
			{
				cells[i][j][k].pass = 8;
			}
		}
	}

	//Pass 9
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 5 + (m * 3);

			if (i == 2 && j == 2 && k == 0
				|| i != 0 && i % checkerX == 0 && j == 2 && k == 0
				|| j != 0 && i == 2 && j % checkerY == 0 && k == 0
				|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 0
				|| k != 0 && i == 2 && j == 2 && k % 3 == 0
				|| j != 0 && k != 0 && i == 2 && j % checkerY == 0 && k % 3 == 0
				|| i != 0 && k != 0 && i % checkerX == 0 && j == 2 && k % 3 == 0
				|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % 3 == 0)
			{
				cells[i][j][k].pass = 9;
			}
		}
	}
	//FRONT 9 CELLS

	//MIDDLE 9 CELLS
	//Pass 10
	for (int l = 0; l < cellNumZ; l++)
	{
		int checkerZ = 4 + (l * 3);

		if (i == 0 && j == 0 && k == 1
			|| i != 0 && i % 3 == 0 && j == 0 && k == 1
			|| j != 0 && i == 0 && j % 3 == 0 && k == 1
			|| i != 0 && j != 0 && i % 3 == 0 && j % 3 == 0 & k == 1
			|| k != 0 && i == 0 && j == 0 && k % checkerZ == 0
			|| j != 0 && k != 0 && i == 0 && j % 3 == 0 && k % checkerZ == 0
			|| i != 0 && k != 0 && i % 3 == 0 && j == 0 && k % checkerZ == 0
			|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % 3 == 0 && k % checkerZ == 0)
		{
			cells[i][j][k].pass = 10;
		}
	}

	//Pass 11
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		for (int m = 0; m < cellNumZ; m++)
		{
			int checkerZ = 4 + (m * 3);

			if (i == 1 && j == 0 && k == 1
				|| i != 0 && i % checkerX == 0 && j == 0 && k == 1
				|| j != 0 && i == 1 && j % 3 == 0 && k == 1
				|| i != 0 && j != 0 && i % checkerX == 0 && j % 3 == 0 & k == 1
				|| k != 0 && i == 1 && j == 0 && k % checkerZ == 0
				|| j != 0 && k != 0 && i == 1 && j % 3 == 0 && k % checkerZ == 0
				|| i != 0 && k != 0 && i % checkerX == 0 && j == 0 && k % checkerZ == 0
				|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % 3 == 0 && k % checkerZ == 0)
			{
				cells[i][j][k].pass = 11;
			}
		}
	}

	//Pass 12
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		for (int m = 0; m < cellNumZ; m++)
		{
			int checkerZ = 4 + (m * 3);

			if (i == 2 && j == 0 && k == 1
				|| i != 0 && i % checkerX == 0 && j == 0 && k == 1
				|| j != 0 && i == 2 && j % 3 == 0 && k == 1
				|| i != 0 && j != 0 && i % checkerX == 0 && j % 3 == 0 & k == 1
				|| k != 0 && i == 2 && j == 0 && k % checkerZ == 0
				|| j != 0 && k != 0 && i == 2 && j % 3 == 0 && k % checkerZ == 0
				|| i != 0 && k != 0 && i % checkerX == 0 && j == 0 && k % checkerZ == 0
				|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % 3 == 0 && k % checkerZ == 0)
			{
				cells[i][j][k].pass = 12;
			}
		}
	}

	//Pass 13
	for (int l = 0; l < cellNumY; l++)
	{
		int checkerY = 4 + (l * 3);

		for (int m = 0; m < cellNumZ; m++)
		{
			int checkerZ = 4 + (m * 3);

			if (i == 0 && j == 1 && k == 1
				|| i != 0 && i % 3 == 0 && j == 1 && k == 1
				|| j != 0 && i == 0 && j % checkerY == 0 && k == 1
				|| i != 0 && j != 0 && i % 3 == 0 && j % checkerY == 0 & k == 1
				|| k != 0 && i == 0 && j == 1 && k % checkerZ == 0
				|| j != 0 && k != 0 && i == 0 && j % checkerY == 0 && k % checkerZ == 0
				|| i != 0 && k != 0 && i % 3 == 0 && j == 1 && k % checkerZ == 0
				|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % checkerY == 0 && k % checkerZ == 0)
			{
				cells[i][j][k].pass = 13;
			}
		}
	}

	//Pass 14
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 4 + (m * 3);

			for (int n = 0; n < cellNumZ; n++)
			{
				int checkerZ = 4 + (n * 3);

				if (i == 1 && j == 1 && k == 1
					|| i != 0 && i % checkerX == 0 && j == 1 && k == 1
					|| j != 0 && i == 1 && j % checkerY == 0 && k == 1
					|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 1
					|| k != 0 && i == 1 && j == 1 && k % checkerZ == 0
					|| j != 0 && k != 0 && i == 1 && j % checkerY == 0 && k % checkerZ == 0
					|| i != 0 && k != 0 && i % checkerX == 0 && j == 1 && k % checkerZ == 0
					|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % checkerZ == 0)
				{
					cells[i][j][k].pass = 14;
				}
			}
		}
	}

	//Pass 15
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 4 + (m * 3);

			for (int n = 0; n < cellNumZ; n++)
			{
				int checkerZ = 4 + (n * 3);

				if (i == 2 && j == 1 && k == 1
					|| i != 0 && i % checkerX == 0 && j == 1 && k == 1
					|| j != 0 && i == 2 && j % checkerY == 0 && k == 1
					|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 1
					|| k != 0 && i == 2 && j == 1 && k % checkerZ == 0
					|| j != 0 && k != 0 && i == 2 && j % checkerY == 0 && k % checkerZ == 0
					|| i != 0 && k != 0 && i % checkerX == 0 && j == 1 && k % checkerZ == 0
					|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % checkerZ == 0)
				{
					cells[i][j][k].pass = 15;
				}
			}
		}
	}

	//Pass 16
	for (int l = 0; l < cellNumY; l++)
	{
		int checkerY = 5 + (l * 3);

		for (int m = 0; m < cellNumZ; m++)
		{
			int checkerZ = 4 + (m * 3);

			if (i == 0 && j == 2 && k == 1
				|| i != 0 && i % 3 == 0 && j == 2 && k == 1
				|| j != 0 && i == 0 && j % checkerY == 0 && k == 1
				|| i != 0 && j != 0 && i % 3 == 0 && j % checkerY == 0 & k == 1
				|| k != 0 && i == 0 && j == 2 && k % checkerZ == 0
				|| j != 0 && k != 0 && i == 0 && j % checkerY == 0 && k % checkerZ == 0
				|| i != 0 && k != 0 && i % 3 == 0 && j == 2 && k % checkerZ == 0
				|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % checkerY == 0 && k % checkerZ == 0)
			{
				cells[i][j][k].pass = 16;
			}
		}
	}

	//Pass 17
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 5 + (m * 3);

			for (int n = 0; n < cellNumZ; n++)
			{
				int checkerZ = 4 + (n * 3);

				if (i == 1 && j == 2 && k == 1
					|| i != 0 && i % checkerX == 0 && j == 2 && k == 1
					|| j != 0 && i == 1 && j % checkerY == 0 && k == 1
					|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 1
					|| k != 0 && i == 1 && j == 2 && k % checkerZ == 0
					|| j != 0 && k != 0 && i == 1 && j % checkerY == 0 && k % checkerZ == 0
					|| i != 0 && k != 0 && i % checkerX == 0 && j == 2 && k % checkerZ == 0
					|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % checkerZ == 0)
				{
					cells[i][j][k].pass = 17;
				}
			}
		}
	}

	//Pass 18
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 5 + (m * 3);

			for (int n = 0; n < cellNumZ; n++)
			{
				int checkerZ = 4 + (n * 3);

				if (i == 2 && j == 2 && k == 1
					|| i != 0 && i % checkerX == 0 && j == 2 && k == 1
					|| j != 0 && i == 2 && j % checkerY == 0 && k == 1
					|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 1
					|| k != 0 && i == 2 && j == 2 && k % checkerZ == 0
					|| j != 0 && k != 0 && i == 2 && j % checkerY == 0 && k % checkerZ == 0
					|| i != 0 && k != 0 && i % checkerX == 0 && j == 2 && k % checkerZ == 0
					|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % checkerZ == 0)
				{
					cells[i][j][k].pass = 18;
				}
			}
		}
	}
	//MIDDLE 9 CELLS

	//Back 9 CELLS
	//Pass 19
	for (int l = 0; l < cellNumZ; l++)
	{
		int checkerZ = 5 + (l * 3);

		if (i == 0 && j == 0 && k == 2
			|| i != 0 && i % 3 == 0 && j == 0 && k == 2
			|| j != 0 && i == 0 && j % 3 == 0 && k == 2
			|| i != 0 && j != 0 && i % 3 == 0 && j % 3 == 0 & k == 2
			|| k != 0 && i == 0 && j == 0 && k % checkerZ == 0
			|| j != 0 && k != 0 && i == 0 && j % 3 == 0 && k % checkerZ == 0
			|| i != 0 && k != 0 && i % 3 == 0 && j == 0 && k % checkerZ == 0
			|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % 3 == 0 && k % checkerZ == 0)
		{
			cells[i][j][k].pass = 19;
		}
	}

	//Pass 20
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		for (int m = 0; m < cellNumZ; m++)
		{
			int checkerZ = 5 + (m * 3);

			if (i == 1 && j == 0 && k == 2
				|| i != 0 && i % checkerX == 0 && j == 0 && k == 2
				|| j != 0 && i == 1 && j % 3 == 0 && k == 2
				|| i != 0 && j != 0 && i % checkerX == 0 && j % 3 == 0 & k == 2
				|| k != 0 && i == 1 && j == 0 && k % checkerZ == 0
				|| j != 0 && k != 0 && i == 1 && j % 3 == 0 && k % checkerZ == 0
				|| i != 0 && k != 0 && i % checkerX == 0 && j == 0 && k % checkerZ == 0
				|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % 3 == 0 && k % checkerZ == 0)
			{
				cells[i][j][k].pass = 20;
			}
		}
	}

	//Pass 21
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		for (int m = 0; m < cellNumZ; m++)
		{
			int checkerZ = 5 + (m * 3);

			if (i == 2 && j == 0 && k == 2
				|| i != 0 && i % checkerX == 0 && j == 0 && k == 2
				|| j != 0 && i == 2 && j % 3 == 0 && k == 2
				|| i != 0 && j != 0 && i % checkerX == 0 && j % 3 == 0 & k == 2
				|| k != 0 && i == 2 && j == 0 && k % checkerZ == 0
				|| j != 0 && k != 0 && i == 2 && j % 3 == 0 && k % checkerZ == 0
				|| i != 0 && k != 0 && i % checkerX == 0 && j == 0 && k % checkerZ == 0
				|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % 3 == 0 && k % checkerZ == 0)
			{
				cells[i][j][k].pass = 21;
			}
		}
	}

	//Pass 22
	for (int l = 0; l < cellNumY; l++)
	{
		int checkerY = 4 + (l * 3);

		for (int m = 0; m < cellNumZ; m++)
		{
			int checkerZ = 5 + (m * 3);

			if (i == 0 && j == 1 && k == 2
				|| i != 0 && i % 3 == 0 && j == 1 && k == 2
				|| j != 0 && i == 0 && j % checkerY == 0 && k == 2
				|| i != 0 && j != 0 && i % 3 == 0 && j % checkerY == 0 & k == 2
				|| k != 0 && i == 0 && j == 1 && k % checkerZ == 0
				|| j != 0 && k != 0 && i == 0 && j % checkerY == 0 && k % checkerZ == 0
				|| i != 0 && k != 0 && i % 3 == 0 && j == 1 && k % checkerZ == 0
				|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % checkerY == 0 && k % checkerZ == 0)
			{
				cells[i][j][k].pass = 22;
			}
		}
	}

	//Pass 23
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 4 + (m * 3);

			for (int n = 0; n < cellNumZ; n++)
			{
				int checkerZ = 5 + (n * 3);

				if (i == 1 && j == 1 && k == 2
					|| i != 0 && i % checkerX == 0 && j == 1 && k == 2
					|| j != 0 && i == 1 && j % checkerY == 0 && k == 2
					|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 2
					|| k != 0 && i == 1 && j == 1 && k % checkerZ == 0
					|| j != 0 && k != 0 && i == 1 && j % checkerY == 0 && k % checkerZ == 0
					|| i != 0 && k != 0 && i % checkerX == 0 && j == 1 && k % checkerZ == 0
					|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % checkerZ == 0)
				{
					cells[i][j][k].pass = 23;
				}
			}
		}
	}

	//Pass 24
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 4 + (m * 3);

			for (int n = 0; n < cellNumZ; n++)
			{
				int checkerZ = 5 + (n * 3);

				if (i == 2 && j == 1 && k == 2
					|| i != 0 && i % checkerX == 0 && j == 1 && k == 2
					|| j != 0 && i == 2 && j % checkerY == 0 && k == 2
					|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 2
					|| k != 0 && i == 2 && j == 1 && k % checkerZ == 0
					|| j != 0 && k != 0 && i == 2 && j % checkerY == 0 && k % checkerZ == 0
					|| i != 0 && k != 0 && i % checkerX == 0 && j == 1 && k % checkerZ == 0
					|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % checkerZ == 0)
				{
					cells[i][j][k].pass = 24;
				}
			}
		}
	}

	//Pass 25
	for (int l = 0; l < cellNumY; l++)
	{
		int checkerY = 5 + (l * 3);

		for (int m = 0; m < cellNumZ; m++)
		{
			int checkerZ = 5 + (m * 3);

			if (i == 0 && j == 2 && k == 2
				|| i != 0 && i % 3 == 0 && j == 2 && k == 2
				|| j != 0 && i == 0 && j % checkerY == 0 && k == 2
				|| i != 0 && j != 0 && i % 3 == 0 && j % checkerY == 0 & k == 2
				|| k != 0 && i == 0 && j == 2 && k % checkerZ == 0
				|| j != 0 && k != 0 && i == 0 && j % checkerY == 0 && k % checkerZ == 0
				|| i != 0 && k != 0 && i % 3 == 0 && j == 2 && k % checkerZ == 0
				|| i != 0 && j != 0 && k != 0 && i % 3 == 0 && j % checkerY == 0 && k % checkerZ == 0)
			{
				cells[i][j][k].pass = 25;
			}
		}
	}

	//Pass 26
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 4 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 5 + (m * 3);

			for (int n = 0; n < cellNumZ; n++)
			{
				int checkerZ = 5 + (n * 3);

				if (i == 1 && j == 2 && k == 2
					|| i != 0 && i % checkerX == 0 && j == 2 && k == 2
					|| j != 0 && i == 1 && j % checkerY == 0 && k == 2
					|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 2
					|| k != 0 && i == 1 && j == 2 && k % checkerZ == 0
					|| j != 0 && k != 0 && i == 1 && j % checkerY == 0 && k % checkerZ == 0
					|| i != 0 && k != 0 && i % checkerX == 0 && j == 2 && k % checkerZ == 0
					|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % checkerZ == 0)
				{
					cells[i][j][k].pass = 26;
				}
			}
		}
	}

	//Pass 27
	for (int l = 0; l < cellNumX; l++)
	{
		int checkerX = 5 + (l * 3);

		for (int m = 0; m < cellNumY; m++)
		{
			int checkerY = 5 + (m * 3);

			for (int n = 0; n < cellNumZ; n++)
			{
				int checkerZ = 5 + (n * 3);

				if (i == 2 && j == 2 && k == 2
					|| i != 0 && i % checkerX == 0 && j == 2 && k == 2
					|| j != 0 && i == 2 && j % checkerY == 0 && k == 2
					|| i != 0 && j != 0 && i % checkerX == 0 && j % checkerY == 0 & k == 2
					|| k != 0 && i == 2 && j == 2 && k % checkerZ == 0
					|| j != 0 && k != 0 && i == 2 && j % checkerY == 0 && k % checkerZ == 0
					|| i != 0 && k != 0 && i % checkerX == 0 && j == 2 && k % checkerZ == 0
					|| i != 0 && j != 0 && k != 0 && i % checkerX == 0 && j % checkerY == 0 && k % checkerZ == 0)
				{
					cells[i][j][k].pass = 27;
				}
			}
		}
	}
	//Back 9 CELLS

	if (cells[i][j][k].pass < 0)
		cout << "ERROR ASSIGNING A NUMBER TO THE CELL" << endl;

}

void UniformGrid::setObjectsInGrid()
{
	//Loop for the number of objects
	for (int i = 0; i < objCounter; i++)
	{
		bool objLoaded = false; //Used to store if an object has already been set

		//Loop for the number of cells in the X
		for (int j = 0; j < cellNumX; j++)
		{
			//Loop for the number of cells in the Y
			for (int k = 0; k < cellNumY; k++)
			{
				//Loop for the number of cells in the Z
				for (int l = 0; l < cellNumZ; l++)
				{

					//Check if the object being looked at is in the cell being looked at
					if (object[i].x >= cells[j][k][l].minX && object[i].x <= cells[j][k][l].maxX)
					{
						if (object[i].y >= cells[j][k][l].minY && object[i].y <= cells[j][k][l].maxY)
						{
							if (object[i].z >= cells[j][k][l].minZ && object[i].z <= cells[j][k][l].maxZ)
							{
								//Check if the object has already been added to another cell
								if (!objLoaded)
								{
									//Add the object variables to the cell it's added to
									cells[j][k][l].object[cells[j][k][l].objCount].x = object[i].x;
									cells[j][k][l].object[cells[j][k][l].objCount].y = object[i].y;
									cells[j][k][l].object[cells[j][k][l].objCount].z = object[i].z;
									cells[j][k][l].object[cells[j][k][l].objCount].r = object[i].r;

									objLoaded = true; //Set objLoaded to true

									cells[j][k][l].objCount++; //Increment the number of objects in that cell by 1

															   //Check if the cell's objAdded is false
									if (!cells[j][k][l].objAdded)
									{
										cells[j][k][l].objAdded = true; //Set the cell's objAdded to true
										cellObjCount++; //Increment the number of objects added to cells by 1
									}

								}
							}
						}
					}
				}
			}
		}
	}

	gCO = new gridsConObj[cellObjCount]; //Set the size of gCO
}

grid*** UniformGrid::getGrid()
{
	return cells;
}

int UniformGrid::getCellNumX()
{
	return cellNumX;
}

int UniformGrid::getCellNumY()
{
	return cellNumY;
}

int UniformGrid::getCellNumZ()
{
	return cellNumZ;
}