/*
*  COPYRIGHT NOTICE
*  Copyright (C) 2015, Jhuster, All Rights Reserved
*  Author: Jhuster(lujun.hust@gmail.com)
*
*  https://github.com/Jhuster/TLV
*
*  This program is free software; you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation; version 2 of the License.
*/
#ifndef _TLV_BOX_H_
#define _TLV_BOX_H_

#include "key_list.h"

typedef enum _opt_type {
	OPT_TYPE_CHAR = 1,
	OPT_TYPE_SHORT = 2,
	OPT_TYPE_INT = 3,
	OPT_TYPE_LONG = 4,
	OPT_TYPE_LONGLONG = 5,
	OPT_TYPE_FLOAT = 6,
	OPT_TYPE_DOUBLE = 7,
	OPT_TYPE_STRING = 8,
	OPT_TYPE_BYTES = 9,
	OPT_TYPE_TLVOBJ = 10
}OPT_TYPE;

typedef struct _tlv {
	int type;
	int length;
	OPT_TYPE opt;
	unsigned char *_value;
} tlv_t;

typedef struct _tlv_box {
	key_list_t *m_list;
	unsigned char *m_serialized_buffer;
	int m_serialized_bytes;
} tlv_box_t;

tlv_box_t *tlv_box_create();
tlv_box_t *tlv_box_parse(const unsigned char *buffer,int buffersize);
int tlv_box_destroy(tlv_box_t *box);

unsigned char *tlv_box_get_buffer(tlv_box_t *box);
int tlv_box_get_size(tlv_box_t *box);

int tlv_box_parse_item(tlv_box_t *box,int type, OPT_TYPE opt, void *_value,int length);

int tlv_box_put_char(tlv_box_t *box,int type,char _value);
int tlv_box_put_short(tlv_box_t *box,int type,short _value);
int tlv_box_put_int(tlv_box_t *box,int type,int _value);
int tlv_box_put_long(tlv_box_t *box,int type,long _value);
int tlv_box_put_longlong(tlv_box_t *box,int type,long long _value);
int tlv_box_put_float(tlv_box_t *box,int type,float _value);
int tlv_box_put_double(tlv_box_t *box,int type,double _value);
int tlv_box_put_string(tlv_box_t *box,int type,char* _value);
int tlv_box_put_bytes(tlv_box_t *box,int type,unsigned char *_value,int length);
int tlv_box_put_object(tlv_box_t *box,int type,tlv_box_t *object);
int tlv_box_serialize(tlv_box_t *box);

int tlv_box_get_char(tlv_box_t *box,int type,char *_value);
int tlv_box_get_short(tlv_box_t *box,int type,short *_value);
int tlv_box_get_int(tlv_box_t *box,int type,int *_value);
int tlv_box_get_long(tlv_box_t *box,int type,long *_value);
int tlv_box_get_longlong(tlv_box_t *box,int type,long long *_value);
int tlv_box_get_float(tlv_box_t *box,int type,float *_value);
int tlv_box_get_double(tlv_box_t *box,int type,double *_value);
int tlv_box_get_string(tlv_box_t *box,int type,char *_value,int* length);
int tlv_box_get_bytes(tlv_box_t *box,int type,unsigned char *_value,int* length);
int tlv_box_get_bytes_ptr(tlv_box_t *box,int type,unsigned char **_value,int* length);
int tlv_box_get_object(tlv_box_t *box,int type,tlv_box_t **object);

#endif //_TLV_BOX_H_
