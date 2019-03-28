#ifndef __ENCRYPT_DEF__
#define __ENCRYPT_DEF__

#ifdef __cplusplus
extern "C" {
#endif

void free_data(unsigned char* data);

void init_rand_ex();
void gen_rand(unsigned char* buf, unsigned int buflen);

void sha256_mac(unsigned char *data, unsigned int dataLen, unsigned char mac[32]);

int base64_encode(unsigned char *data, unsigned int dataLen, unsigned char **encData, unsigned int *encDataLen);
int base64_decode(unsigned char *data, unsigned int dataLen, unsigned char **decData, unsigned int *decDataLen);

long aes256_cbc_enc_by_head(unsigned char *head, unsigned int headLen, unsigned char *data, unsigned int dataLen,
		unsigned char **encData, unsigned int *encDataLen, unsigned char key[32]);
long aes256_cbc_enc(unsigned char *data, unsigned int dataLen, unsigned char **encData, unsigned int *encDataLen, unsigned char key[32]);
long aes256_cbc_dec(unsigned char *data, unsigned int dataLen, unsigned char **decData, unsigned int *decDataLen, unsigned char key[32]);

int xor_encrypt_64(unsigned char* data, unsigned int dataLen, unsigned char key[64]);



#ifdef __cplusplus
}
#endif

#endif
