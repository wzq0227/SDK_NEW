// CGOSCAMProtocolAX.h: interface for the CProtocolAX class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_PROTOCOLAX_H__978E7552_2498_4E06_AFA0_DBD2394F1FBF__INCLUDED_)
#define AFX_PROTOCOLAX_H__978E7552_2498_4E06_AFA0_DBD2394F1FBF__INCLUDED_

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_ARRAY_FIELD		100

	typedef struct _filedAx
	{
		int dwFieldNameLen ;
		int dwFieldContentLen ;
		char *pszFieldName;
		char *pszFieldContent;
	}Field;

	typedef struct _tlibfiledax
	{
		Field * arrFields[MAX_ARRAY_FIELD];
		int filedcounts;
		char  *szpCmdBuf;
		int  dwBufLen;
		int  dwAppPos;
		int  dwProtoVer;
		int  dwCommand;
	}TlibFieldAx;

	TlibFieldAx *Tlib_CreateFiled();
	void Tlib_DestroyFiled(TlibFieldAx* tlibfieldax);

	void Tlib_ResetAX(TlibFieldAx* tlibfieldax) ;
	void Tlib_RemoveAllField(TlibFieldAx* tlibfieldax);
	void Tlib_RemoveFiledByIndex(TlibFieldAx* tlibfieldax,int dwFieldIndex);
	void Tlib_RemoveFiledByName(TlibFieldAx* tlibfieldax,const char * lpszFieldName);
	void Tlib_AddNewFiledVoid(TlibFieldAx* tlibfieldax,const char * lpszFieldName,void *lpszFieldContent,int dwFieldNameLen,int dwFieldContentLen);
	void Tlib_AddNewFiledInt(TlibFieldAx* tlibfieldax,const char * lpszFieldName,int dwValue,int dwFormatLen,int bHexFormat);

	void Tlib_SetCommand(TlibFieldAx* tlibfieldax,int dwCommand);
	void Tlib_SetVersion(TlibFieldAx* tlibfieldax,int dwVersion);

	void Tlib_DoBuildString(TlibFieldAx* tlibfieldax) ;
	void Tlib_DoDecodeString(TlibFieldAx* tlibfieldax,char *pszSrcBuf) ;

	Field *Tlib_GetFieldInfoByIndex(TlibFieldAx* tlibfieldax,int dwFieldIndex);
	Field *Tlib_GetFieldInfoByName(TlibFieldAx* tlibfieldax,const char * lpszFieldName);
	void   Tlib_AppendToBuildBuffer(TlibFieldAx* tlibfieldax,void *pData,int dwLen);

#ifdef __cplusplus
}
#endif

#endif // !defined(AFX_PROTOCOLAX_H__978E7552_2498_4E06_AFA0_DBD2394F1FBF__INCLUDED_)
