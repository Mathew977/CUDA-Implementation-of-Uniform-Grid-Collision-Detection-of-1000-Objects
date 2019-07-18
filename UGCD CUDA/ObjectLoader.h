#pragma once

#include "Stdafx.h"
#include "UniformGrid.h"

class ObjectLoader
{
private:
	int objCount; //Stores the total number of objects in the file
				  //UniformGrid grid;
public:
	//Handles counting the number of objects to be loaded in
	int objectCounter(void);

	//Handles reading in the objects from a file
	float objLoader(UniformGrid);

	ObjectLoader();
	~ObjectLoader();
};

