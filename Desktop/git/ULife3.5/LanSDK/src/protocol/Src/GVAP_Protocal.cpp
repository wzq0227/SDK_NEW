/********************************************************
*@file   GVAPProtocal.cpp
*@brief  Implementation file
*		    GVAP协议的C语言接口实现
*@date   2011-06-09 11:11:26
*
*@author  Eric Guo <guojl@goscam.com>
**********************************************************/
#include "GVAP_Protocal.h"
#include "GVAP_PackageHeader.h"
#include <assert.h>

GVAP_Builder*  createPackage(char *cmdLine, int type)
{
	assert(cmdLine);
	CGVAPPackageBuilder *builder = new CGVAPPackageBuilder(cmdLine, type);
	return builder;
}
void releasePackage(GVAP_Builder* header)
{
	assert(header);
	CGVAPPackageBuilder *builder = (CGVAPPackageBuilder*)header;
	delete builder;
}
int  addSection(GVAP_Builder* header, char *name, int nameLen, char *value, int valueLen)
{
	assert(header);
	CGVAPPackageBuilder *builder = (CGVAPPackageBuilder*)header;
	return builder->addSection(name, nameLen, value, valueLen);
}
int  addIntegerSection(GVAP_Builder* header, char *name, int nameLen, int value)
{
	assert(header);
	CGVAPPackageBuilder *builder = (CGVAPPackageBuilder*)header;
	return builder->addIntegerSection(name, nameLen, value);
}
char *getHeaderBuffer(GVAP_Builder* header)
{
	assert(header);
	CGVAPPackageBuilder *builder = (CGVAPPackageBuilder*)header;
	return builder->getBuffer();
}
int	  getHeaderLen(GVAP_Builder* header)
{
	assert(header);
	CGVAPPackageBuilder *builder = (CGVAPPackageBuilder*)header;
	return builder->getDataLen();
}

///////////////////////////////packge Parser  ////////////////
GVAP_Parser* parsePackage(char *buffer, int bufLen)
{
	CGVAPPackageParser *parser = new CGVAPPackageParser();
	parser->parse(buffer, bufLen);
	return parser;
}
void releaseParser(GVAP_Parser* arg)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	delete parser;
}

int getType(GVAP_Parser* arg)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getType();
} 
int	getStatusCode(GVAP_Parser* arg)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getStatusCode();
} 
int	getCommand(GVAP_Parser* arg, char **pCmd, int *cmdLen)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getCommand(pCmd, *cmdLen);
} 
int	getResourceName(GVAP_Parser* arg, char **pResource, int *resourceLen)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getResourceName(pResource, *resourceLen);
} 
int getStatusDescription(GVAP_Parser* arg, char **pDescription, int *discriptionLen)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getStatusDescription(pDescription, *discriptionLen);
} 
int getVersion(GVAP_Parser* arg, char **pVersion, int *versionLen)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getVersion(pVersion, *versionLen);
} 
int	getSectionByName(GVAP_Parser* arg, const char *pName, char **pValue, int *valueLen)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getSectionByName(pName, pValue, *valueLen);
} 
int getIntegerSectionWithDefault(GVAP_Parser* arg, const char *pName, int nDefault)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getIntegerSectionWithDefault(pName, nDefault);
} 

// 大于等于0表示还有后续的值需要解析，小于等于0表示解析结束或者失败
int	  getNextSection(GVAP_Parser* arg, char **pName, int *nameLen, char **pValue, int *valueLen)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getNextSection(pName, *nameLen, pValue, *valueLen);
} 

char* getBuffer(GVAP_Parser* arg)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getBuffer();
} 
int  getBufferLen(GVAP_Parser* arg)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getBufferLen();
} 
int getContentLength(GVAP_Parser* arg)
{
	assert(arg);
	CGVAPPackageParser *parser = (CGVAPPackageParser*)arg;
	return parser->getContentLength();
} 
int  getContentLengthFromBuffer(char *buf, int bufLen)
{
	return CGVAPPackageParser::getContentLength(buf, bufLen);
}


