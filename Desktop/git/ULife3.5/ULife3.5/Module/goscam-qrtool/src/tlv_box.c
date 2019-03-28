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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tlv_box.h"

 // #define TYPE_STR_LEN 2+1
 // #define OPT_STR_LEN  2+1
 // #define LEN_STR_LEN  4+1
#define TYPE_STR_LEN 2+1
#define OPT_STR_LEN  1+1
#define LEN_STR_LEN  2+1

#ifndef WIN32
/*WIN32
_CRT_NONSTDC_DEPRECATE(_itoa) _CRT_INSECURE_DEPRECATE(_itoa_s)
_ACRTIMP char* __cdecl itoa(
	_In_                   int   _Value,
	_Pre_notnull_ _Post_z_ char* _Buffer,
	_In_                   int   _Radix
        );
*/
char* itoa(int num,char*str,int radix){
	int i = 0, j, k;
	char temp;
	unsigned unum;
	char index[]="0123456789ABCDEF";

  if(radix == 10 && num < 0) {
    unum = (unsigned) -num;
    str[i++]='-';
  } else
    unum= (unsigned) num;
  do{
    str[i++] = index[unum%(unsigned)radix];
    unum /= radix;
  }while(unum);
  str[i]='\0';
  if(str[0]=='-')
    k=1;
  else
    k=0;
  for(j=k;j<=(i-1)/2;j++) {
    temp=str[j];
    str[j]=str[i-1+k-j];
    str[i-1+k-j]=temp;
  }
  return str;
}
#endif

static const char* get_opt_name(OPT_TYPE opt) {
  switch (opt) {
    case OPT_TYPE_CHAR:
      return "char";
    case OPT_TYPE_SHORT:
      return "short";
    case OPT_TYPE_INT:
      return "int";
    case OPT_TYPE_LONG:
      return "long";
    case OPT_TYPE_LONGLONG:
      return "long-long";
    case OPT_TYPE_FLOAT:
      return "float";
    case OPT_TYPE_DOUBLE:
      return "double";
    case OPT_TYPE_STRING:
      return "string";
    case OPT_TYPE_BYTES:
      return "bytes";
    case OPT_TYPE_TLVOBJ:
      return "tlv-obj";
    default:
      return "unkown";
  }
}

static void tlv_box_release_tlv(value_t _value)
{
	tlv_t *tlv = (tlv_t *)_value._value;
	free(tlv->_value);
	free(tlv);
}

tlv_box_t *tlv_box_create()
{
	tlv_box_t* box = (tlv_box_t*)malloc(sizeof(tlv_box_t));
	box->m_list = key_list_create(tlv_box_release_tlv);
	box->m_serialized_buffer = NULL;
	box->m_serialized_bytes = 0;
	return box;
}

tlv_box_t *tlv_box_parse(const unsigned char *buffer,int buffersize)
{
	int offset = 0;
	int length = 0;
	int type = 0;
	OPT_TYPE opt = OPT_TYPE_CHAR;
	tlv_box_t *box = NULL;
	unsigned char *cached = NULL;

    unsigned char type_str[TYPE_STR_LEN];
    unsigned char opt_str[OPT_STR_LEN];
    unsigned char length_str[LEN_STR_LEN];

    printf("####### tlv_box_parse begin #######\n");
    box = tlv_box_create();
    cached = (unsigned char*)malloc(buffersize);
    memcpy(cached,buffer,buffersize);

    memset(type_str, '\0', TYPE_STR_LEN);
    memset(opt_str, '\0', OPT_STR_LEN);
    memset(length_str, '\0', LEN_STR_LEN);

    while (offset < buffersize) {
        memcpy(type_str, cached+offset, TYPE_STR_LEN - 1);
        offset += TYPE_STR_LEN - 1;
        memcpy(opt_str, cached+offset, OPT_STR_LEN - 1);
        offset += OPT_STR_LEN - 1;
        memcpy(length_str, cached+offset, LEN_STR_LEN - 1);
        offset += LEN_STR_LEN - 1;
        // printf("** %s,%s, %s, ", type_str, opt_str, length_str);

        type = strtol(type_str, NULL, 16);
        opt = strtol(opt_str, NULL, 16);
        length = strtol(length_str, NULL, 16);

        // length = length & 0xFFFF;
        // printf("t=%02d:0x%02x, l=%04d:0x%02x, o=%02d:%s, ", type, type, length, length, opt, get_opt_name(opt));
        tlv_box_parse_item(box,type,opt,cached+offset,length);
        offset += length;
        printf("\n");
    }

    box->m_serialized_buffer = cached;
    box->m_serialized_bytes  = buffersize;
    printf("####### tlv_box_parse end #######\n");
    return box;
}

int tlv_box_destroy(tlv_box_t *box){
  key_list_destroy(box->m_list);
  if (box->m_serialized_buffer != NULL) {
    free(box->m_serialized_buffer);
  }
  free(box);
  return 0;
}

unsigned char *tlv_box_get_buffer(tlv_box_t *box){
  if(!box->m_serialized_buffer) {
    printf("Pls call tlv_box_serialize first!\n");
  }
  return box->m_serialized_buffer;
}

int tlv_box_get_size(tlv_box_t *box){
  if(!box->m_serialized_buffer) {
    printf("Pls call tlv_box_serialize first!\n");
  }
  return box->m_serialized_bytes;
}

int tlv_box_parse_item(tlv_box_t *box,int type, OPT_TYPE opt, void *_value,int length){
	value_t object;
	tlv_t *tlv;
	tlv = (tlv_t *)malloc(sizeof(tlv_t));
	tlv->type = type;
	tlv->opt = opt;
	tlv->length = length;
	tlv->_value = (unsigned char *)malloc(length);
	// memset(tlv->_value, '\0', length);
	memcpy(tlv->_value,_value,length);
	// printf("## get-tlv: t=0x%02x, l=0x%04x, o=0x%02x:%s, v=%s",
	//   type, length, opt, get_opt_name(opt), tlv->_value);
	printf("## get-tlv: t=0x%02x, l=%d:0x%02x, o=0x%x:%s, v=%s",
		type, length, length, opt, get_opt_name(opt), tlv->_value);

	object._value = tlv;

	if (key_list_add(box->m_list,type,object) != 0) {
		printf("XXXXXXXXXXXXXXXXXXXX dec ERROR! \n");
		free(tlv);
		return -1;
	}
	// sizeof(TYPE) + sizeof(OPT_TYPE) + sizeof(LENGTH)
	// box->m_serialized_bytes += 2 + 2 + 4 + length;
	box->m_serialized_bytes += 2 + 1 + 2 + length;
	return 0;
}

int tlv_box_putobject(tlv_box_t *box,int type, OPT_TYPE opt, void *_value,int length)
{
	value_t object;
	char g_str[25];
	tlv_t *tlv;
	unsigned char * temp;

	memset(g_str, '\0', 25);
	temp = (unsigned char *)malloc(length);
	memset(temp, '\0', length);
	memcpy(temp, _value, length);

	tlv = (tlv_t *)malloc(sizeof(tlv_t));
	tlv->type = type;
	tlv->opt = opt;
	switch (opt) {
	  case OPT_TYPE_SHORT:
#if (defined _WINDOWS) || (defined WIN32)
		  sprintf_s(g_str, sizeof(g_str), "%x", (*(short*)(temp)));
#else
		  sprintf(g_str, "%x", (*(short*)(temp)));
#endif
		  break;
	  case OPT_TYPE_INT:
#if (defined _WINDOWS) || (defined WIN32)
		  sprintf_s(g_str, sizeof(g_str), "%x", (*(int*)(temp)));
#else
		  sprintf(g_str, "%x", (*(int*)(temp)));
#endif
		  break;
	  case OPT_TYPE_LONG:
#if (defined _WINDOWS) || (defined WIN32)
		  sprintf_s(g_str, sizeof(g_str), "%x", (*(long*)(temp)));
#else
		  sprintf(g_str, "%x", (*(long*)(temp)));
#endif
		  break;
	  case OPT_TYPE_LONGLONG:
#if (defined _WINDOWS) || (defined WIN32)
		  // sprintf_s(g_str, sizeof(g_str), "%I64x", (*(long long*)(temp)));
		  sprintf_s(g_str, sizeof(g_str), "%llx", (*(long long*)(temp)));
#else
		  sprintf(g_str, "%lx", (*(long long*)(temp)));
#endif
		  break;
	  case OPT_TYPE_FLOAT:
#if (defined _WINDOWS) || (defined WIN32)
		// sprintf_s(g_str, sizeof(g_str), "%f", (*(float*)(temp)));
		// _gcvt_s(cArray1, nResult, 10);// (n).(10)
		// 20=sizeof(cArray2); (n).(10)
		//_gcvt_s(cArray2, 20, nResult, 10);
		// _gcvt(nResult, 12, cArray3); // (n).(12)
		_gcvt_s(g_str, sizeof(g_str), (*(float *)(temp)), 10);
#else
		sprintf(g_str, "%f", (*(float*)(temp)));
#endif
        break;
      case OPT_TYPE_DOUBLE:
#if (defined _WINDOWS) || (defined WIN32)
		// sprintf_s(g_str, sizeof(g_str), "%f", (*(double*)(temp)));
		// sprintf(g_str, "%f", (*(double*)(temp)));
		// gcvt((*(double *)(temp)), 10, g_str);
		_gcvt_s(g_str, sizeof(g_str), (*(double *)(temp)), 10);
#else
		sprintf(g_str, "%f", (*(double*)(temp)));
#endif
		break;
	  case OPT_TYPE_STRING:
		  //if((*(char*)(_value+length)) == '\0'){
			  // printf("str[%d] == \'\\0\' \n", length);
			  // // length = length - 1;
		  //} else {
			  // printf("str[%d]= %c, != \'\\0\' \n", (*(char*)(_value+length)), length);
		 // }
		  break;
	}
	switch (opt) {
	  case OPT_TYPE_SHORT:
	  case OPT_TYPE_INT:
	  case OPT_TYPE_LONG:
	  case OPT_TYPE_LONGLONG:
		case OPT_TYPE_FLOAT:
	  case OPT_TYPE_DOUBLE:
		  length = strlen(g_str);
		  tlv->length = strlen(g_str);
		  tlv->_value = (unsigned char *)malloc(tlv->length);
		  memcpy(tlv->_value,g_str,tlv->length);
		  // printf("## put-tlv: t=0x%02x, l=0x%04x, o=0x%02x:%s, v=%s\n",
		  //   type, tlv->length, opt, get_opt_name(opt), g_str);
		  printf("## put-tlv: t=0x%02x, l=0x%02x, o=0x%x:%s, v=%s\n",
			  type, tlv->length, opt, get_opt_name(opt), g_str);
		  break;
	  // case OPT_TYPE_FLOAT:
	  // case OPT_TYPE_DOUBLE:
		//   length = strlen(temp);
		//   tlv->length = strlen(temp);
		//   tlv->_value = (unsigned char *)malloc(tlv->length);
		//   memcpy(tlv->_value, temp, tlv->length);
		//   // printf("## put-tlv: t=0x%02x, l=0x%04x, o=0x%02x:%s, v=%s\n",
		//   //   type, tlv->length, opt, get_opt_name(opt), g_str);
		//   printf("## put-tlv: t=0x%02x, l=0x%02x, o=0x%x:%s, v=%s\n",
		// 	  type, tlv->length, opt, get_opt_name(opt), temp);
		  // break;
	  case OPT_TYPE_CHAR:
	  case OPT_TYPE_STRING:
	  case OPT_TYPE_BYTES:
	  case OPT_TYPE_TLVOBJ:
	  default:
		  tlv->length = length;
		  tlv->_value = (unsigned char *)malloc(length);
		  memcpy(tlv->_value,_value,length);
		  // printf("## put-tlv: t=0x%02x, l=0x%04x, o=0x%02x:%s, v=%s\n",
		  //   type, tlv->length, opt, get_opt_name(opt), tlv->_value);
		  printf("## put-tlv: t=0x%02x, l=0x%02x, o=0x%x:%s, v=%s\n",
			  type, tlv->length, opt, get_opt_name(opt), tlv->_value);
		  break;
	}

	object._value = tlv;

	free(temp);

	if (key_list_add(box->m_list,type,object) != 0) {
		printf("XXXXXXXXXXXXXXXXXXXX enc ERROR! \n");
		free(tlv);
		return -1;
	}
	// sizeof(TYPE) + sizeof(OPT_TYPE) + sizeof(LENGTH)
	// box->m_serialized_bytes += 2 + 2 + 4 + length;
	box->m_serialized_bytes += 2 + 1 + 2 + length;
	return 0;
}

int tlv_box_put_char(tlv_box_t *box,int type,char _value)
{
	return tlv_box_putobject(box,type,OPT_TYPE_CHAR,&_value,sizeof(char));
}

int tlv_box_put_short(tlv_box_t *box,int type,short _value)
{
	return tlv_box_putobject(box,type,OPT_TYPE_SHORT,&_value,sizeof(short));
}

int tlv_box_put_int(tlv_box_t *box,int type,int _value)
{
	return tlv_box_putobject(box,type,OPT_TYPE_INT,&_value,sizeof(int));
}

int tlv_box_put_long(tlv_box_t *box,int type,long _value)
{
	return tlv_box_putobject(box,type,OPT_TYPE_LONG,&_value,sizeof(long));
}

int tlv_box_put_longlong(tlv_box_t *box,int type,long long _value)
{
	return tlv_box_putobject(box,type,OPT_TYPE_LONGLONG,&_value,sizeof(long long));
}

int tlv_box_put_float(tlv_box_t *box,int type,float _value)
{
	return tlv_box_putobject(box,type,OPT_TYPE_FLOAT,&_value,sizeof(float));
}

int tlv_box_put_double(tlv_box_t *box,int type,double _value)
{
	return tlv_box_putobject(box,type,OPT_TYPE_DOUBLE,&_value,sizeof(double));
}

int tlv_box_put_string(tlv_box_t *box,int type,char *_value)
{
	// printf("put_str: strlen=%d, %s\n", strlen(_value), _value);
	return tlv_box_putobject(box,type,OPT_TYPE_STRING,_value,strlen(_value));
}

int tlv_box_put_bytes(tlv_box_t *box,int type,unsigned char *_value,int length)
{
	return tlv_box_putobject(box,type,OPT_TYPE_BYTES,_value,length);
}

int tlv_box_put_object(tlv_box_t *box,int type,tlv_box_t *object)
{
	// printf("## chk tlv obj: %d, %s\n", tlv_box_get_size(object), tlv_box_get_buffer(object));
	return tlv_box_putobject(box,type,OPT_TYPE_TLVOBJ,tlv_box_get_buffer(object),tlv_box_get_size(object));
}

int tlv_box_serialize(tlv_box_t *box)
{
	int offset = 0;
	int count = 0;
	unsigned char* buffer;
	tlv_t *tlv;
	unsigned char opt;
	key_list_node_t *_node = NULL;
	key_list_node_t* V;

	printf("####### tlv_box_serialize begin #######\n");
	if (box->m_serialized_buffer != NULL) {
		free(box->m_serialized_buffer);
		box->m_serialized_buffer = NULL;
	}

	opt = OPT_TYPE_CHAR & 0xFF;
	// printf("chk box->m_serialized_bytes=%d\n", box->m_serialized_bytes);
	buffer = (unsigned char*)malloc(box->m_serialized_bytes+1);
	memset(buffer, '\0', box->m_serialized_bytes+1);
	//key_list_foreach(box->m_list,node)
//#define key_list_foreach(L,V)

	for (V = _node = box->m_list->header; _node != NULL; V = _node = _node->next)
	{
		tlv = (tlv_t *)_node->_value._value;
		// sprintf(buffer+offset, "%02x%02x%04x", tlv->type, tlv->opt, tlv->length);
		// offset += 8;
		// sprintf(buffer+offset, "%02x%x%02x", tlv->type, tlv->opt, tlv->length);
#if (defined _WINDOWS) || (defined WIN32)
		sprintf_s((char*)(buffer + offset), (box->m_serialized_bytes + 1 -offset), "%02x%x%02x", tlv->type, tlv->opt, tlv->length);
#else
		sprintf(buffer + offset, "%02x%x%02x", tlv->type, tlv->opt, tlv->length);
#endif
		offset += 2 + 1 + 2;
		memcpy(buffer+offset,tlv->_value,tlv->length);
		offset += tlv->length;
		printf("## serialized-tlv: [%d,%d]: t=0x%02x, o=0x%x:%s, l=%d:0x%02x, v=%s\n",
			count++, offset, tlv->type, opt, get_opt_name(tlv->opt), tlv->length, tlv->length, tlv->_value);
		// printf("## serialized-tlv: [%d,%d]: t=0x%02x, o=0x%x:%s, l=%d, v=%s\n",
		//   count++, offset, tlv->type, opt, get_opt_name(tlv->opt), tlv->length, tlv->_value);
	}
	box->m_serialized_buffer = buffer;
	printf("## tlv-final: %d, strlen=%d, %s\n",
		box->m_serialized_bytes,
		strlen(box->m_serialized_buffer),
		box->m_serialized_buffer);
	printf("####### tlv_box_serialize end #######\n");
	return 0;
}

int tlv_box_get_char(tlv_box_t *box,int type,char *_value)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		return -1;
	}
	tlv = (tlv_t *)object._value;
	*_value = (*(char *)(tlv->_value));
	return 0;
}

int tlv_box_get_short(tlv_box_t *box,int type,short *_value)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		return -1;
	}
	tlv = (tlv_t *)object._value;
	// *_value = (*(short *)(tlv->_value));
	*_value = (short)strtol(tlv->_value, NULL, 16);
	return 0;
}

int tlv_box_get_int(tlv_box_t *box,int type,int *_value)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		return -1;
	}
	tlv = (tlv_t *)object._value;
	// *_value = (*(int *)(tlv->_value));
	*_value = (int)strtol(tlv->_value, NULL, 16);
	return 0;
}

int tlv_box_get_long(tlv_box_t *box,int type,long *_value)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		return -1;
	}
	tlv = (tlv_t *)object._value;
	// *_value = (*(long *)(tlv->_value));
	*_value = (long)strtol(tlv->_value, NULL, 16);
	return 0;
}

int tlv_box_get_longlong(tlv_box_t *box,int type,long long *_value)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		return -1;
	}
	tlv = (tlv_t *)object._value;
	// *_value = (*(long long *)(tlv->_value));
	// TODO: ??????
	*_value = (long long)strtol(tlv->_value, NULL, 16);
	return 0;
}

int tlv_box_get_float(tlv_box_t *box,int type,float *_value)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		return -1;
	}
	tlv = (tlv_t *)object._value;
	// *_value = (*(float *)(tlv->_value));
	//*_value = atof(tlv->_value);
	*_value = strtof(tlv->_value, NULL);
	return 0;
}

int tlv_box_get_double(tlv_box_t *box,int type,double *_value)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		return -1;
	}
	tlv = (tlv_t *)object._value;
	// *_value = (*(double *)(tlv->_value));
	*_value = strtod(tlv->_value, NULL);
	return 0;
}

/**
 * length[io]: in: size of _value, > 0; out: length got
 */
int tlv_box_get_string(tlv_box_t *box,int type,char *_value,int* length)
{
	// int ret = tlv_box_get_bytes(box,type,_value,length);
	// printf("tlv_box_get_string: %d, %s\n", *length, _value);
	// return ret;
	return tlv_box_get_bytes(box,type,_value,length);
}

/**
 ** length[io]: in: size of _value, > 0; out: length got
 */
int tlv_box_get_bytes(tlv_box_t *box,int type,unsigned char *_value,int* length)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		// printf("tlv_box_get_bytes: failed @t=%d:%02x\n", type, type);
		return -1;
	}
	tlv = (tlv_t *)object._value;
	if (*length < tlv->length) {
		// printf("tlv_box_get_bytes: failed @ *length=%d < tlv->length=%d @t=%d:%02x\n",
		// 	*length, tlv->length, type, type);
		return -1;
	}
	memset(_value,0,*length);
	*length = tlv->length;
	memcpy(_value,tlv->_value,tlv->length);
	return 0;
}

int tlv_box_get_bytes_ptr(tlv_box_t *box,int type,unsigned char **_value,int* length)
{
	value_t object;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&object) != 0) {
		return -1;
	}
	tlv = (tlv_t *)object._value;
	*_value  = tlv->_value;
	*length = tlv->length;
	return 0;
}

int tlv_box_get_object(tlv_box_t *box,int type,tlv_box_t **object)
{
	value_t _value;
	tlv_t *tlv;
	if (key_list_get(box->m_list,type,&_value) != 0) {
		return -1;
	}
	tlv = (tlv_t *)_value._value;
	*object = (tlv_box_t *)tlv_box_parse(tlv->_value,tlv->length);
	return 0;
}
