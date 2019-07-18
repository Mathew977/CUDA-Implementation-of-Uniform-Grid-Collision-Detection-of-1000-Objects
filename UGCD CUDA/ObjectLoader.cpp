#include "ObjectLoader.h"

ObjectLoader::ObjectLoader()
{
}

ObjectLoader::~ObjectLoader()
{
}

int ObjectLoader::objectCounter(void)
{
	ifstream objFile; //Used to open file
	string line; //Used to read from the file

	objFile.open("Objects7.txt"); //Open file containing the object information

	int tempObjCount = 0; //Used to count the total numbr of objects

	//Check if the file opened correctly
	if (!objFile.fail())
	{
		//Loop through until the end of the file has been found
		while (!objFile.eof())
		{
			//Read line from file and save it to the line string
			getline(objFile, line);

			//Increment the object counter by 1
			tempObjCount++;
		}

		objFile.close();
	}
	else
	{
		//Output Error message
		cout << "ERROR: FILE NOT OPENED" << endl;
	}

	//Set objCount to be the number of objects found in the file
	objCount = tempObjCount;

	return objCount;
	//grid.setobj(objCount);
}

float ObjectLoader::objLoader(UniformGrid grid)
{
	ifstream objFile; //Used to open file
	string line[4]; //Used to read from the file

	objFile.open("Objects7.txt"); //Open file containing the object information

	int objCount = 0;
	float radius;
	//Check if the file opened correctly
	if (!objFile.fail())
	{
		//Loop through until the end of the file has been found
		while (!objFile.eof())
		{
			for (int i = 0; i < 4; i++)
			{
				//Read line from file and save it to the line string
				getline(objFile, line[i]);
			}

			radius = grid.setObject(strtof((line[0]).c_str(), 0), strtof((line[1]).c_str(), 0), strtof((line[2]).c_str(), 0), strtof((line[3]).c_str(), 0), objCount);

			objCount++;
		}

		objFile.close();
	}
	else
	{
		//Output Error message
		cout << "ERROR: FILE NOT OPENED" << endl;
	}

	return radius;
	//return grid;
}