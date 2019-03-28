#include "UTF8Utils.h"
#include <stdio.h>

#ifdef WIN32
#include <Windows.h>

char *EncodeToUTF8(const char* lpszSrc) 
{
	char    *pszUTF8  = NULL; 
	int      nCharLen = 0;
	wchar_t *pwszTmp = NULL;

	if(IsEmptyStr(lpszSrc))
		return NULL ;

	nCharLen = MultiByteToWideChar(CP_ACP, 0, lpszSrc, -1, NULL, 0); 
	pwszTmp  = (wchar_t*) malloc(sizeof(wchar_t)*(nCharLen+1)); 
	MultiByteToWideChar(CP_ACP, 0, lpszSrc, -1, pwszTmp, nCharLen); 
	nCharLen = WideCharToMultiByte(CP_UTF8, 0, pwszTmp, -1, NULL, 0, NULL, NULL);

	pszUTF8 = (char *)malloc(nCharLen+1);
	WideCharToMultiByte(CP_UTF8, 0, pwszTmp, -1, pszUTF8, nCharLen, NULL, NULL);
	free(pwszTmp);

	pszUTF8[nCharLen]=0;
	return pszUTF8;
} 

char *DecodeFromUTF8(const char* lpszUTF8) 
{ 
	char    *pszDest  = NULL; 
	int      nCharLen = 0;
	wchar_t *pwszTmp = NULL;

	if(IsEmptyStr(lpszUTF8))
		return NULL ;
	nCharLen = MultiByteToWideChar(CP_UTF8, 0, lpszUTF8, -1, NULL, 0); 
	pwszTmp  = (wchar_t*) malloc(sizeof(wchar_t)*(nCharLen+1)); 
	MultiByteToWideChar(CP_UTF8, 0, lpszUTF8, -1, pwszTmp, nCharLen); 
	nCharLen = WideCharToMultiByte(CP_ACP, 0, pwszTmp, -1, NULL, 0, NULL, NULL); 

	pszDest  = (char *)malloc(nCharLen+1);
	WideCharToMultiByte(CP_ACP, 0, pwszTmp, -1, pszDest, nCharLen, NULL, NULL);
	free(pwszTmp);
	pszDest[nCharLen] = 0 ;
	return pszDest;
} 


static char  szStrEnc[0x10000]={0} ;
static char  szStrDec[0x10000]={0} ;

char *EncodeToUTF8_S(const char* lpszSrc)
{
	int      nCharLen = 0;
	wchar_t *pwszTmp = NULL;
	if(IsEmptyStr(lpszSrc))
		return NULL ;

	nCharLen = MultiByteToWideChar(CP_ACP, 0, lpszSrc, -1, NULL, 0); 
	pwszTmp  = (wchar_t*) malloc(sizeof(wchar_t)*(nCharLen+1)); 
	MultiByteToWideChar(CP_ACP, 0, lpszSrc, -1, pwszTmp, nCharLen);

	nCharLen = WideCharToMultiByte(CP_UTF8, 0, pwszTmp, -1, NULL, 0, NULL, NULL);
	WideCharToMultiByte(CP_UTF8, 0, pwszTmp, -1, szStrEnc, nCharLen, NULL, NULL);
	free(pwszTmp);

	szStrEnc[nCharLen]=0;
	return szStrEnc;
}

char *DecodeFromUTF8_S(const char* lpszUTF8)
{
	int      nCharLen = 0;
	wchar_t *pwszTmp = NULL;
	if(IsEmptyStr(lpszUTF8))
		return NULL ;

	nCharLen = MultiByteToWideChar(CP_UTF8, 0, lpszUTF8, -1, NULL, 0); 
	pwszTmp  = (wchar_t*) malloc(sizeof(wchar_t)*(nCharLen+1)); 
	MultiByteToWideChar(CP_UTF8, 0, lpszUTF8, -1, pwszTmp, nCharLen);

	nCharLen = WideCharToMultiByte(CP_ACP, 0, pwszTmp, -1, NULL, 0, NULL, NULL); 
	WideCharToMultiByte(CP_ACP, 0, pwszTmp, -1, szStrDec, nCharLen, NULL, NULL);
	free(pwszTmp);

	szStrDec[nCharLen] = 0 ;
	return szStrDec;
}


// static WCHAR wszString[0x10000]={0} ;
static char  szString[0x10000 ]={0} ;
// 
// WCHAR *S_A2W(const char* lpszSrc)
// {
// 	if(IsEmptyStr(lpszSrc))
// 		return NULL ;
// 
// 	USES_CONVERSION ;
// 	wcscpy(wszString,A2W(lpszSrc));
// 	int  nCharLen = MultiByteToWideChar(CP_ACP, 0, lpszSrc, -1, NULL, 0); 
// 	//MultiByteToWideChar(CP_ACP, 0, lpszSrc, -1, wszString, nCharLen); 
// 
// 	wszString[nCharLen] = 0;
// 	return wszString ;
// }
// 
// WCHAR *D_A2W(const char* lpszSrc)
// {
// 	if(IsEmptyStr(lpszSrc))
// 		return NULL ;
// 
// 
// 	int      nCharLen = MultiByteToWideChar(CP_ACP, 0, lpszSrc, -1, NULL, 0); 
// 	wchar_t *pwszTmp  = (wchar_t*) malloc(sizeof(wchar_t)*(nCharLen+1)); 
// 	MultiByteToWideChar(CP_ACP, 0, lpszSrc, -1, pwszTmp, nCharLen); 
// 
// 	return pwszTmp ;
// }
// 
// char *S_W2A(LPCWSTR lpszSrc)
// {
// 	if(IsEmptyWStr(lpszSrc))
// 		return NULL ;
// 
// 	int nCharLen = WideCharToMultiByte(CP_OEMCP, 0, lpszSrc, -1, NULL, -1, NULL, NULL);
// 	if(nCharLen==0)
// 	{
// 		char *pszTmp = (char *)lpszSrc;
// 		nCharLen = strlen(pszTmp);
// 		strcpy(szString,pszTmp);
// 	}
// 	else
// 	{
// 		WideCharToMultiByte(CP_OEMCP, 0, lpszSrc, -1, szString, nCharLen, NULL, NULL);
// 	}
// 
// 	szString[nCharLen] = 0 ;
// 
// 	return szString ;
// }
// 
// char *D_W2A(LPCWSTR lpszSrc)
// {
// 	if(IsEmptyWStr(lpszSrc))
// 		return NULL ;
// 
// 	int  nCharLen = WideCharToMultiByte(CP_ACP, 0, lpszSrc, -1, NULL, -1, NULL, NULL);
// 	char *pszDest = (char *)malloc(nCharLen+1);
// 	WideCharToMultiByte(CP_ACP, 0, lpszSrc, -1, pszDest, nCharLen, NULL, NULL);
// 	pszDest[nCharLen] = 0 ;
// 
// 	return pszDest ;
// }

// bool IsHasChinese( char *pName )
// {
// 	bool bHasChinese = 0;
// 	int index = 0;	
// 	while(pName[index] != NULL)
// 	{
// 		if(pName[index] < 0)
// 		{
// 			bHasChinese = 1;
// 			break;
// 		}
// 		index++;
// 	}
// 
// 	return bHasChinese;
// }

#else

char *EncodeToUTF8(const char* lpszSrc)     //Must free() return pionter!
{
	return lpszSrc;
}
char *DecodeFromUTF8(const char* lpszUTF8)  //Must free() return pionter!
{
	return lpszUTF8;
}
char *EncodeToUTF8_S(const char* lpszSrc)   //Must NO free() !!
{
	return lpszSrc;
}
char *DecodeFromUTF8_S(const char* lpszUTF8)//Must NO free() !!
{
	return lpszUTF8;
}

#endif

int IsTextUTF8(const char* str,long length)
{
	int i;
	int nBytes=0;//UFT8可用1-6个字节编码,ASCII用一个字节
	unsigned char chr;
	int bAllAscii=1; //如果全部都是ASCII, 说明不是UTF-8
	for(i=0;i<length;i++)
	{
		chr= *(str+i);
		if( (chr&0x80) != 0 ) // 判断是否ASCII编码,如果不是,说明有可能是UTF-8,ASCII用7位编码,但用一个字节存,最高位标记为0,o0xxxxxxx
			bAllAscii= 0;
		if(nBytes==0) //如果不是ASCII码,应该是多字节符,计算字节数
		{
			if(chr>=0x80)
			{
				if(chr>=0xFC&&chr<=0xFD)
					nBytes=6;
				else if(chr>=0xF8)
					nBytes=5;
				else if(chr>=0xF0)
					nBytes=4;
				else if(chr>=0xE0)
					nBytes=3;
				else if(chr>=0xC0)
					nBytes=2;
				else
				{
					return 0;
				}
				nBytes--;
			}
		}
		else //多字节符的非首字节,应为 10xxxxxx
		{
			if( (chr&0xC0) != 0x80 )
			{
				return 0;
			}
			nBytes--;
		}
	}

	if( nBytes > 0 ) //违返规则
	{
		return 0;
	}

	if( bAllAscii ) //如果全部都是ASCII, 说明不是UTF-8
	{
		return 0;
	}
	return 1;
}

// bool IsHasChineseAndIsUTF8( const char* str )
// {
// 	bool bHasChinese = 0;
// 	int index = 0;	
// 	while(str[index] != NULL)
// 	{
// 		if(str[index] < 0)
// 		{
// 			bHasChinese = 1;
// 			break;
// 		}
// 		index++;
// 	}
// 
// 	if(bHasChinese)
// 	{
// 		int len = strlen(str);
// 		len = (len - index) > 6 ? 6 : (len - index);
// 		return IsTextUTF8(str+index,len);
// 	}
// 	else
// 	{
// 		return 0;
// 	}
// }