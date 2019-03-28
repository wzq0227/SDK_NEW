#include "Tlib_ProtocolAX.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static Field *CreateField(const char * lpszFieldName,void *lpszFieldContent,int dwFieldNameLen,int dwFieldContentLen)
{
	Field *pNewField = (Field *)calloc(1,sizeof(Field));
	
	if(pNewField != NULL)
	{
		int dwLen = dwFieldNameLen ;
		if(dwLen == 0)
			dwLen = strlen((char *)lpszFieldName);
		pNewField->dwFieldNameLen = dwLen ;
		pNewField->pszFieldName = (char *)calloc(1,(dwLen+1)) ;
		if(pNewField->pszFieldName == NULL)
		{
			free(pNewField);
			return NULL ;
		}
		memcpy(pNewField->pszFieldName,lpszFieldName,dwLen);

		dwLen = dwFieldContentLen ;
		if(dwLen == 0)
			dwLen = strlen((char *)lpszFieldContent);
		pNewField->dwFieldContentLen = dwLen ;
		pNewField->pszFieldContent = (char *)calloc(1,(dwLen+1));
		if(pNewField->pszFieldContent == NULL)
		{
			if(pNewField->pszFieldName != NULL)
				free(pNewField->pszFieldName);

			free(pNewField);
			return NULL ;
		}
		memcpy(pNewField->pszFieldContent,lpszFieldContent,dwLen);
	}
	
	return pNewField;
}

static void FreeField(Field *pField)
{
	if(pField != NULL)
	{
		free(pField->pszFieldName);
		free(pField->pszFieldContent);
		free(pField);
		pField = NULL ;
	}
}

TlibFieldAx *Tlib_CreateFiled()
{
	TlibFieldAx *ptlibfield = (TlibFieldAx*)malloc(sizeof(TlibFieldAx));
	if (ptlibfield == NULL)
	{
		return NULL;
	}
	memset(ptlibfield,0,sizeof(TlibFieldAx));
	Tlib_ResetAX(ptlibfield);
	return ptlibfield;
}

void Tlib_DestroyFiled(TlibFieldAx* tlibfieldax)
{
	if (tlibfieldax != NULL)
	{
		Tlib_ResetAX(tlibfieldax);
		free(tlibfieldax);
	}
}

void Tlib_ResetAX(TlibFieldAx* tlibfieldax)
{	
	if (tlibfieldax != NULL)
	{
		Tlib_RemoveAllField(tlibfieldax);

		tlibfieldax->dwProtoVer = 0x0100;
		tlibfieldax->dwCommand  = 0x0008;

		tlibfieldax->dwBufLen   = 14;
		tlibfieldax->dwAppPos   = 0;

		if(tlibfieldax->szpCmdBuf != NULL)
		{
			free(tlibfieldax->szpCmdBuf)  ;
			tlibfieldax->szpCmdBuf = NULL ;
		}
	}
}

void Tlib_RemoveAllField(TlibFieldAx* tlibfieldax)
{
	if(tlibfieldax != NULL)
	{
		for(int i = 0; i <= tlibfieldax->filedcounts; i++)
		{
			Field *pTmp = tlibfieldax->arrFields[i];
			if (pTmp)
			{
				tlibfieldax->dwBufLen -= (pTmp->dwFieldContentLen + pTmp->dwFieldNameLen);
				FreeField(pTmp);
				tlibfieldax->arrFields[i] = NULL;
			}
		}
		tlibfieldax->filedcounts = 0;
	}

}

void Tlib_RemoveFiledByIndex(TlibFieldAx* tlibfieldax , int dwFieldIndex)
{
	if(tlibfieldax != NULL && dwFieldIndex > tlibfieldax->filedcounts)
	{
		Field *pTmp = tlibfieldax->arrFields[dwFieldIndex];
		if (pTmp)
		{
			tlibfieldax->dwBufLen -= (pTmp->dwFieldContentLen + pTmp->dwFieldNameLen);
			FreeField(pTmp);
			tlibfieldax->arrFields[dwFieldIndex] = NULL;
			tlibfieldax->filedcounts--;
		}
	}
}

void Tlib_RemoveFiledByName(TlibFieldAx* tlibfieldax ,const char * lpszFieldName)
{
	if(tlibfieldax != NULL)
	{
		for(int i = 0; i<tlibfieldax->filedcounts; i++)
		{
#ifdef WIN32
			if(stricmp(tlibfieldax->arrFields[i]->pszFieldName,lpszFieldName) == 0)
#else
			if(strcasecmp(tlibfieldax->arrFields[i]->pszFieldName,lpszFieldName) == 0)
#endif
			{
				Tlib_RemoveFiledByIndex(tlibfieldax,i);
				break ;
			}
		}
	}
}

void Tlib_AddNewFiledInt(TlibFieldAx* tlibfieldax,const char * lpszFieldName,int dwValue,int dwFormatLen,int bHexFormat)
{
	if((tlibfieldax == NULL) || (tlibfieldax->filedcounts >= MAX_ARRAY_FIELD))
		return ;

	char szFormat[32]={0};
	char szValue[64] ={0};
	if(bHexFormat)
		sprintf(szFormat,"%%0%dX",dwFormatLen);
	else
		sprintf(szFormat,"%%0%dd",dwFormatLen);

	sprintf(szValue,szFormat,dwValue);
	Tlib_AddNewFiledVoid(tlibfieldax,lpszFieldName,szValue,0,0) ;
}

void Tlib_AddNewFiledVoid(TlibFieldAx* tlibfieldax,const char * lpszFieldName,void *lpszFieldContent,int dwFieldNameLen,int dwFieldContentLen)
{
	if((tlibfieldax == NULL) || !lpszFieldName || !lpszFieldContent || Tlib_GetFieldInfoByName(tlibfieldax,lpszFieldName) != NULL || (tlibfieldax->filedcounts >= MAX_ARRAY_FIELD))
		return ;

	Field *pTmp = CreateField(lpszFieldName,lpszFieldContent,dwFieldNameLen,dwFieldContentLen);
	if (pTmp == NULL)
		return;

	tlibfieldax->dwBufLen += 8;
	tlibfieldax->dwBufLen += (pTmp->dwFieldContentLen + pTmp->dwFieldNameLen);
	tlibfieldax->arrFields[tlibfieldax->filedcounts++] = pTmp;
}

void Tlib_SetCommand(TlibFieldAx* tlibfieldax,int dwCommand)
{
	if(tlibfieldax)
		tlibfieldax->dwCommand = dwCommand;	
}

void Tlib_SetVersion(TlibFieldAx* tlibfieldax,int dwVersion)
{
	if(tlibfieldax)
		tlibfieldax->dwProtoVer = dwVersion ;
}

void Tlib_AppendToBuildBuffer(TlibFieldAx* tlibfieldax,void *pData,int dwLen)
{
	if(tlibfieldax == NULL)
		return ;
	if (tlibfieldax->szpCmdBuf == NULL)
		tlibfieldax->szpCmdBuf = (char *)calloc(1,tlibfieldax->dwBufLen+200);

	if (tlibfieldax->szpCmdBuf == NULL)
		return ;

	int dwAppLen = dwLen;
	if (dwAppLen == 0)
		dwAppLen = strlen((char*)(pData));

	memcpy(tlibfieldax->szpCmdBuf+tlibfieldax->dwAppPos,pData,dwAppLen);

	tlibfieldax->dwAppPos += dwAppLen;
}

void Tlib_DoBuildString(TlibFieldAx* tlibfieldax)
{
	if(tlibfieldax ==NULL)
		return;

	char  szTmp[32]={0} ;

	sprintf(szTmp,"%04X",tlibfieldax->dwProtoVer);
	Tlib_AppendToBuildBuffer(tlibfieldax,szTmp,0) ;

	sprintf(szTmp,"%04X",tlibfieldax->dwCommand);
	Tlib_AppendToBuildBuffer(tlibfieldax,szTmp,0) ;

	sprintf(szTmp,"%06X",0);
	Tlib_AppendToBuildBuffer(tlibfieldax,szTmp,0) ;

	int nFieldCount = tlibfieldax->filedcounts;
	for(int i=0; i<nFieldCount; i++)
	{
		Field *pTF = tlibfieldax->arrFields[i] ;

		sprintf(szTmp,"%02X",pTF->dwFieldNameLen) ;		
		Tlib_AppendToBuildBuffer(tlibfieldax,szTmp,0) ;

		sprintf(szTmp,"%06X",pTF->dwFieldContentLen) ;
		Tlib_AppendToBuildBuffer(tlibfieldax,szTmp,0) ;

		Tlib_AppendToBuildBuffer(tlibfieldax,pTF->pszFieldName,pTF->dwFieldNameLen) ;
		Tlib_AppendToBuildBuffer(tlibfieldax,pTF->pszFieldContent,pTF->dwFieldContentLen) ;
	}

	if(nFieldCount>0)
	{
		sprintf(szTmp,"%06X",tlibfieldax->dwAppPos - 14);
		memcpy(tlibfieldax->szpCmdBuf+8,szTmp,6);
	}
}

void Tlib_DoDecodeString(TlibFieldAx* tlibfieldax,char *pszSrcBuf)
{
	if (!pszSrcBuf || !tlibfieldax) return;
	
	int dwDataLen = 0 ;
	char szTmp[0xFF]  = {0};

	Tlib_ResetAX(tlibfieldax) ;

	memcpy(szTmp,pszSrcBuf,4);
	sscanf(szTmp,"%04X",&tlibfieldax->dwProtoVer);

	memcpy(szTmp,pszSrcBuf+4,4);
	sscanf(szTmp,"%04X",&tlibfieldax->dwCommand);			// 9 means thransmit data ack

	memcpy(szTmp,pszSrcBuf+8,6);
	sscanf(szTmp,"%06X",&dwDataLen);

	if (dwDataLen > 0x2ffff*8)
		return ;

	char *pTmp = pszSrcBuf+14 ;

	int dwReadCount      = 0 ;
	int nFieldNameLen    = 0 ;
	int nFieldContentLen = 0 ;

	while(1)
	{
		memcpy(szTmp,pTmp+dwReadCount,2);				// 属性名长度
		dwReadCount += 2 ;
		sscanf(szTmp,"%02X",&nFieldNameLen) ;
		if(nFieldNameLen>dwDataLen || nFieldNameLen < 0)
			break;

		memcpy(szTmp,pTmp+dwReadCount,6);				// 属性值长度
		dwReadCount += 6 ;
		sscanf(szTmp,"%06X",&nFieldContentLen) ;

		if (nFieldContentLen>dwDataLen)
			break;

		char *pszTmp1 = (char *)calloc(1,nFieldNameLen+1);
		if(pszTmp1 == NULL)
			break;
		memcpy(pszTmp1,pTmp+dwReadCount,nFieldNameLen);
		dwReadCount += nFieldNameLen ;

		char *pszTmp2 = (char *)calloc(1,nFieldContentLen+1);
		if (pszTmp2 == NULL)
			break;
		memcpy(pszTmp2,pTmp+dwReadCount,nFieldContentLen);
		dwReadCount += nFieldContentLen ;

		Tlib_AddNewFiledVoid(tlibfieldax,pszTmp1,pszTmp2,nFieldNameLen,nFieldContentLen);

		free(pszTmp1);
		free(pszTmp2);

		if(dwReadCount>=dwDataLen)
			break;
	}
}

Field *Tlib_GetFieldInfoByIndex(TlibFieldAx *tlibfieldax,int dwFieldIndex)
{
	if((tlibfieldax == NULL) || dwFieldIndex >= tlibfieldax->filedcounts)
		return NULL;

	return tlibfieldax->arrFields[dwFieldIndex];
}

Field *Tlib_GetFieldInfoByName(TlibFieldAx *tlibfieldax,const char * lpszFieldName)
{
	if(tlibfieldax != NULL)
	{
		for(int i=0; i<tlibfieldax->filedcounts; i++)
		{
#ifdef WIN32
			if(stricmp(tlibfieldax->arrFields[i]->pszFieldName,lpszFieldName) == 0)
#else
			if(strcasecmp(tlibfieldax->arrFields[i]->pszFieldName,lpszFieldName) == 0)
#endif
			{
				return tlibfieldax->arrFields[i];
			}
		}
	}
	return NULL ;
}