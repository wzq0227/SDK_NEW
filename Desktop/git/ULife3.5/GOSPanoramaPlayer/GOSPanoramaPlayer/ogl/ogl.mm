
#include "ogl.h"
#include "shader_utils.h"
#include "commonFun.h"



int cSig=0;

//ni
int modelState[3]; // 0 for cylinder 1 for bowl,2 for flat

//触屏信号

float pxDragN;
float pyDragN;
float pxDragO=0;
float pyDragO=0;

//旋转
float rotx=0;
float roty=0;
float rotz=0;

float rotxO=0;
float rotyO=0;
float dx=0;
float dy=0;
//循环信号
int loopNum1=0;
int loopSpreadNum=0;
static float xMove=0.0;

//自动旋转
static float autoRot=0;
//触摸信号模式
static int touchStatusOld=0;
float xSpeed=200;

//缩放信号
static float zoomValue=1.0;
static float zoomValueOld=1.0;

//四画面信号
int model4State=-1;
float pxDragN4[4];
float pyDragN4[4];
float pxDragO4[4];
float pyDragO4[4];

float rotx4[4];
float roty4[4];
float rotz4[4];

float rotxO4[4];
float rotyO4[4];
float dx4[4];
float dy4[4];
float xMove4[4];


static float autoRot4[4];
static int touchStatusOld4[4];
float xSpeed4=200;
static float zoomValue4[4];
static float zoomValueOld4[4];

glm::vec3 eye4[4];
glm::vec3 cen4[4];
glm::vec3 up4[4];

int yInit;
int xInit;
int lx,ly;
static int iniCtl=0;
float xMoveOld=0;
float deltaxMove=0;
float deltaxMove4[4]={0,0,0,0};

//ogl， vbo
GLuint vbo_cube_vertices1, vbo_cube_texcoords1;
GLuint ibo_cube_elements1;
GLuint program1;
GLuint textureID;
GLint attribute_coord3d1, attribute_texcoord1;
GLint uniform_mvp1, uniform_mytexture1;
int facenum;
//ogl，lookat参数
glm::vec3 eye2,eye1,eye0,eye,eye50,eye51,eye00;
glm::vec3 cen2,cen1,cen0,cen,cen50,cen51,cen00;
glm::vec3 up2,up1,up0,up,up50,up51,up00;


//color convert

GLuint vboVerticesConvert, vboTexcoordsConvert[2];
GLuint iboElementsConvert;
GLuint programConvert;
GLint positionConvertLoc, textureConvertLoc;
GLint uniform_yuvTexSamplerY,uniform_yuvTexSamplerU,uniform_yuvTexSamplerV;
GLint  defaultFBO;
GLuint framebufferConvert;
GLuint renderBufferTextureConvert;
GLuint textureIDConvert[3];
static void checkGlError(const char* op)
{
    GLenum glError = glGetError();
    
    switch (glError) {
        case GL_INVALID_ENUM:
            printf("===%s GL Error: Enum argument is out of range:%x \r\n",op,glError);
            break;
        case GL_INVALID_VALUE:
            printf("GL Error: Numeric value is out of range:%x \r\n",glError);
            break;
        case GL_INVALID_OPERATION:
            printf("GL Error: Operation illegal in current state:%x \r\n",glError);
            break;
        case GL_OUT_OF_MEMORY:
            printf("GL Error: Not enough memory to execute command:%x \r\n",glError);
            break;
        case GL_NO_ERROR:
            break;
        default:
            printf("===%s Unknown GL Error:%x \r\n",op,glError);
            break;
    }
}
//生成文理ID和设置参数

void makeTexture(){

		glGenTextures(1, &textureID);
		glBindTexture(GL_TEXTURE_2D, textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

}
//绑定纹理
static GLuint bindTexture(GLuint texture, unsigned char *buffer, GLuint w , GLuint h)
{
//  GLuint texture;
//  glGenTextures ( 1, &texture );
    checkGlError("glGenTextures");
    glBindTexture ( GL_TEXTURE_2D, texture );
    checkGlError("glBindTexture");
    
    glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, w, h, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, buffer);
    checkGlError("glTexImage2D");
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    checkGlError("glTexParameteri");
    //glBindTexture(GL_TEXTURE_2D, 0);
    
    return texture;
}
void updateTextureConvert(unsigned char* videoIn,int videoInW,int videoInH){
    if (videoIn) {
        bindTexture(textureIDConvert[0], videoIn, videoInW, videoInH);
        bindTexture(textureIDConvert[1], videoIn + videoInW * videoInH, videoInW/2, videoInH/2);
        bindTexture(textureIDConvert[2], videoIn + videoInW * videoInH * 5 / 4, videoInW/2, videoInH/2);
    }
}

void makeTextureConvert(){

		glGenTextures(3, &textureIDConvert[0]);
		glBindTexture(GL_TEXTURE_2D, textureIDConvert[0]);
		glBindTexture(GL_TEXTURE_2D, textureIDConvert[1]);
		glBindTexture(GL_TEXTURE_2D, textureIDConvert[2]);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}
//fbo buffer 初始化
void fboInit(int videoInW,int videoInH){
    
    glGenTextures(1, &renderBufferTextureConvert);
    glBindTexture(GL_TEXTURE_2D, renderBufferTextureConvert);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, videoInW, videoInH, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
     	glBindTexture(GL_TEXTURE_2D, 0);
    checkGlError("glBindTexture");
    
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &defaultFBO);
		glGenFramebuffers(1, &framebufferConvert);
		checkGlError("glGenframebufferConverts");
		glBindFramebuffer(GL_FRAMEBUFFER, framebufferConvert);
	    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderBufferTextureConvert,0);
		checkGlError("glframebufferConvertTexture2D");


    
    int status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if(status != GL_FRAMEBUFFER_COMPLETE)
        printf("zzz fboinit RAMEBUFFER FAILURE!!!!!!!!!!!\n");
    else
        printf("zzz fboinit RAMEBUFFER SUCCESS!!!!!!!!!!!\n");
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFBO);

}

//yuv转换函数初始化
void frameConvertInit(int videoInW,int videoInH){

printf("zzz: %s ........... %d!\n",__FUNCTION__,__LINE__);

	GLfloat rect_vertices[] = {
   // front
    -1.0, -1.0,  0.0,
     1.0, -1.0,  0.0,
     1.0,  1.0,  0.0,
    -1.0,  1.0,  0.0
  };
  glGenBuffers(1, &vboVerticesConvert);
  glBindBuffer(GL_ARRAY_BUFFER, vboVerticesConvert);
  glBufferData(GL_ARRAY_BUFFER, sizeof(rect_vertices), rect_vertices, GL_STATIC_DRAW);

    //吊装
    static GLfloat rect_texcoords0[] = {
            0.18, 0.0,
		    0.78, 0.0,
		    0.78, 1.0,
		    0.18, 1.0
  };
    //侧装
    static GLfloat rect_texcoords1[] = {
            0.03125, 1-0.0,
            0.96093, 1-0.0,
            0.96093, 1-1.0,
            0.03125, 1-1.0
    };

    glGenBuffers(2, vboTexcoordsConvert);
    glBindBuffer(GL_ARRAY_BUFFER, vboTexcoordsConvert[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(rect_texcoords0), rect_texcoords0, GL_STATIC_DRAW);

    glBindBuffer(GL_ARRAY_BUFFER, vboTexcoordsConvert[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(rect_texcoords1), rect_texcoords1, GL_STATIC_DRAW);


  GLushort rect_elements[] = {
    // front
    0,  1,  2,
    2,  3,  0
  };
  glGenBuffers(1, &iboElementsConvert);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iboElementsConvert);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(rect_elements), rect_elements, GL_STATIC_DRAW);

	static const char gVertexShader[] =
	"attribute vec3 coord3d;\n"
	"attribute vec2 texcoord;\n"
	"varying vec2 f_texcoord;\n"
	"void main(void) {\n"
	  "gl_Position = vec4(coord3d, 1.0);\n"
	  "f_texcoord = texcoord;\n"
	"}\n";

	static const char gFragmentShader[] =
			 "precision highp float;  \n"
			"varying vec2 f_texcoord;\n"
			"uniform sampler2D mytextureY;\n"
			"uniform sampler2D mytextureU;\n"
			"uniform sampler2D mytextureV;\n"
			"void main(void) {\n"
					"mediump vec3 yuv;\n"
			        "lowp vec3 rgb;\n"
			        "yuv.x = texture2D(mytextureY, f_texcoord).r;\n"
			        "yuv.y = texture2D(mytextureU, f_texcoord).r - 0.5;\n"
			        "yuv.z = texture2D(mytextureV, f_texcoord).r - 0.5;\n"
						"rgb = mat3( 1,   1,   1,\n"
			                    "0,       -0.39465,  2.03211,\n"
			                    "1.13983,   -0.58060,  0) * yuv;\n"
			        "gl_FragColor = vec4(rgb, 1);\n"
			"//gl_FragColor =vec4(1,0,0,1);\n"
			"}\n";


	programConvert = createProgram(gVertexShader, gFragmentShader);

    if (!programConvert ) {
		printf("zzz %s ........... %d  %d ERROR!\n",__FUNCTION__,__LINE__,programConvert);
    }
    else
    	printf("zzz %s ........... %d  %d success!\n",__FUNCTION__,__LINE__,programConvert );


	const char* attribute_name;
	attribute_name = "coord3d";
	positionConvertLoc = glGetAttribLocation(programConvert, attribute_name);
	if (positionConvertLoc == -1) {
		printf("zzz zzzx Could not bind attribute %s\n", attribute_name);
	}
	attribute_name = "texcoord";
	textureConvertLoc = glGetAttribLocation(programConvert, attribute_name);
	if (textureConvertLoc == -1) {
		fprintf(stderr, "Could not bind attribute %s\n", attribute_name);
	}


		uniform_yuvTexSamplerY = glGetUniformLocation(programConvert, "mytextureY");
	    checkGlError("glGetUniformLocation");
	    uniform_yuvTexSamplerU = glGetUniformLocation(programConvert, "mytextureU");
	    checkGlError("glGetUniformLocation");
	    uniform_yuvTexSamplerV = glGetUniformLocation(programConvert, "mytextureV");
	    checkGlError("glGetUniformLocation");
	glUseProgram(programConvert);



///////////
	makeTextureConvert();
	fboInit(videoInW,videoInH);
}
//yuv转换运行函数
void frameConvertRun(unsigned char* videoIn, int videoInW,int videoInH){

    glClearColor(0.0, 0.0, 0.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

	updateTextureConvert( videoIn, videoInW, videoInH);

	glUseProgram(programConvert);
	glViewport(0, 0, videoInW , videoInH);

		////////////////////////////////////////////////////
	  glEnableVertexAttribArray(positionConvertLoc);
	  glBindBuffer(GL_ARRAY_BUFFER, vboVerticesConvert);
	  glVertexAttribPointer(positionConvertLoc, 3, GL_FLOAT,  GL_FALSE, 0, 0  );

      glEnableVertexAttribArray(textureConvertLoc);
    if(modelState[0]==5 || modelState[0]==6)
        glBindBuffer(GL_ARRAY_BUFFER, vboTexcoordsConvert[1]);
    else
        glBindBuffer(GL_ARRAY_BUFFER, vboTexcoordsConvert[0]);
      glVertexAttribPointer(textureConvertLoc, 2, GL_FLOAT,  GL_FALSE, 0, 0  );

	  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iboElementsConvert);
  	int size;  glGetBufferParameteriv(GL_ELEMENT_ARRAY_BUFFER, GL_BUFFER_SIZE, &size);


    glActiveTexture(GL_TEXTURE0);
    checkGlError("glActiveTexture");
    glBindTexture(GL_TEXTURE_2D, textureIDConvert[0]);
    checkGlError("glBindTexture");
    glUniform1i(uniform_yuvTexSamplerY, 0);
    checkGlError("glUniform1i");

    glActiveTexture(GL_TEXTURE1);
    checkGlError("glActiveTexture");
    glBindTexture(GL_TEXTURE_2D, textureIDConvert[1]);
    checkGlError("glBindTexture");
    glUniform1i(uniform_yuvTexSamplerU, 1);
    checkGlError("glUniform1i");

    glActiveTexture(GL_TEXTURE2);
    checkGlError("glActiveTexture");
    glBindTexture(GL_TEXTURE_2D, textureIDConvert[2]);
    checkGlError("glBindTexture");
    glUniform1i(uniform_yuvTexSamplerV, 2);
    checkGlError("glUniform1i");

    glBindFramebuffer(GL_FRAMEBUFFER, framebufferConvert);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,renderBufferTextureConvert,0);
    
    glDrawElements(GL_TRIANGLES, size/sizeof(GLushort), GL_UNSIGNED_SHORT, 0);
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFBO);
    checkGlError("glDrawElements");
}

//ogl初始化
bool oglInit(int videoInW,int videoInH,int initialModel)
{
    modelState[0]=initialModel;
    modelState[1]=initialModel;
    cSig=1;
    loopNum1=0;
    if(modelState[0]==-1 ) {
        zoomValue = 1.4165;
        roty=-0.747;
    }
    else {
        zoomValue = 1.0;
        roty=0.0;
   }
    rotx=0;rotz=0; loopSpreadNum=0;
    //Random camera's view when first entering
    xMove = arc4random()%100;

    for(int i=0;i<4;i++){
        rotx4[i]=0;
        roty4[i]=0;
        rotz4[i]=0;
        zoomValueOld4[i]=1.0;
        eye4[i]=glm::vec3(0,2.5,0.0001);
        cen4[i]=glm::vec3(0,0,0);
        up4[i]=glm::vec3(0,1,0);
    }

	printf("zzz: %s %d %d\n",__FUNCTION__,__LINE__,program1);
    //3D模型生成函数
    bowlModelMakeAndCreatVBO(vbo_cube_vertices1, vbo_cube_texcoords1 ,ibo_cube_elements1,facenum,loopNum1,xMove,modelState,loopSpreadNum);
    makeTexture();
    printf("zzz: %s %d %d\n",__FUNCTION__,__LINE__,program1);
    static const char gVertexShader[] =
            "attribute vec3 coord3d;\n"
                    "attribute vec2 texcoord;\n"
                    "varying vec2 f_texcoord;\n"
                    "uniform mat4 mvp;\n"
                    "void main(void) {\n"
                    "gl_Position = mvp * vec4(coord3d, 1.0);\n"
                    "f_texcoord = texcoord;\n"
                    "}\n";

	static const char gFragmentShader[] =
			 "precision highp float;  \n"
				"varying vec2 f_texcoord;\n"
				"uniform sampler2D mytexture;\n"
				"void main(void) {\n"
				"	vec4 uyvy=texture2D(mytexture, f_texcoord);\n"
				 " gl_FragColor =uyvy;\n"
				"//gl_FragColor =vec4(1,0,0,1);\n"
				"}\n";

	
	GLint link_ok = GL_FALSE;
	program1 = createProgram(gVertexShader, gFragmentShader);
    
//	printf("zzz: %s %d %d\n",__FUNCTION__,__LINE__,program1);
	    if (!program1) {
	    	fprintf(stderr,"Could not create program.");
	        return false;
	    }

	const char* attribute_name;
	attribute_name = "coord3d";
	attribute_coord3d1 = glGetAttribLocation(program1, attribute_name);
	if (attribute_coord3d1 == -1) {
		fprintf(stderr, "Could not bind attribute %s\n", attribute_name);
		return 0;
	}
	attribute_name = "texcoord";
	attribute_texcoord1 = glGetAttribLocation(program1, attribute_name);
	if (attribute_texcoord1 == -1) {
		fprintf(stderr, "Could not bind attribute %s\n", attribute_name);
		return 0;
	}
	const char* uniform_name;
	uniform_name = "mvp";
	uniform_mvp1 = glGetUniformLocation(program1, uniform_name);
	if (uniform_mvp1 == -1) {
		fprintf(stderr, "Could not bind uniform %s\n", uniform_name);
		return 0;
	}

	uniform_name = "mytexture";
	uniform_mytexture1 = glGetUniformLocation(program1, uniform_name);
	if (uniform_mytexture1 == -1) {
		printf("zzz zzzx Could not bind uniform %s\n", uniform_name);
		return 0;
	}

//	printf("zzz: %s %d %d\n",__FUNCTION__,__LINE__,program1);
	frameConvertInit(videoInW,videoInH);
	return 1;
}
//ogl 渲染函数


void loopGL0(unsigned char* videoIn,int videoInW,int videoInH, glm::vec3 eye,glm::vec3 cen,glm::vec3 up, float rotx,float roty, float rotz, float theta,float zoomValue, int disW,int disH){

	glUseProgram(program1);

	glm::mat4 View = glm::lookAt(eye, cen, up);
	glm::mat4 Projection = glm::perspective(45.0f,(float)disW/disH,0.1f,1000.f);
	glm::mat4 Model = glm::mat4(1.0f);
	

    if(model4State==0){
        //printf("zxy22:--- %d %f %f %f \n",model4State,rotx,roty,eye.z);
    }

	Model = glm::rotate(Model, roty, glm::vec3(1.0f, 0.0f, 0.0f));
    Model = glm::rotate(Model, rotx+theta, glm::vec3(0.0f, -1.0f, 0.0f));
	Model = glm::scale(Model, glm::vec3(zoomValue, zoomValue, zoomValue));
	
	glm::mat4 mvp1;
		mvp1= Projection * View * Model;
	
	glUniformMatrix4fv(uniform_mvp1, 1, GL_FALSE, glm::value_ptr(mvp1));

	glActiveTexture(GL_TEXTURE0);
	glUniform1i(uniform_mytexture1, /*GL_TEXTURE*/0);

	glEnableVertexAttribArray(attribute_coord3d1);
	// Describe our vertices array to OpenGL (it can't guess its format automatically)
	glBindBuffer(GL_ARRAY_BUFFER, vbo_cube_vertices1);
	glVertexAttribPointer(attribute_coord3d1,	3, GL_FLOAT, GL_FALSE, 0,  0 );

	glEnableVertexAttribArray(attribute_texcoord1);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_cube_texcoords1);
	glVertexAttribPointer(attribute_texcoord1, 2, GL_FLOAT, GL_FALSE, 0, 0);


	/* Push each element in buffer_vertices to the vertex shader */
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_cube_elements1);
	int size;  glGetBufferParameteriv(GL_ELEMENT_ARRAY_BUFFER, GL_BUFFER_SIZE, &size);
	
	glBindTexture(GL_TEXTURE_2D, renderBufferTextureConvert);
	glDrawElements(GL_TRIANGLES, size/sizeof(GLushort), GL_UNSIGNED_SHORT, 0);

	

}
//四画面渲染
void oglRun4Screen(unsigned char* videoIn,int videoInW,int videoInH,int disW,int disH, int motionSig[],int clickSig,int autoRotSignal, float zoomSig[],int clickDouble){


	static float rotyy4[4];
	static float zoomValuee4[4];

	for(int i=0;i<4;i++){
		rotyy4[i]=0.0;
		zoomValuee4[i]=0.0;
		eye4[i]=glm::vec3(0,2.5,0.01);
		cen4[i]=glm::vec3(0,0,0);
		up4[i]=glm::vec3(0,1,0);
	}


    if(modelState[0]==4){
        for(int i=0;i<4;i++){

                rotyy4[i]=roty4[i];
                zoomValuee4[i]=zoomValue4[i];

            if(cen4[i].z<0.001){
                cen4[i].z=cen4[i].z+rotyy4[i];
            }
            if(cen4[i].z>0)
                cen4[i].z=0;
        }

	}
	//printf("zxyyy: %d %d %f %f %f %f %f",modelState[1],modelState[0],roty4[0],rotyy4[0],rotz4[0],zoomValuee4[0],cen4[0].z);

    static int clickStatus=4;

	if(pxDragN>0 && pyDragN>0 && pxDragN<disW/2 && pyDragN<disH/2 && clickDouble==0){
		model4State=2;
	 }
	 if(pxDragN>0 && pyDragN>0 && pxDragN>disW/2 && pyDragN<disH/2 && clickDouble==0){
			model4State=3;
	 }
	 if(pxDragN>0 && pyDragN>0 && pxDragN<disW/2 && pyDragN>disH/2 && clickDouble==0){
			model4State=0;
	 }
	 if(pxDragN>0 && pyDragN>0 && pxDragN>disW/2 && pyDragN>disH/2 && clickDouble==0){
		model4State=1;
	 }



		if(clickStatus==4){
		printf("zzzxy: %s %d %d %d %d\n",__FUNCTION__,__LINE__,clickDouble,clickStatus,model4State);
		}




    if(clickDouble==1 && model4State==0){
        glViewport(0, 0, disW, disH);
        loopGL0(videoIn, videoInW, videoInH, eye4[0], cen4[0], up4[0], rotx4[0], rotyy4[0], rotz4[0], 0*PI/4,zoomValuee4[0], disW,disH);
    }
    else if(clickDouble==1 && model4State==1){
        glViewport(0, 0, disW, disH);
        loopGL0(videoIn, videoInW, videoInH, eye4[1], cen4[1], up4[1], rotx4[1], rotyy4[1], rotz4[1], 1*PI/4, zoomValuee4[1], disW,disH);
    }
    else if(clickDouble==1 && model4State==2){
        glViewport(0, 0, disW, disH);
        loopGL0(videoIn, videoInW, videoInH, eye4[2], cen4[2], up4[2], rotx4[2], rotyy4[2], rotz4[2], 2*PI/4, zoomValuee4[2], disW,disH);
    }
    else if(clickDouble==1 && model4State==3){
        glViewport(0, 0, disW, disH);
        loopGL0(videoIn, videoInW, videoInH, eye4[3], cen4[3], up4[3], rotx4[3], rotyy4[3], rotz4[3], 3*PI/4, zoomValuee4[3], disW,disH);
    }
    else if(clickDouble==0){
        glViewport(0, 0, disW/2, disH/2);
        loopGL0(videoIn, videoInW, videoInH, eye4[0], cen4[0], up4[0], rotx4[0], rotyy4[0], rotz4[0], 0*PI/4,zoomValuee4[0], disW,disH);
        glViewport(disW/2, 0, disW/2, disH/2);
        loopGL0(videoIn, videoInW, videoInH, eye4[1], cen4[1], up4[1], rotx4[1], rotyy4[1], rotz4[1], 1*PI/4, zoomValuee4[1], disW,disH);
        glViewport(0, disH/2, disW/2, disH/2);
        loopGL0(videoIn, videoInW, videoInH, eye4[2], cen4[2], up4[2], rotx4[2], rotyy4[2], rotz4[2], 2*PI/4, zoomValuee4[2], disW,disH);
        glViewport(disW/2, disH/2, disW/2, disH/2);
        loopGL0(videoIn, videoInW, videoInH, eye4[3], cen4[3], up4[3], rotx4[3], rotyy4[3], rotz4[3], 3*PI/4, zoomValuee4[3], disW,disH);
    }

}
//ogl 运行函数
void oglRun(unsigned char* videoIn,GLKView *delegateView,int videoInW,int videoInH,int disW,int disH, int motionSig[],int clickSig, int autoRotSignal, float zoomSig[],int clickDouble){

	glClearColor(0.0, 0.0, 0.0, 1.0);

    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	glEnable(GL_DEPTH_TEST);

//    //printf("zxy2:--- %d %d %f %f %f %d %d \n",modelState[0],clickSig,rotx,roty,rotz,cSig,loopNum1);

	frameConvertRun(videoIn, videoInW, videoInH);

    [delegateView bindDrawable];
    
    
//	printf("zzzx: %s %d %f %f %f\n",__FUNCTION__,__LINE__,zoomSig[0],zoomSig[1],zoomSig[2]);
    motionAction(motionSig[0],motionSig[1],motionSig[2],zoomSig,clickDouble,autoRotSignal);
	clickAction(clickSig);


	if(loopNum1==STEPNUM-1 && modelState[1]==0)	modelState[0]=0;
	if(loopNum1==STEPNUM-1 && modelState[1]==1)	modelState[0]=1;
	if(loopNum1==STEPNUM-1 && modelState[1]==2)	modelState[0]=2;
	if( modelState[1]==3)	modelState[0]=3;
	if( modelState[1]==31)	modelState[0]=31;
	if( modelState[1]==4)	modelState[0]=4;
	

    if( modelState[1]==0 && (modelState[0]==3 || modelState[0]==31 || modelState[0]==4  || modelState[0]==5 || modelState[0]==6))
        modelState[0]=0;
    if( modelState[1]==1 && (modelState[0]==3 || modelState[0]==31 || modelState[0]==4  || modelState[0]==5 || modelState[0]==6)){
        modelState[0]=1;
        loopNum1=STEPNUM-1;
    }

    if( modelState[1]==2 && (modelState[0]==3 || modelState[0]==31 || modelState[0]==4  || modelState[0]==5 || modelState[0]==6))
        modelState[0]=2;
    if( modelState[1]==4 && (modelState[0]==3 || modelState[0]==31 || modelState[0]==4  || modelState[0]==5 || modelState[0]==6))
        modelState[0]=4;



    if(loopNum1==STEPNUM-1 && modelState[1]==5 && modelState[0]==6)	modelState[0]=5;
    if(loopNum1==STEPNUM-1 && modelState[1]==6 && modelState[0]==5)	modelState[0]=6;
    if(modelState[1]==5 && modelState[0]!=6) 	modelState[0]=5;
	if(modelState[1]==6 && modelState[0]!=5) 	modelState[0]=6;
    if(modelState[1]==1 && modelState[0]==-1) 	modelState[0]=1;
    if(modelState[1]==2 && modelState[0]==-1) 	modelState[0]=2;

	if( modelState[1]==1 && modelState[0]==0 ||
		modelState[1]==0 && modelState[0]==1 ||
		modelState[1]==2 && modelState[0]==0 ||
		modelState[1]==0 && modelState[0]==2 ||
		modelState[1]==1 && modelState[0]==2 ||
		modelState[1]==2 && modelState[0]==1 ||
		modelState[1]==6
		){ 
		rotx=0;
		roty=0;
		rotz=0;

		pxDragO=0;
		pyDragO=0;
        if(modelState[1]!=0)
            zoomValue=1.0;
        loopSpreadNum=0;
    }
    //0.5
    if(modelState[1]==5 && modelState[0]!=6 && loopNum1==0)
        zoomValue=0.5;
    
#if 0
    if(modelState[0]==5 && modelState[1]==5 && loopNum1<STEPNUM) {
        zoomValue = 0.5 + 0.5 / (STEPNUM-1) * loopNum1;
    }
#else
    static int SPEED= 0;
    if(modelState[0]==5 && modelState[1]==5 && loopNum1<STEPNUM) {
        SPEED += 1;
        if ((SPEED+1)%2 == 0) {
            loopNum1 -= 1;
        }
        if(zoomValue<1.0){
            zoomValue = 0.5 + 0.025 *(SPEED+1);
        }
        else{
            zoomValue = 1.0;
            SPEED = 0;
        }
    }
#endif
    
//    if(modelState[0]==5 && modelState[1]==5 && loopNum1<STEPNUM) {
//        zoomValue = 0.5 + 0.5 / (STEPNUM-1) * loopNum1;
//       // zoomValue=zoomValue/2.0;
//    }

    if(modelState[1]==1 && modelState[0]==3 || modelState[1]==1 && modelState[0]==4)
        cSig=0;
//    //printf("zxy23:--- %d %d %f %f %f %d %d %d \n",modelState[0],modelState[1],rotx,roty,rotz,cSig,loopNum,loopNum1);

//	printf("\n zxy1:--- %d %d %f %f %f %d %d \n",modelState[0],modelState[1],rotx,roty,rotz,cSig,loopNum1);

	if(cSig==1)
		loopNum1=loopNum1+1;
	
	if(loopNum1>STEPNUM){
		loopNum1=STEPNUM;
		cSig=0;
	}
	


    bowlModelMakeAndCreatVBO(vbo_cube_vertices1, vbo_cube_texcoords1, ibo_cube_elements1, facenum, loopNum1, xMove, modelState, loopSpreadNum);
   //
    glUseProgram(program1);




	eye0=glm::vec3(0,2.5,0.01);
	cen0=glm::vec3(0,0,0);
	up0=glm::vec3(0,1,0);
	
	eye1=glm::vec3(0,1,1.8);
	cen1=glm::vec3(0,0,0);
	up1=glm::vec3(0,1,0);
	
	eye2=glm::vec3(0,0,1.8);
	cen2=glm::vec3(0,0,0);
	up2=glm::vec3(0,1,0);


    if(modelState[0]==0 || modelState[0]==-1){
        if(cen0.z<0.001){
            cen0.z=cen0.z+roty;
        }

        if(cen0.z>0)
            cen0.z=0;

        eye=eye0;
        cen=cen0;
        up=up0;
    }
	else if(modelState[0]==1){
		for(int i=0;i<3;i++){
			if(modelState[0]==1 && loopSpreadNum<STEPNUM1){
				eye[i]=(float)(eye2[i]-eye1[i])/(STEPNUM1-1)*loopSpreadNum+eye1[i];
				cen[i]=(float)(cen2[i]-cen1[i])/(STEPNUM1-1)*loopSpreadNum+cen1[i];
				up[i]=(float)(up2[i]-up1[i])/(STEPNUM1-1)*loopSpreadNum+up1[i];
			}
		}
	}
	else if(modelState[0]==1 && modelState[1]==1 || modelState[0]==5 ){
			eye=eye1;
			cen=cen1;
			up=up1;
		}

//    printf("zzxy: %d %d %d %d",autoRotSignal,modelState[0],modelState[1],loopNum1);

    if(loopNum1<STEPNUM){
        for(int i=0;i<3;i++){
            if(modelState[1]==1 && modelState[0]==0){
                eye[i]=(float)(eye1[i]-eye0[i])/(STEPNUM-1)*loopNum1+eye0[i];
                cen[i]=(float)(cen1[i]-cen0[i])/(STEPNUM-1)*loopNum1+cen0[i];
                up[i]=(float)(up1[i]-up0[i])/(STEPNUM-1)*loopNum1+up0[i];
            }

			if(modelState[1]==0 && modelState[0]==1){
				eye[i]=(float)(eye0[i]-eye1[i])/(STEPNUM-1)*loopNum1+eye1[i];
				cen[i]=(float)(cen0[i]-cen1[i])/(STEPNUM-1)*loopNum1+cen1[i];
				up[i]=(float)(up0[i]-up1[i])/(STEPNUM-1)*loopNum1+up1[i];
			}
			if(modelState[1]==2 && modelState[0]==1){
				eye[i]=(float)(eye2[i]-eye1[i])/(STEPNUM-1)*loopNum1+eye1[i];
				cen[i]=(float)(cen2[i]-cen1[i])/(STEPNUM-1)*loopNum1+cen1[i];
				up[i]=(float)(up2[i]-up1[i])/(STEPNUM-1)*loopNum1+up1[i];
			}
			if(modelState[1]==1 && modelState[0]==2){
				eye[i]=(float)(eye1[i]-eye2[i])/(STEPNUM-1)*loopNum1+eye2[i];
				cen[i]=(float)(cen1[i]-cen2[i])/(STEPNUM-1)*loopNum1+cen2[i];
				up[i]=(float)(up1[i]-up2[i])/(STEPNUM-1)*loopNum1+up2[i];
			}
			if(modelState[1]==2 && modelState[0]==0){
				eye[i]=(float)(eye2[i]-eye0[i])/(STEPNUM-1)*loopNum1+eye0[i];
				cen[i]=(float)(cen2[i]-cen0[i])/(STEPNUM-1)*loopNum1+cen0[i];
				up[i]=(float)(up2[i]-up0[i])/(STEPNUM-1)*loopNum1+up0[i];
			}
			if(modelState[1]==0 && modelState[0]==2){
				eye[i]=(float)(eye0[i]-eye2[i])/(STEPNUM-1)*loopNum1+eye2[i];
				cen[i]=(float)(cen0[i]-cen2[i])/(STEPNUM-1)*loopNum1+cen2[i];
				up[i]=(float)(up0[i]-up2[i])/(STEPNUM-1)*loopNum1+up2[i];
			}

		}
	}




    if(modelState[0]==2 && modelState[1]==2 || modelState[0]==31 || modelState[1]==3 ){
        eye=glm::vec3(0,0,1.0);
        cen=glm::vec3(0,0,0);
        up=glm::vec3(0,1,0);
    }

	if(modelState[0]==5 || modelState[0]==6){
		eye=glm::vec3(0,1.0,0.01);
		cen=glm::vec3(0,0,0);
		up=glm::vec3(0,1,0);
	//	cen.z=cen.z+rotx/5.0;

	}


	glm::mat4 View = glm::lookAt(eye, cen, up);
	glm::mat4 Projection;
    if(modelState[0]==1 || modelState[0]==2 ||modelState[0]==3 ||modelState[0]==31 || modelState[0]==5 || modelState[0]==6){
        Projection = glm::ortho(-(float)disW/disH, (float)disW/disH, -1.0f, 1.0f, 0.1f, 10.0f);
        //	Projection = glm::perspective(60.0f,(float)disW/disH,0.1f,1000.f);
    }
    else
        Projection = glm::perspective(45.0f,(float)disW/disH,0.001f,10.f);

    glm::mat4 Model = glm::mat4(1.0f);
    static float rr=0;

	if(modelState[0]==1){
		roty=0;
		if(loopSpreadNum>0)
			rotx=0;
	}
	if(modelState[0]==2 || modelState[0]==3 || modelState[0]==31 ||  modelState[0]==6 ){
		rotx=0;
		roty=0;rotz=0;
	}
	
	glm::mat4 mvp1;

    if(autoRotSignal==1 ){
        if(modelState[0]==-1 || modelState[0]==0 || modelState[0]==1 || modelState[0]==4) {
//            NSLog(@"__________________________________________xMove:%4.2f",xMove);
            xMove = xMove + 2 / xSpeed; // for 自动巡航
        }
        else {
            xMove = xMove - 2 / xSpeed;
        }
        if(modelState[0]==6)
            xMove=0;
    }

	static int autoPlus=0;
	static float rotzM=0.2;
    if(modelState[0]==5 && autoRotSignal==1){
        float rotSp=0.002;
        if(autoPlus==0)
            rotz=rotz+rotSp;
        else
            rotz=rotz-rotSp;
        if(fabs(rotz-rotzM)<0.0001)
            autoPlus=1;
        if(fabs(rotz+rotzM)<0.0001)
            autoPlus=0;

		//printf("zxy0:--- %d %f\n",autoPlus,rotz);

	}


    if(modelState[0]==0 || modelState[0]==-1){
        Model = glm::scale(Model,glm::vec3(zoomValue*1.0f,zoomValue*1.0f,zoomValue*1.0f));
    }

    if(modelState[0]==5 || modelState[0]==6){
        float roty5=PI/2;
        float rotz5=PI;
        if(modelState[0]==5) {

            Model = glm::scale(Model, glm::vec3(zoomValue * 1.0f, zoomValue * 1.0f, zoomValue * 1.0f));
            Model = glm::rotate(Model, rotz, glm::vec3(0.0f, 0.0f, 1.0f));
        }

        Model = glm::rotate(Model, rotz5, glm::vec3(0.0f, -1.0f, 0.0f));
        Model = glm::rotate(Model, roty5, glm::vec3(1.0f, 0.0f, 0.0f));
        Model = glm::rotate(Model, -roty, glm::vec3(1.0f, 0.0f, 0.0f));
        Model = glm::rotate(Model, -rotx, glm::vec3(0.0f, 1.0f, 0.0f));


        if(autoRotSignal==0) {
            if (rotx > PI / 16.0) rotx = rotx/1.01;
            if (rotx < -PI / 16.0) rotx = rotx/1.01;
        }
        else{
            if (rotx != 0) rotx = rotx /1.1;
        }
        if (roty > PI / 100.0) roty = roty - 0.002;
        if (roty < -PI / 100.0) roty = roty + 0.002;
    }
    else if(modelState[0]==-1 ||  modelState[0]==0){
        Model = glm::rotate(Model, roty, glm::vec3(1.0f, 0.0f, 0.0f));
        Model = glm::rotate(Model, -rotx, glm::vec3(0.0f, 1.0f, 0.0f));
    }

    mvp1= Projection * View * Model;
    glUniformMatrix4fv(uniform_mvp1, 1, GL_FALSE, glm::value_ptr(mvp1));

	glActiveTexture(GL_TEXTURE0);
	glUniform1i(uniform_mytexture1, 0);

	glEnableVertexAttribArray(attribute_coord3d1);
	// Describe our vertices array to OpenGL (it can't guess its format automatically)
	glBindBuffer(GL_ARRAY_BUFFER, vbo_cube_vertices1);
	glVertexAttribPointer(attribute_coord3d1,	3, GL_FLOAT, GL_FALSE, 0,  0 );

	glEnableVertexAttribArray(attribute_texcoord1);
	glBindBuffer(GL_ARRAY_BUFFER, vbo_cube_texcoords1);
	glVertexAttribPointer(attribute_texcoord1, 2, GL_FLOAT, GL_FALSE, 0, 0);


	// Push each element in buffer_vertices to the vertex shader
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_cube_elements1);
	int size;  glGetBufferParameteriv(GL_ELEMENT_ARRAY_BUFFER, GL_BUFFER_SIZE, &size);
	
	glBindTexture(GL_TEXTURE_2D, renderBufferTextureConvert);


    
    if(modelState[0]==3 || modelState[0]==31){
        printf("zcj: modelState[0] %d",modelState[0]);
        modelState[0]=3;
        glViewport(0, 0, disW, disH/2);
        glDrawElements(GL_TRIANGLES, size/sizeof(GLushort), GL_UNSIGNED_SHORT, 0);

        modelState[0]=31;
        bowlModelMakeAndCreatVBO(vbo_cube_vertices1, vbo_cube_texcoords1, ibo_cube_elements1,facenum,loopNum1,xMove,modelState,loopSpreadNum);
        glEnableVertexAttribArray(attribute_coord3d1);
        // Describe our vertices array to OpenGL (it can't guess its format automatically)
        glBindBuffer(GL_ARRAY_BUFFER, vbo_cube_vertices1);
        glVertexAttribPointer(attribute_coord3d1,	3, GL_FLOAT, GL_FALSE, 0,  0 );

        glEnableVertexAttribArray(attribute_texcoord1);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_cube_texcoords1);
        glVertexAttribPointer(attribute_texcoord1, 2, GL_FLOAT, GL_FALSE, 0, 0);


		// Push each element in buffer_vertices to the vertex shader
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_cube_elements1);

		glViewport(0, disH/2, disW, disH/2);
		glDrawElements(GL_TRIANGLES, size/sizeof(GLushort), GL_UNSIGNED_SHORT, 0);

    }




	if(modelState[0]==-1 || modelState[0]==0  ||modelState[0]==5 || modelState[0]==6){

		glViewport(0, 0, disW, disH);
		glDrawElements(GL_TRIANGLES, size/sizeof(GLushort), GL_UNSIGNED_SHORT, 0);
	}
	else if(modelState[0]==1){
		glViewport(0, 0, disW, disH);
		glDrawElements(GL_TRIANGLES, size/sizeof(GLushort), GL_UNSIGNED_SHORT, 0);

    }
    else if(modelState[0]==2){
        glViewport(0, 0, disW, disH);
        glDrawElements(GL_TRIANGLES, size/sizeof(GLushort), GL_UNSIGNED_SHORT, 0);
    }
    else  if(modelState[0]==4)
        oglRun4Screen(videoIn, videoInW, videoInH, disW, disH, motionSig, clickSig, autoRotSignal, zoomSig,clickDouble);

	if( modelState[0]!=4 )
			{
			for(int i=0;i<4;i++){
				rotx4[i]=0;
				roty4[i]=0;
				rotz4[i]=0;
				pxDragO4[i]=0;
				pyDragO4[i]=0;
				zoomValue4[i]=0;

				eye4[i]=glm::vec3(0,2.5,0.0001);
				cen4[i]=glm::vec3(0,0,0);
				up4[i]=glm::vec3(0,1,0);


			}
		}

//printf("modelState: %d %d\r\n",modelState[0],modelState[1]);
    
}
//触屏滑动操作，旋转，缩放功能
void motionAction(int touchStatus,int x,int y, float zoomSig[], int clickDouble, int autoRotSignal) //??????????
{


			float rotSpeed=0.001;
    //float rotSpeed=0.0000001;
				pxDragN = x;
				pyDragN = y;

				pxDragN4[model4State]=x;
				pyDragN4[model4State]=y;


			if(pxDragO!=0)
				dx=pxDragN-pxDragO;

			if(pxDragO4[model4State]!=0)
				dx4[model4State]=pxDragN4[model4State]-pxDragO4[model4State];



			if(pyDragO!=0){
				dy=pyDragN-pyDragO;
				dy=-dy;
			}

			if(pyDragO4[model4State]!=0){
				dy4[model4State]=pyDragN4[model4State]-pyDragO4[model4State];
				dy4[model4State]=-dy4[model4State];
			}



    if (touchStatus == 1 && touchStatusOld == 1) {
        roty = dy * rotSpeed + rotyO;
        roty4[model4State] = dy4[model4State] * rotSpeed + rotyO4[model4State];

        if(modelState[0]==5)
            rotSpeed = rotSpeed * 3;//测装滑动速度
        else
            rotSpeed = rotSpeed * 10;
        if (fabs(dx) < 2)
            dx = 0;
        rotx = dx * rotSpeed + rotxO;

        if (fabs(dx4[model4State]) < 2)
            dx4[model4State] = 0;
        rotx4[model4State] = dx4[model4State] * rotSpeed + rotxO4[model4State];
    }
//for deltaxMove
    else if (touchStatus == 2 && touchStatusOld == 1) {
        deltaxMove = (pxDragN - pxDragO) / xSpeed;
        deltaxMove4[model4State] = (pxDragN4[model4State] - pxDragO4[model4State]) / xSpeed;
    } else if (touchStatus == 2 && touchStatusOld == 2) {
        deltaxMove = deltaxMove / 1.05;
        rotx += deltaxMove;
        deltaxMove4[model4State] = deltaxMove4[model4State] / 1.05;
        rotx4[model4State] += deltaxMove4[model4State];
    }
    if(modelState[0]==4){
        //	//printf("zxyy: %d %f %f",model4State,pxDragN4[model4State],pxDragO4[model4State]);
    }
			
				//printf("zxyy: %d %f %f %f %f %f",model4State,rotx4[0],roty4[0],rotz4[0],zoomValue4[0]);
			if(touchStatus==0){
				autoRot=0;
				autoRot4[model4State]=0;
			}

			if(fabs(autoRot)>0.0001){
				autoRot=autoRot/(xSpeed*1.0);
				autoRot4[model4State]=autoRot4[model4State]/(xSpeed*1.0);


			}


    if(modelState[0] == -1 || modelState[0] == 0){
        if (roty > PI / 36)
            roty = PI / 36;
        if (roty < -PI / 3)
            roty = -PI / 3;
    }
    else if(modelState[0] == 5 ) {
        if (rotx > PI / 6) rotx = PI / 6;
        if (rotx < -PI / 6) rotx = -PI / 6;

       if (roty > PI / 24)
            roty = PI / 24;
        if (roty < -PI / 24)
            roty = -PI / 24;
    }
    else {
        if (roty > PI / 36)
            roty = PI / 36;
        if (roty < -PI / 3)
            roty = -PI / 3;
    }



    if (roty4[model4State] > PI / 36)
        roty4[model4State] = PI / 36;
    if (roty4[model4State] < -0.747)
        roty4[model4State] = -0.747;


    if (modelState[0] == 1 || modelState[0] == 2 || modelState[0] == 3 || modelState[0] == 31){
            if (touchStatus == 1) {
                xMove += -dx / xSpeed;
                xMoveOld = xMove;
            } else if (touchStatus == 2 && touchStatusOld == 1) {
                deltaxMove = (pxDragN - pxDragO) / xSpeed;
                float xMoveOld = -deltaxMove;
                xMove += xMoveOld;
            } else if (touchStatus == 2 && touchStatusOld == 2) {
                deltaxMove = deltaxMove / 1.05;
                float xMoveOld = -deltaxMove;
                xMove += xMoveOld;
            }
    }

    //////for zoom
    static float zoomSpeed=500.0;
    if(modelState[0]==-1 || modelState[0]==0 || modelState[0]==4 || modelState[0]==5){
        if(touchStatus==3){

        }
        if(touchStatus==4){
            zoomValue=zoomSig[2]/zoomSpeed;
            zoomValue4[model4State]=zoomSig[2]/zoomSpeed;

            zoomValue=zoomValueOld+zoomValue/zoomValueOld;
            zoomValue4[model4State]=zoomValueOld4[model4State]+zoomValue4[model4State]/zoomValueOld4[model4State];

            if(modelState[0]==5){
                if(zoomValue<0.5)
                    zoomValue=0.5;
                if(zoomValue>6.0)
                    zoomValue=6.0;

            }
            else{
                if(zoomValue<0.4)
                    zoomValue=0.4;
                if(zoomValue>3.4)
                    zoomValue=3.4;
            }

            if(clickDouble==0){
                if(zoomValue4[model4State]<1)
                    zoomValue4[model4State]=1;
                if(zoomValue4[model4State]>5.0)
                    zoomValue4[model4State]=5.0;
            }
            else{
                if(zoomValue4[model4State]<0.4)
                    zoomValue4[model4State]=0.4;
                if(zoomValue4[model4State]>5.0)
                    zoomValue4[model4State]=5.0;
            }
        }
        if(touchStatus==2){
            zoomValueOld=zoomValue;
            zoomValueOld4[model4State]=zoomValue4[model4State];
        }
//		printf("zzcc2:: %f %f %f %f %f %d",zoomSig[0],zoomSig[1],zoomSig[2],zoomValue4[0],zoomValueOld4[0],touchStatus);
	}
	///////loop spread num
	if(modelState[0]!=1){
		x=0;y=0;
		ly=0.01;
		lx=0;
	}
	if(touchStatus==0 || touchStatus==2 ){
		iniCtl=0;
	}
	if(touchStatus==1){
		if(iniCtl==0){
			xInit=x;
			yInit=y;

			lx=x-xInit;
			ly=y-yInit;
			ly=-ly;
			iniCtl=1;
		}
		else{
			lx=x-xInit;
			ly=y-yInit;
			ly=-ly;
		}
	}

	if(modelState[0]==1 && abs(ly)>abs(lx)){
			if(loopNum1==STEPNUM1-1)
			loopSpreadNum=0;
			if(loopSpreadNum<STEPNUM1-1 && ly>0){
				if(loopSpreadNum!=STEPNUM1-1)
				loopSpreadNum=floor((ly)/20.0);

		}

		if(loopSpreadNum>-1 && ly<0){
			if(loopSpreadNum!=0)
				loopSpreadNum=STEPNUM1+floor(ly/20.0);

		}

		if(loopSpreadNum>STEPNUM1-5)
				loopSpreadNum=STEPNUM1-1;
		if(loopSpreadNum<5)
			loopSpreadNum=0;


	}
	pxDragO=pxDragN;
	pyDragO=pyDragN;
	rotxO=rotx;
	rotyO=roty;

    pxDragO4[model4State]=pxDragN4[model4State];
    pyDragO4[model4State]=pyDragN4[model4State];
    rotxO4[model4State]=rotx4[model4State];
    rotyO4[model4State]=roty4[model4State];

    touchStatusOld=touchStatus;


}
//按键button响应函数
void clickAction(int clickSig) {

    if (clickSig==0) {
        modelState[1]=0;autoRot=0;autoRot=0; rotx=0;roty=0;rotz=0;xMove=0;zoomValue=0.4;    model4State=0;deltaxMove=0;

        for(int i=0;i<4;i++){
            autoRot4[i]=0; rotx4[i]=0;roty4[i]=0;rotz4[i]=0;xMove4[i]=0;zoomValue4[i]=1.0;deltaxMove4[i]=0;
        }
        if(modelState[1]!=modelState[0]) {
            cSig = 1;
            loopNum1 = 0;
        }
    }
    else if (clickSig==1) {
        modelState[1]=1;autoRot=0;xMove=0;zoomValue=1.0;deltaxMove=0; model4State=0;
        if(modelState[1]!=modelState[0]) {
            cSig = 1;
            loopNum1 = 0;
        }
    }
    else if (clickSig==2) {
        modelState[1]=2;autoRot=0;xMove=0;zoomValue=1.0;deltaxMove=0; model4State=0;
        if(modelState[1]!=modelState[0]) {
            cSig = 1;
            loopNum1 = 0;
        }

    }
    else if (clickSig==3) {
        modelState[1]=3;autoRot=0;xMove=0;zoomValue=1.0;deltaxMove=0; model4State=0;
        if(modelState[1]!=modelState[0]) {
            cSig = 1;
            loopNum1 = 0;
        }
    }
    else if (clickSig==4) {
        modelState[1]=4; autoRot=0;autoRot=0; rotx=0;roty=0;rotz=0;xMove=0;zoomValue=0.0; model4State=0;

        for(int i=0;i<4;i++){
            autoRot4[i]=0; rotx4[i]=0;roty4[i]=-0.747;rotz4[i]=0;xMove4[i]=0;zoomValue4[i]=1.4165;deltaxMove4[i]=0;
        }
        if(modelState[1]!=modelState[0]) {
            cSig = 1;
            loopNum1 = 0;
        }
    }
    else if (clickSig==5) {
        modelState[1]=5;autoRot=0;autoRot=0; rotx=0;roty=0;rotz=0;xMove=0;zoomValue=1.0;
        if(modelState[1]!=modelState[0]) {
            cSig = 1;
            loopNum1 = 0;
        }
    }
    else if (clickSig==6) {
        modelState[1]=6;autoRot=0;autoRot=0; rotx=0;roty=0;rotz=0;xMove=0;zoomValue=1.0;
        if(modelState[1]!=modelState[0]) {
            cSig = 1;
            loopNum1 = 0;
        }
    }
}

