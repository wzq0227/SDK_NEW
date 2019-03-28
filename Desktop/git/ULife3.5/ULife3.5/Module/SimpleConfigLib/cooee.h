#ifndef __COOEE_H__
#define __COOEE_H__

int send_cooee(const char* ssid, int ssid_len, 
    const char* pwd, int pwd_len, 
    const char* key, int key_len, 
    unsigned int ip);

#endif /* __COOEE_H__ */