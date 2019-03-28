
#ifndef __UTF8UTILS_H__
#define __UTF8UTILS_H__

#ifdef __cplusplus
extern "C" {
#endif

#ifndef  IsEmptyStr
#define  IsEmptyStr(pstr)  ( (pstr == NULL) || (strlen(pstr) == 0) )
#endif

#ifndef  IsEmptyWStr
#define  IsEmptyWStr(pstr)  ( (pstr == NULL) || (wcslen(pstr) == 0) )
#endif

char *EncodeToUTF8(const char* lpszSrc);     //Must free() return pionter!
char *DecodeFromUTF8(const char* lpszUTF8);  //Must free() return pionter!
char *EncodeToUTF8_S(const char* lpszSrc);   //Must NO free() !!
char *DecodeFromUTF8_S(const char* lpszUTF8);//Must NO free() !!

// WCHAR *S_A2W(const char* lpszSrc) ;  //Must NO free() !!
// WCHAR *D_A2W(const char* lpszSrc) ;  //Must free() return pionter!
// char  *S_W2A(LPCWSTR lpszSrc) ; //Must NO free() !!
// char  *D_W2A(LPCWSTR lpszSrc) ; //Must free() return pionter!

int IsTextUTF8(const char* str,long length);
// bool IsHasChinese(char *pName);
// bool IsHasChineseAndIsUTF8(const char* str);

#ifdef __cplusplus
}
#endif

#endif
