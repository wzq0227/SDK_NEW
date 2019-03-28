// G711Decoder.cpp: implementation of the CG711Decoder class.
//
//////////////////////////////////////////////////////////////////////

#include "G711Decoder.h"


CG711Decoder::CG711Decoder()
{

}

CG711Decoder::~CG711Decoder()
{

}

// ±àÂë
int CG711Decoder::G711_EnCode(unsigned char* pCodecBits, const char* pBuffer, int nBufferSize)
{
	short* buffer = (short*)pBuffer;
	for(int i=0; i<nBufferSize/2; i++)
	{
		pCodecBits[i] = encode(buffer[i]);
	}
  
	return nBufferSize/2;
}	
  
// ½âÂë
int CG711Decoder::G711_Decode(char* pRawData, const unsigned char* pBuffer, int nBufferSize)
{
	short *out_data = (short*)pRawData;
	for(int i=0; i<nBufferSize; i++)
	{
		out_data[i] = decode(pBuffer[i]);
	}
	
	return nBufferSize*2;
}

unsigned char CG711Decoder::encode(short pcm)
{
	int sign = (pcm & 0x8000) >> 8;
	if (sign != 0)
	{
		pcm = -pcm;
	}
	if (pcm > 32635) pcm = 32635;
	int exponent = 7;
	int expMask;
	for (expMask = 0x4000; (pcm & expMask) == 0	
		&& exponent>0; exponent--, expMask >>= 1)
	{
	}
	int mantissa = (pcm >> ((exponent == 0) ? 4 : (exponent + 3))) & 0x0f;
	unsigned char alaw = (unsigned char)(sign | exponent << 4 | mantissa);
	return (unsigned char)(alaw^0xD5);
}

short CG711Decoder::decode(unsigned char alaw)
{
	alaw ^= 0xD5;
	int sign = alaw & 0x80;
	int exponent = (alaw & 0x70) >> 4;
	int data = alaw & 0x0f;
	data <<= 4;
	data += 8;
	if (exponent != 0)
	{
		data += 0x100;
	}
	if (exponent > 1)
	{
		data <<= (exponent - 1);
	}

	return (short)(sign == 0 ? data : -data);
} 

