#ifndef _G711_DECODER_H_
#define _G711_DECODER_H_


class CG711Decoder  
{
public:
	CG711Decoder();
	virtual ~CG711Decoder();

	int G711_EnCode(unsigned char* pCodecBits, const char* pBuffer, int nBufferSize);
	int G711_Decode(char* pRawData, const unsigned char* pBuffer, int nBufferSize);
	unsigned char encode(short pcm);
	short decode(unsigned char alaw);
};

#endif 
