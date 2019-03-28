
#ifndef _commonFun_H
#define _commonFun_H
#define TOPVIEW 0

#define STEPNUM 10
#define STEPNUM1 20

//#define PLATFORM_WIN
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#ifdef PLATFORM_WIN
	/* Use glew.h instead of gl.h to get all the GL prototypes declared */
	#include <GL/glew.h>
	/* Using the GLUT library for the base windowing setup */
	#include <GL/freeglut.h>
#else
	#include <OpenGLES/ES2/gl.h>
	#include <OpenGLES/ES2/glext.h>
#endif
/* GLM */
// #define GLM_MESSAGES

#define GLM_FORCE_RADIANS
#include  "glm.hpp"
#include  "matrix_transform.hpp"
#include  "type_ptr.hpp"


#define ALPHAPOINTNUM_TEST 100
#define BETAPOINTNUM_TEST 100
//#define ALPHAPOINTNUM 45
//#define BETAPOINTNUM 90
#define PI 3.1415926


typedef struct
{
        int width;
        int height;
        int channels;
        unsigned char* imageData;
}my_Image;

my_Image* my_LoadImage(const char* path,int imgChn);
bool my_SaveImage(const char* path, unsigned char* bmpdata, int width, int height,int channels);
void bowlModelMakeAndCreatVBO(GLuint &m_VertexVBO, GLuint &m_uvVBO , GLuint &m_indicesVBO,int &m_TotalFaces, int loopNum,float xMove, int modelState[],int loopSpreadNum);

#endif
