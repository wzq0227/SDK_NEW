
#ifndef _OGL_H
#define _OGL_H


//#define VIDEOINON
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

#import<GLKit/GLKit.h>


bool oglInit(int videoInW,int videoInH,int initialModel);
void oglRun(unsigned char* videoIn,GLKView *delegateView, int videoInW,int videoInH,int disW,int disH, int motionSig[],int clickSig,int autoRotSignal,float zoomSig[],int clickDouble);
void motionAction(int touchStatus,int x,int y, float zoomSig[],int clickDouble,int autoRotSignal);
void clickAction(int clickSig);
#endif
