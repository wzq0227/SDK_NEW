#include "encrypt_def.h"

#ifdef __APPLE__
#include <stdlib.h>
#else
#include <malloc.h>
#endif
#include <memory.h>
#include <stddef.h>


void free_data(unsigned char* data)
{
	if(data)
	{
		free((void*)data);
	}
}

int xor_encrypt_64(unsigned char* data, unsigned int dataLen, unsigned char key[64])
{
	int k = 0;
	int k_size = 64;
	int i = 0;

	if(data == NULL || dataLen < 1)
	{
		return -1;
	}

	while(i < dataLen)
	{
		data[i++] ^= key[k++];
		if(k == k_size)
		{
			k = 0;
		}
	}

	return 0;
}
