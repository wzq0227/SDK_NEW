#include "NetProCommon.h"
#include "tutk/TutkProtocol.h"
#include "p2psdk/P2pProtocol.h"
#include <stdio.h>


CNetProCommon* CreateChildPro(eNetProType eType)
{	
	CNetProCommon* pNet = NULL;

	if(eType == NETPRO_USE_TUTK)
	{
		pNet = new CTutkProtocol();
	}
	else if(eType == NETPRO_USE_4_0)
	{
		pNet = new CP2pProtocol();
	}

	return pNet;
}