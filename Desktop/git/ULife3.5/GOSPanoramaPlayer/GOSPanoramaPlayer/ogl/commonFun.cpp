#include <iostream>
#include <fstream>
#include <cmath>
#include <list>
#include <vector>
#include <stdio.h>
#include <stdint.h>
#include <math.h>

#include "commonFun.h"



//bmp读写文件
unsigned char* pixels;
typedef struct
{
        //unsigned short    bfType;
        unsigned long    bfSize;
        unsigned short    bfReserved1;
        unsigned short    bfReserved2;
        unsigned long    bfOffBits;
} my_BitMapFileHeader;
typedef struct
{
    unsigned char rgbBlue; //蓝色分量
    unsigned char rgbGreen; //绿色分量
    unsigned char rgbRed; //红色分量
    unsigned char rgbReserved; //保留位
} my_RgbQuad;
typedef struct
{
        unsigned long  biSize;
        long   biWidth;
        long   biHeight;
        unsigned short   biPlanes;
        unsigned short   biBitCount;
        unsigned long  biCompression;
        unsigned long  biSizeImage;
        long   biXPelsPerMeter;
        long   biYPelsPerMeter;
        unsigned long   biClrUsed;
        unsigned long   biClrImportant;
} my_BitMapInfoHeader;
//加载bmp图像
my_Image* my_LoadImage(const char* path,int imgChn)
{
	my_Image* bmpImg;
	FILE* pFile;
	unsigned short fileType;
	my_BitMapFileHeader bmpFileHeader;
	my_BitMapInfoHeader bmpInfoHeader;
	int channels = 1;
	int width = 0;
	int height = 0;
	int step = 0;
	int offset = 0;
	unsigned char pixVal;
	my_RgbQuad* quad;
	int i, j, k;
	bmpImg = (my_Image*)malloc(sizeof(my_Image));
	pFile = fopen(path, "rb");
	if (!pFile)
	{
		printf("zcj CANNOTOPEN :%s  \n",path);
		free(bmpImg);
		return NULL;
	}
	fread(&fileType, sizeof(unsigned short), 1, pFile);
	if (fileType == 0x4D42)
	{
		printf("zzz bmp file! \n");
		printf("zcj bmp file! \n");
		fread(&bmpFileHeader, sizeof(my_BitMapFileHeader), 1, pFile);
/*
		printf("zzz \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n");
		printf("zzz bmp head info:\n");
		printf("zzz file size: %d \n", bmpFileHeader.bfSize);
		printf("zzz bfReserved1: %d \n", bmpFileHeader.bfReserved1);
		printf("zzz bfReserved2: %d \n", bmpFileHeader.bfReserved2);
		printf("zzz bfOffBits: %d \n", bmpFileHeader.bfOffBits);
*/
		fread(&bmpInfoHeader, sizeof(my_BitMapInfoHeader), 1, pFile);
		printf("zzz \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n");
		printf("zzz InfoHeader:\n");
		printf("zzz biSize: %d \n", bmpInfoHeader.biSize);
		printf("zzz biWidth: %d \n", bmpInfoHeader.biWidth);
		printf("zzz biHeight: %d \n", bmpInfoHeader.biHeight);
		printf("zzz biPlanes: %d \n", bmpInfoHeader.biPlanes);
		printf("zzz biBitCount: %d \n", bmpInfoHeader.biBitCount);
		printf("zzz biCompression: %d \n", bmpInfoHeader.biCompression);
		printf("zzz biSizeImage: %d \n", bmpInfoHeader.biSizeImage);
		printf("zzz biXPelsPerMeter: %d \n", bmpInfoHeader.biXPelsPerMeter);
		printf("zzz biYPelsPerMeter: %d \n", bmpInfoHeader.biYPelsPerMeter);
		printf("zzz biClrUsed: %d \n", bmpInfoHeader.biClrUsed);
		printf("zzz biClrImportant: %d \n", bmpInfoHeader.biClrImportant);
		printf("zzz \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n");
		if (bmpInfoHeader.biBitCount == 8 && imgChn==1)
		{
			channels = 1;
			width = bmpInfoHeader.biWidth;
			height = bmpInfoHeader.biHeight;
			offset = (channels*width)%4;
			if (offset != 0)
			{
				offset = 4 - offset;
			}
			//bmpImg->mat = kzCreateMat(height, width, 1, 0);
			bmpImg->width = width;
			bmpImg->height = height;
			bmpImg->channels = 1;
			bmpImg->imageData = (unsigned char*)malloc(sizeof(unsigned char)*width*height);
			step = channels*width;
			quad = (my_RgbQuad*)malloc(sizeof(my_RgbQuad)*256);
			fread(quad, sizeof(my_RgbQuad), 256, pFile);
			free(quad);
			for (i=0; i<height; i++)
			{
				for (j=0; j<width; j++)
				{
					fread(&pixVal, sizeof(unsigned char), 1, pFile);
					bmpImg->imageData[i*step+j] = pixVal;
				}
				if (offset != 0)
				{
					for (j=0; j<offset; j++)
					{
						fread(&pixVal, sizeof(unsigned char), 1, pFile);
					}
				}
			}
		}
		else if (bmpInfoHeader.biBitCount == 24 && imgChn==3)
		{
			channels = 3;
			width = bmpInfoHeader.biWidth;
			height = bmpInfoHeader.biHeight;
			bmpImg->width = width;
			bmpImg->height = height;
			bmpImg->channels = 3;
			bmpImg->imageData = (unsigned char*)malloc(sizeof(unsigned char)*width*3*height);
			step = channels*width;
			offset = (channels*width)%4;
			if (offset != 0)
			{
				offset = 4 - offset;
			}
			for (i=0; i<height; i++)
			{
				for (j=0; j<width; j++)
				{
					for (k=2; k>-1; k--)
					{
						fread(&pixVal, sizeof(unsigned char), 1, pFile);
						bmpImg->imageData[i*step+j*3+k] = pixVal;
					}
					//kzSetMat(bmpImg->mat, height-1-i, j, kzScalar(pixVal[0], pixVal[1], pixVal[2]));
				}
				if (offset != 0)
				{
					for (j=0; j<offset; j++)
					{
						fread(&pixVal, sizeof(unsigned char), 1, pFile);
					}
				}
			}
		}
		else if (bmpInfoHeader.biBitCount == 24 && imgChn==4)
		{
			channels = 4;
			width = bmpInfoHeader.biWidth;
			height = bmpInfoHeader.biHeight;
			bmpImg->width = width;
			bmpImg->height = height;
			bmpImg->channels = 4;
			bmpImg->imageData = (unsigned char*)malloc(sizeof(unsigned char)*width*3*height);
			step = channels*width;
			offset = (channels*width)%4;
			if (offset != 0)
			{
				offset = 4 - offset;
			}
			for (i=0; i<height; i++)
			{
				for (j=0; j<width; j++)
				{
					for (k=0; k<3; k++)
					{
						fread(&pixVal, sizeof(unsigned char), 1, pFile);
						bmpImg->imageData[(height-1-i)*step+j*4+k] = pixVal;
					}
					bmpImg->imageData[(height-1-i)*step+j*4+4] = 0;
					//kzSetMat(bmpImg->mat, height-1-i, j, kzScalar(pixVal[0], pixVal[1], pixVal[2]));
				}
				if (offset != 0)
				{
					for (j=0; j<offset; j++)
					{
						fread(&pixVal, sizeof(unsigned char), 1, pFile);
					}
				}
			}
		}
	}
	return bmpImg;
}
//保存bmp图像
bool my_SaveImage(const char* path, unsigned char* bmpdata, int width, int height,int channels)
{
FILE *pFile;
	unsigned short fileType;
	my_BitMapFileHeader bmpFileHeader;
	my_BitMapInfoHeader bmpInfoHeader;
	int step;
	int offset;
	unsigned char pixVal = '\0';
	int i, j;
	my_RgbQuad* quad;
	pFile = fopen(path, "wb");
	if (!pFile)
	{
		return false;
	}
	fileType = 0x4D42;
	fwrite(&fileType, sizeof(unsigned short), 1, pFile);
    if (channels == 3 || channels==4)//24bit图像
	{
		step = channels*width;
		offset = step%4;
		if (offset != 4)
		{
			step += 4-offset;
		}
		bmpFileHeader.bfSize = height*step + 54;
		bmpFileHeader.bfReserved1 = 0;
		bmpFileHeader.bfReserved2 = 0;
		bmpFileHeader.bfOffBits = 54;
		fwrite(&bmpFileHeader, sizeof(my_BitMapFileHeader), 1, pFile);
		bmpInfoHeader.biSize = 40;
		bmpInfoHeader.biWidth = width;
		bmpInfoHeader.biHeight = height;
		bmpInfoHeader.biPlanes = 1;
		bmpInfoHeader.biBitCount = 24;
		bmpInfoHeader.biCompression = 0;
		bmpInfoHeader.biSizeImage = height*step;
		bmpInfoHeader.biXPelsPerMeter = 0;
		bmpInfoHeader.biYPelsPerMeter = 0;
		bmpInfoHeader.biClrUsed = 0;
		bmpInfoHeader.biClrImportant = 0;
		fwrite(&bmpInfoHeader, sizeof(my_BitMapInfoHeader), 1, pFile);
		for (i=0; i<height; i++)
		{
			for (j=0; j<width; j++)
			{
				pixVal = bmpdata[i*width*channels+j*channels+2];
				fwrite(&pixVal, sizeof(unsigned char), 1, pFile);
				pixVal = bmpdata[i*width*channels+j*channels+1];
				fwrite(&pixVal, sizeof(unsigned char), 1, pFile);
				pixVal = bmpdata[i*width*channels+j*channels+0];
				fwrite(&pixVal, sizeof(unsigned char), 1, pFile);
			}
			if (offset!=0)
			{
				for (j=0; j<offset; j++)
				{
					pixVal = 0;
					fwrite(&pixVal, sizeof(unsigned char), 1, pFile);
				}
			}
		}
	}
    else if (channels == 1)//8位图像
	{
		step = width;
		offset = step%4;
		if (offset != 4)
		{
			step += 4-offset;
		}
		bmpFileHeader.bfSize = 54 + 256*4 + width;
		bmpFileHeader.bfReserved1 = 0;
		bmpFileHeader.bfReserved2 = 0;
		bmpFileHeader.bfOffBits = 54 + 256*4;
		fwrite(&bmpFileHeader, sizeof(my_BitMapFileHeader), 1, pFile);
		bmpInfoHeader.biSize = 40;
		bmpInfoHeader.biWidth = width;
		bmpInfoHeader.biHeight = height;
		bmpInfoHeader.biPlanes = 1;
		bmpInfoHeader.biBitCount = 8;
		bmpInfoHeader.biCompression = 0;
		bmpInfoHeader.biSizeImage = height*step;
		bmpInfoHeader.biXPelsPerMeter = 0;
		bmpInfoHeader.biYPelsPerMeter = 0;
		bmpInfoHeader.biClrUsed = 256;
		bmpInfoHeader.biClrImportant = 256;
		fwrite(&bmpInfoHeader, sizeof(my_BitMapInfoHeader), 1, pFile);
		quad = (my_RgbQuad*)malloc(sizeof(my_RgbQuad)*256);
		for (i=0; i<256; i++)
		{
			quad[i].rgbBlue = i;
			quad[i].rgbGreen = i;
			quad[i].rgbRed = i;
			quad[i].rgbReserved = 0;
		}
		fwrite(quad, sizeof(my_RgbQuad), 256, pFile);
		free(quad);
		for (i=0; i<height; i++)
		{
			for (j=0; j<width; j++)
			{
				pixVal = bmpdata[i*width+j];
				fwrite(&pixVal, sizeof(unsigned char), 1, pFile);
			}
			if (offset!=0)
			{
				for (j=0; j<offset; j++)
				{
					pixVal = 0;
					fwrite(&pixVal, sizeof(unsigned char), 1, pFile);
				}
			}
		}
	}
	fclose(pFile);
	return true;
}
//保存rgb文件
void image_write(char* filename, void* data, int width, int height, int bpp)
{
	FILE* fp;
	fp = fopen(filename, "w+b");

	if (fp == NULL)
	{
		printf("zzz failed to open file %s\n", filename);
		return;
	}

//	fwrite((void*) data, width*height*bpp, 1, fp);
	unsigned char* mydata=(unsigned char*)data;
	for(int i=0;i<width*height*bpp;i=i+1){
		fprintf(fp,"%d ",mydata[i]);
	//	printf("%d ",mydata[i]);

		if(i%(width*4)==(width*4-1)){
			fprintf(fp,"\r\n");
		//	printf("\n");
		}
	}
	printf("zzz image_write : %d",width*height*bpp);
	fclose(fp);
}
//3D模型生成文件，包括模型生成，不同模型间切换
//loopnum， 模型间平滑切换控制参数
//loopSpreadNum， 柱形展开，模型变形参数
float *sphere_vertices,*sphere_vertices00,*sphere_vertices01,*sphere_vertices02,*sphere_vertices03,*sphere_vertices05,*sphere_texcoords;
unsigned short *sphere_indices;
void bowlModelMakeAndCreatVBO(GLuint &m_VertexVBO, GLuint &m_uvVBO , GLuint &m_indicesVBO,int &m_TotalFaces, int loopNum,float xMove, int modelState[],int loopSpreadNum) {

    float alpha = 0;
    float beta = 0;

    float R = 1.0;
    const unsigned int n_vertex_coordinates = 3;// 顶点个数
    const unsigned int n_texture_coordinates = 2;// 纹理坐标元素个数
    const unsigned int n_normal_coordinates = 3; //发现坐标元素个数
    const unsigned int n_indices_per_vertex = 6; //索引坐标元素个数

    int sphere_vertex_data_size = ALPHAPOINTNUM_TEST * BETAPOINTNUM_TEST * n_vertex_coordinates;
    int sphere_normal_data_size = ALPHAPOINTNUM_TEST * BETAPOINTNUM_TEST * n_normal_coordinates;
    int sphere_texcoords_size = ALPHAPOINTNUM_TEST * BETAPOINTNUM_TEST * n_texture_coordinates;
    int sphere_indices_size = ALPHAPOINTNUM_TEST * BETAPOINTNUM_TEST * n_indices_per_vertex;


    static int initCtl = 0;
    if (initCtl == 0) {//开辟空间
        sphere_vertices = (float *) malloc(sphere_vertex_data_size * sizeof(float));
        sphere_vertices00 = (float *) malloc(sphere_vertex_data_size * sizeof(float));
        sphere_vertices01 = (float *) malloc(sphere_vertex_data_size * sizeof(float));
        sphere_vertices02 = (float *) malloc(sphere_vertex_data_size * sizeof(float));
        sphere_vertices03 = (float *) malloc(sphere_vertex_data_size * sizeof(float));
        sphere_vertices05 = (float *) malloc(sphere_vertex_data_size * sizeof(float));
        sphere_texcoords = (float *) malloc(sphere_texcoords_size * sizeof(float));
        sphere_indices = (unsigned short *) malloc(sphere_indices_size * sizeof(unsigned short));
        if (sphere_vertices == NULL || sphere_vertices00 == NULL || sphere_vertices01 == NULL ||
            sphere_texcoords == NULL || sphere_indices == NULL) {
            printf("Memory allocation error FILE: %s LINE: %i\n", __FILE__, __LINE__);
        }

        glGenBuffers(1, &m_VertexVBO);
        glGenBuffers(1, &m_uvVBO);
        glGenBuffers(1, &m_indicesVBO);


    }

    float *vertices00 = sphere_vertices00;
    float *vertices01 = sphere_vertices01;
    float *vertices02 = sphere_vertices02;
    float *vertices03 = sphere_vertices03;
    float *vertices05 = sphere_vertices05;
    float *texcoords = sphere_texcoords;
    unsigned short *indices = sphere_indices;

    //生成索引坐标
    if (initCtl == 0) {
        for (int i = 0; i < ALPHAPOINTNUM_TEST * BETAPOINTNUM_TEST - BETAPOINTNUM_TEST; i++) {
            *indices++ = i;
            *indices++ = i + BETAPOINTNUM_TEST;
            *indices++ = i + 1;

            *indices++ = i + 1;
            *indices++ = i + BETAPOINTNUM_TEST;
            *indices++ = i + BETAPOINTNUM_TEST + 1;

            if (i % (BETAPOINTNUM_TEST) == BETAPOINTNUM_TEST - 2)
                i = i + 1;
        }
        initCtl = 1;
    }

    float alphaStep = PI / 2 / (ALPHAPOINTNUM_TEST - 1);
    float betaStep = PI / (BETAPOINTNUM_TEST - 1);
  if(loopNum!=STEPNUM ){
       for (int j = 0; j < ALPHAPOINTNUM_TEST; j++) {
            for (int i = 0; i < BETAPOINTNUM_TEST; i++) {
                alphaStep = PI / (ALPHAPOINTNUM_TEST - 1);
                betaStep = 2 * PI / (BETAPOINTNUM_TEST - 1);
                alpha = j * alphaStep - PI / 2;
                alpha = alpha / 3;
                beta = i * betaStep;
                beta = beta / 3.0 + PI / 6.0;
               // beta = beta / 4.0 +PI/4;
                float RR = 2.0;//0.45;
                *vertices05++ = RR * cos(alpha) * cos(beta);
                *vertices05++ = RR * sin(alpha);
                *vertices05++ = RR * cos(alpha) * sin(beta);
            }
        }

        for (int j = 0; j < ALPHAPOINTNUM_TEST; j++) {
            for (int i = 0; i < BETAPOINTNUM_TEST; i++) {

                ///半球模型
                alphaStep = PI / 2 / (ALPHAPOINTNUM_TEST - 1);
                betaStep = 2 * PI / (BETAPOINTNUM_TEST - 1);
                alpha = j * alphaStep - PI / 2;
                beta = i * betaStep;

                float tz = R / 2 * cos(alpha) * sin(beta);
                float rz = (-R / 2 / ALPHAPOINTNUM_TEST * j + R / 2);

                float RR = 1.0;
                if (modelState[0] == 5)
                    RR = R * 1;
                else
                    RR = R * 1;

                float ratio=1.0;

                *vertices00++ = RR/ratio * cos(alpha) * cos(beta);
                float tValue = sin(0.4 * PI);
                if (alpha < 0.4 * PI)
                    *vertices00++ = R/ratio * sin(alpha) + R / 2.0;
                else
                    *vertices00++ = R/ratio * tValue + R * (alpha - 0.4 * PI) + R / 2.0;

                *vertices00++ = RR/ratio * cos(alpha) * sin(beta);

                //柱形模型
                alphaStep = PI / 2 / (ALPHAPOINTNUM_TEST - 1);
                betaStep = 2 * PI / (BETAPOINTNUM_TEST - 1);
                alpha = j * alphaStep - PI / 2;
                beta = i * betaStep;
                R = 1.0;
                *vertices01++ = 0.8 * R * cos(beta);
                *vertices01++ = -R / (ALPHAPOINTNUM_TEST - 1) * (ALPHAPOINTNUM_TEST - 1 - j) + R / 2;
                *vertices01++ = 0.8 * R * sin(beta);
                //plan
                alphaStep = 1.0 / (ALPHAPOINTNUM_TEST - 1);
                betaStep = 1.0 / (BETAPOINTNUM_TEST - 1);
                alpha = j * alphaStep;
                beta = i * betaStep ;
                R=2.4;
                *vertices02++ = R * beta-R/2;
                *vertices02++ = R * alpha-R/2;
                *vertices02++ = 0.0;

                //畸变展开模型
                float R = 1.0;
                alphaStep = PI / (ALPHAPOINTNUM_TEST - 1);
                betaStep = 2 * PI / (BETAPOINTNUM_TEST - 1);
                alpha = j * alphaStep - PI / 2;
                alpha = alpha / 2.0;
                beta = i * betaStep;
                beta = beta / 3.0 + PI / 6.0;
                float tx = R * cos(alpha) * cos(beta);
                float ty = R * sin(alpha);
                tz = R * cos(alpha) * sin(beta);
                float mx = 1 * tz / cos(alpha*1.15) / tz;

                tx = mx * tx;
                *vertices03++ = tx*1.3;
                *vertices03++ = ty*1.5;
                *vertices03++ = tz;
            }
        }

        //柱面展开模型
        //旋转顶点到中间，达到平展效果
        float ra = 3 * PI / 2;
        for (int i = 0; i < sphere_vertex_data_size;) {
            float tx = sphere_vertices01[i];
            float tz = sphere_vertices01[i + 2];
            float nx = tx * cos(ra) - tz * sin(ra);
            float nz = tx * sin(ra) + tz * cos(ra);
            sphere_vertices01[i] = -nx;
            sphere_vertices01[i + 2] = nz;
            i = i + 3;
        }

        if (modelState[0] != 5 && modelState[0] != 6) {
            for (int i = 0; i < sphere_vertex_data_size;) {
                float tx = sphere_vertices00[i];
                float tz = sphere_vertices00[i + 2];
                float nx = tx * cos(ra) - tz * sin(ra);
                float nz = tx * sin(ra) + tz * cos(ra);
                sphere_vertices00[i] = -nx;
                sphere_vertices00[i + 2] = nz;
                i = i + 3;
            }
        }


        //模型之间平滑切换
        for (int i = 0; i < sphere_vertex_data_size; i++) {
            if (modelState[0] == 0 && modelState[1] == 1 || modelState[0] == -1 && modelState[1] == 1)
                sphere_vertices[i] =
                        (sphere_vertices01[i] - sphere_vertices00[i]) / (STEPNUM - 1) * loopNum +
                        sphere_vertices00[i];
            if (modelState[0] == 1 && modelState[1] == 0)
                sphere_vertices[i] =
                        (sphere_vertices00[i] - sphere_vertices01[i]) / (STEPNUM - 1) * loopNum +
                        sphere_vertices01[i];

            else if (modelState[0] == 1 && modelState[1] == 2)
                sphere_vertices[i] =
                        (sphere_vertices02[i] - sphere_vertices01[i]) / (STEPNUM - 1) * loopNum +
                        sphere_vertices01[i];
            else if (modelState[0] == 2 && modelState[1] == 1)
                sphere_vertices[i] =
                        (sphere_vertices01[i] - sphere_vertices02[i]) / (STEPNUM - 1) * loopNum +
                        sphere_vertices02[i];


            if (modelState[0] == 0 && modelState[1] == 2 || modelState[0] == -1 && modelState[1] == 2)
                sphere_vertices[i] =
                        (sphere_vertices02[i] - sphere_vertices00[i]) / (STEPNUM - 1) * loopNum +
                        sphere_vertices00[i];
            if (modelState[0] == 2 && modelState[1] == 0)
                sphere_vertices[i] =
                        (sphere_vertices00[i] - sphere_vertices02[i]) / (STEPNUM - 1) * loopNum +
                        sphere_vertices02[i];

            if (modelState[0] == 5 && modelState[1] == 6)
                sphere_vertices[i] =
                        (sphere_vertices03[i] - sphere_vertices05[i]) / (STEPNUM - 1) * loopNum +
                        sphere_vertices05[i];
            if (modelState[0] == 6 && modelState[1] == 5)
                sphere_vertices[i] =
                        (sphere_vertices05[i] - sphere_vertices03[i]) / (STEPNUM - 1) * loopNum +
                        sphere_vertices03[i];


            if (modelState[0] == 0 && modelState[1] == 0 || modelState[0] == -1 )
                sphere_vertices[i] = sphere_vertices00[i];
            else if(modelState[0]==1 && modelState[1]==1)
            	sphere_vertices[i]=sphere_vertices01[i];
            else if (modelState[0] == 2 && modelState[1] == 2 )
                sphere_vertices[i] = sphere_vertices02[i];
            else if (modelState[0] == 3 && modelState[1] == 3)
                sphere_vertices[i] = sphere_vertices02[i];
            else if (modelState[0] == 31)
                sphere_vertices[i] = sphere_vertices02[i];
            else if (modelState[0] == 4 && modelState[1] == 4)
                sphere_vertices[i] = sphere_vertices00[i];

            else if (modelState[0] == 5 && modelState[1] == 5)
                sphere_vertices[i] = sphere_vertices05[i];
            else if (modelState[0] == 6 && modelState[1] == 6)
                sphere_vertices[i] = sphere_vertices03[i];
        }
    }//end ==STEPNUM


    for (int i = 0; i < sphere_vertex_data_size; i++){
        if (modelState[0] == 1 && loopSpreadNum < STEPNUM1 && loopNum==STEPNUM) {
			sphere_vertices[i] = (sphere_vertices02[i] - sphere_vertices01[i]) / (STEPNUM1 - 1) * loopSpreadNum + sphere_vertices01[i];
        }
    }
    //计算纹理坐标
    for(int j=0;j<ALPHAPOINTNUM_TEST;j++){
		for(int i=0;i<BETAPOINTNUM_TEST;i++){
			float tmpR=0.5;
			float vcrop=0.10;
			float du=	2*PI/(BETAPOINTNUM_TEST-1);
			float dv;
			if(modelState[0]==-1 || modelState[0]==0 || modelState[0]==4 || modelState[0]==5 || modelState[0]==6 ){
				dv=	PI/2/(ALPHAPOINTNUM_TEST-1);
				alpha=j*dv;
			}
			else{
				dv=	(1-vcrop)/(ALPHAPOINTNUM_TEST-1);
				alpha=j*dv+vcrop;
			}
			if(modelState[0]==5 || modelState[0]==6){
					xMove=0;
            }

			if(modelState[0]==3 || modelState[0]==31 )
				du=du/2;
			else if(modelState[0]==2 || (modelState[0]==1 && loopSpreadNum==STEPNUM1-1))
				du=du/4;

			if(modelState[0]==31 )
                beta=i*du+xMove+PI;
			else
				beta=i*du+xMove;

			if(modelState[0]==-1 || modelState[0]==0 || modelState[0]==4 )
				beta=beta+PI/2;

			float tmpu,tmpv;
			if(modelState[0]==-1 || modelState[0]==0 || modelState[0]==4 ){
				tmpu = tmpR*alpha/(PI/2)*cos(beta)+tmpR;
				tmpv = tmpR*alpha/(PI/2)*sin(beta)+tmpR;
			}
            else if(modelState[0]==5 || modelState[0]==6 ){
                tmpu=du*i/(2*PI);
                tmpv=dv*j/(PI/2);
            }
			else{
				tmpu=tmpR*alpha*cos(beta)+tmpR;
				tmpv=tmpR*alpha*sin(beta)+tmpR;

			}
				*texcoords++=tmpu;
				*texcoords++=tmpv;
        }
	}



    //绑定顶点，纹理和索引缓冲
	glBindBuffer(GL_ARRAY_BUFFER, m_VertexVBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * sphere_vertex_data_size,  &sphere_vertices[0], GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);



    glBindBuffer(GL_ARRAY_BUFFER, m_uvVBO);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * sphere_texcoords_size, &sphere_texcoords[0], GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, m_indicesVBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned short) * sphere_indices_size, &sphere_indices[0], GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

/*
        glDeleteBuffers(1, &m_VertexVBO);
        glDeleteBuffers(1, &m_uvVBO);
        glDeleteBuffers(1, &m_indicesVBO);

        free(sphere_vertices);
        free(sphere_vertices00);
        free(sphere_vertices01);
        free(sphere_vertices02);
        free(sphere_vertices03);
        free(sphere_vertices05);
        free(sphere_texcoords);
        free(sphere_indices);

	  */

 }
