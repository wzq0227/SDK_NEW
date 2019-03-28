#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "qrcode_tools.h"
#include "quicklz.h"
#include "tlv_box.h"


#if defined(WIN32) && !defined(__cplusplus)

#define inline __inline

#endif
#if (defined __ANDROID__) || (defined ANDROID)
#include "goscam_log.h" // #define Log __android_log_print
#elif WIN32
#define Log(...) fprintf(stderr,  __VA_ARGS__) // with log on linux/win/mac/ios
#else
#define Log(x...) printf(x)
#endif

#define N 32
#define M (1 << (N - 1))
void PRINT_BIN_TEXT(unsigned c){
  int i;
  for (i=0;i<N ;i++) {
     if(i%8==0)printf(" ");
     putchar(((c&M)==0)?'0':'1');
     c<<=1;
  }
  printf("\n");
}

CGetQrCode* goscam_qrcode_create(int action){
  CGetQrCode *qrc = (CGetQrCode*) malloc(sizeof(CGetQrCode));
  memset(qrc, '\0', sizeof(CGetQrCode));
  qrc->nAction = action;
  qrc->nVersion = QRC_PROTOCOL_VER;
  // Log("nAction=%d\n", qrc->nAction);
  return qrc;
}

// 2016-07-21: ���ɳ�����ά��
/*
�ɰ�
00 3 01 0 : QRC_ACTION_FACTORY
02 3 08 fffffdfd : old capabilities
01 8 14 0011223344556677111A
*/
/*
�°�
qrtext:(size=52), 003013028103841101110110210018140011223344556677111A
00 3 01 3 : QRC_ACTION_FACTORY_V1
02 8 10 3841101110110210 : T_SDK_DEVICE_ABILITY_INFO1 (3 + 13*char)
01 8 14 0011223344556677111A : szDevID
*/
void goscam_qrcode_gettext_v1(const char *szDevID, T_SDK_DEVICE_ABILITY_INFO1 *info, char **qrtext, int *qrtext_len){
  // char extra[1024];
  char capabilities[17];// 3+13 + 1=16;// 3+(3*8)+13*1+1=45;
  tlv_box_t *box = NULL;
  char* buffer = NULL;
  int length = 0;

  box = tlv_box_create();
  *qrtext_len = -1;
  if(szDevID == NULL)
    return;
  if(*qrtext != NULL) {
    printf("argument qrtext must be NULL!!!\n");
    return;
  }
  if(strlen(szDevID) > 0) {
    tlv_box_put_string(box, QRC_TAG_IPC_ID, szDevID);
  }
  memset(capabilities, '\0', 17);

#if (defined _WINDOWS) || (defined WIN32)
  sprintf_s(capabilities, 17, "%03x%x%x%x%x%x%x%x%x%x%x%x%x%x",
    info->c_device_type,
    info->c_encrypted_ic_flag, info->c_pir_flag, info->c_ptz_flag, info->c_mic_flag,
    info->c_speaker_flag, info->c_sd_flag, info->c_temperature_flag, info->c_timezone_flag,
    info->c_night_vison_flag, info->ethernet_flag, info->c_smart_connect_flag, info->c_motion_detection_flag,
    info->c_record_duration_flag);
#else
  sprintf(capabilities, "%03x%x%x%x%x%x%x%x%x%x%x%x%x%x",
    info->c_device_type,
    info->c_encrypted_ic_flag, info->c_pir_flag, info->c_ptz_flag, info->c_mic_flag,
    info->c_speaker_flag, info->c_sd_flag, info->c_temperature_flag, info->c_timezone_flag,
    info->c_night_vison_flag, info->ethernet_flag, info->c_smart_connect_flag, info->c_motion_detection_flag,
    info->c_record_duration_flag);
#endif
  // printf("capabilities(%d)=%s\n", strlen(capabilities), capabilities);
  tlv_box_put_string(box, QRC_TAG_IPC_ABI, capabilities);
  tlv_box_put_int(box, QRC_TAG_ACTION, QRC_ACTION_FACTORY_V1);

  if (tlv_box_serialize(box) == 0){
    length = tlv_box_get_size(box);
    buffer = tlv_box_get_buffer(box);
    if(length > 0 && buffer != NULL){
      *qrtext_len = length;
      *qrtext = (char*) malloc(*qrtext_len+1);
      memset(*qrtext, '\0', *qrtext_len+1);
      memcpy(*qrtext, buffer, length);
    }
  }
  buffer = NULL;
  tlv_box_destroy(box);
  Log("qrtext:(size=%d), %s\n", length, *qrtext);
  Log("########### build QRText V1 end ##########\n");
}


void goscam_qrcode_gettext_v2(const char *szDevID, T_SDK_DEVICE_ABILITY_INFO2 *info, char **qrtext, int *qrtext_len){
	// char extra[1024];
	char capabilities[QRC_CAP_LEN_V2];// 3+13 + 1=16;// 3+(3*8)+13*1+1=45;
	tlv_box_t *box = NULL;
	char* buffer = NULL;
	int length = 0;

	box = tlv_box_create();
	*qrtext_len = -1;
	if(szDevID == NULL)
		return;
	if(*qrtext != NULL) {
		printf("argument qrtext must be NULL!!!\n");
		return;
	}
	if(strlen(szDevID) > 0) {
		tlv_box_put_string(box, QRC_TAG_IPC_ID, szDevID);
	}
	memset(capabilities, '\0', QRC_CAP_LEN_V2);

#if (defined _WINDOWS) || (defined WIN32)
	sprintf_s(capabilities, QRC_CAP_LEN_V2, "%03x%x%x%x%x%x%x%x%x%x%x%03x%x%x%x%x",
		info->c_device_type,
		info->c_encrypted_ic_flag, info->c_pir_flag, info->c_ptz_flag, info->c_mic_flag,
		info->c_speaker_flag, info->c_sd_flag, info->c_temperature_flag, info->c_timezone_flag,
		info->c_night_vison_flag, info->ethernet_flag, info->c_smart_connect_flag, info->c_motion_detection_flag,
		info->c_record_duration_flag, info->c_light_flag, info->c_voice_detection_flag);
#else
	sprintf(capabilities, "%03x%x%x%x%x%x%x%x%x%x%x%03x%x%x%x%x",
		info->c_device_type,
		info->c_encrypted_ic_flag, info->c_pir_flag, info->c_ptz_flag, info->c_mic_flag,
		info->c_speaker_flag, info->c_sd_flag, info->c_temperature_flag, info->c_timezone_flag,
		info->c_night_vison_flag, info->ethernet_flag, info->c_smart_connect_flag, info->c_motion_detection_flag,
		info->c_record_duration_flag, info->c_light_flag, info->c_voice_detection_flag);
#endif
	// printf("capabilities(%d)=%s\n", strlen(capabilities), capabilities);
	tlv_box_put_string(box, QRC_TAG_IPC_ABI, capabilities);
	tlv_box_put_int(box, QRC_TAG_ACTION, QRC_ACTION_FACTORY_V2);

	if (tlv_box_serialize(box) == 0){
		length = tlv_box_get_size(box);
		buffer = tlv_box_get_buffer(box);
		if(length > 0 && buffer != NULL){
			*qrtext_len = length;
			*qrtext = (char*) malloc(*qrtext_len+1);
			memset(*qrtext, '\0', *qrtext_len+1);
			memcpy(*qrtext, buffer, length);
		}
	}
	buffer = NULL;
	tlv_box_destroy(box);
	Log("qrtext:(size=%d), %s\n", length, *qrtext);
	Log("########### build QRText V1 end ##########\n");
}


// 2016-07-21:
// qrtext:(size=55), 00301105809goscam12304805admin018140011223344556677111A
void goscam_qrcode_sharing_v1(const char *szDevID, const char *szStreamUser, const char *szSteamPwd, char **qrtext, int *qrtext_len){
  tlv_box_t *box = NULL;
  char* buffer = NULL;
  int length = 0;

  box = tlv_box_create();
  *qrtext_len = -1;
  if(szDevID == NULL || szStreamUser == NULL || szSteamPwd == NULL){
    printf("arguments szDevID && szStreamUser && szSteamPwd cannot be NULL!!!\n");
    return;
  }
  if(*qrtext != NULL) {
    printf("argument *qrtext must be NULL!!!\n");
    return;
  }
  if(strlen(szDevID) > 0) {
    tlv_box_put_string(box, QRC_TAG_IPC_ID, szDevID);
  }
  if(strlen(szStreamUser) > 0) {
    tlv_box_put_string(box, QRC_TAG_STREAM_USR, szStreamUser);
  }
  if(strlen(szSteamPwd) > 0) {
    tlv_box_put_string(box, QRC_TAG_STREAM_PWD, szSteamPwd);
  }
  // ACTION ������������
  tlv_box_put_int(box, QRC_TAG_ACTION, QRC_ACTION_IPC_SHARING);

  if (tlv_box_serialize(box) == 0){
    length = tlv_box_get_size(box);
    buffer = tlv_box_get_buffer(box);
    if(length > 0 && buffer != NULL){
      *qrtext_len = length;
      *qrtext = (char*) malloc(*qrtext_len+1);
      memset(*qrtext, '\0', *qrtext_len+1);
      memcpy(*qrtext, buffer, length);
    }
  }
  buffer = NULL;
  tlv_box_destroy(box);
  Log("qrtext:(size=%d), %s\n", length, *qrtext);
  Log("########### build QRText V1 end ##########\n");
}

// 2016-07-21: ��������IPC�������õĶ�ά��
// $ goscam-qrtool -a 2 -s HiWiFi-test -t goscam518
// qrtext:(size=36), 00301207809goscam5180680bHiWiFi-test
// $ goscam-qrtool -a 2 -i 0011223344556677111A -s HiWiFi-test -t goscam518
// qrtext:(size=61), 00301207809goscam5180680bHiWiFi-test018140011223344556677111A
void goscam_qrcode_smartconfig_v1(const char *szDevID, const char *szWiFiSSID, const char *szWiFiPwd, char **qrtext, int *qrtext_len){
  tlv_box_t *box = NULL;
  char* buffer = NULL;
  int length = 0;

  box = tlv_box_create();
  *qrtext_len = -1;
  if(szDevID == NULL || szWiFiSSID == NULL || szWiFiPwd == NULL){
    printf("arguments szDevID && szWiFiSSID && szWiFiPwd cannot be NULL!!!\n");
    return;
  }
  if(*qrtext != NULL) {
    printf("argument *qrtext must be NULL!!!\n");
    return;
  }
  if(strlen(szDevID) > 0) {
    tlv_box_put_string(box, QRC_TAG_IPC_ID, szDevID);
  }
  if(strlen(szWiFiSSID) > 0) {
    tlv_box_put_string(box, QRC_TAG_SMART_SSID, szWiFiSSID);
  }
  if(strlen(szWiFiPwd) > 0) {
    tlv_box_put_string(box, QRC_TAG_SMART_PWD, szWiFiPwd);
  }
  // ACTION ������������
  tlv_box_put_int(box, QRC_TAG_ACTION, QRC_ACTION_SMART_CONFIG);

  if (tlv_box_serialize(box) == 0){
    length = tlv_box_get_size(box);
    buffer = tlv_box_get_buffer(box);
    if(length > 0 && buffer != NULL){
      *qrtext_len = length;
      *qrtext = (char*) malloc(*qrtext_len+1);
      memset(*qrtext, '\0', *qrtext_len+1);
      memcpy(*qrtext, buffer, length);
    }
  }
  buffer = NULL;
  tlv_box_destroy(box);
  Log("qrtext:(size=%d), %s\n", length, *qrtext);
  Log("########### build QRText V1 end ##########\n");
}

char* goscam_qrcode_get_tagname(int tag) {
  switch (tag) {
    case QRC_TAG_ACTION:
      return "QRC_TAG_ACTION";
    case QRC_TAG_IPC_ABI:
      return "QRC_TAG_IPC_ABI";
    case QRC_TAG_IPC_ID:
      return "QRC_TAG_IPC_ID";
    case QRC_TAG_IPC_MAC:
      return "QRC_TAG_IPC_MAC";
    case QRC_TAG_STREAM_USR:
      return "QRC_TAG_STREAM_USR";
    case QRC_TAG_STREAM_PWD:
      return "QRC_TAG_STREAM_PWD";
    case QRC_TAG_SMART_SSID:
      return "QRC_TAG_SMART_SSID";
    case QRC_TAG_SMART_PWD:
      return "QRC_TAG_SMART_PWD";
    case QRC_TAG_RESERVE:
      return "QRC_TAG_RESERVE";
    case QRC_TAG_ENCRYPTMTH:
      return "QRC_TAG_ENCRYPTMTH";
    case QRC_TAG_VERSION:
      return "QRC_TAG_VERSION";
    case QRC_TAG_IPC_EXTRA:
      return "QRC_TAG_IPC_EXTRA";
    default:
      return "unkown";
  }
}

char* goscam_qrcode_get_tagptr(CGetQrCode *qrc, QRC_TAG tag, int *str_length) {
  *str_length = QRC_DEF_STR_LEN - 1;
  switch (tag) {
    case QRC_TAG_IPC_ID:
      return qrc->szDevID;
    case QRC_TAG_IPC_MAC:
      return qrc->szDevMAC;
    case QRC_TAG_STREAM_USR:
      return qrc->szUser;
    case QRC_TAG_STREAM_PWD:
      return qrc->szPwd;
    case QRC_TAG_SMART_SSID:
      return qrc->szWifiSSID;
    case QRC_TAG_SMART_PWD:
      return qrc->szWifiPwd;
    case QRC_TAG_RESERVE:
      *str_length = QRC_RESERVE_LEN - 1;
      return qrc->reserve;
    default:
      return NULL;
  }
}

/**
 * tlv_box(string_x)=>qrc[tag]<br/>
 * box[in]: where the string from<br/>
 * qrc[in & out]: set string from qrc, within which tag<br/>
 * tag[in]: the tag for the string field of qrc<br/>
 * length_exp[in & out]:  >= 0<br/>
 * return the length of the value string from box to qrc<br/>
 */
static int tlv_box_get_qrc_string_exp(tlv_box_t *box, CGetQrCode *qrc, QRC_TAG tag, int length_exp){
  unsigned char *_value = NULL;
  unsigned char *tag_name = NULL;
  int str_length = 0;
  int ret = 0;
  if(length_exp <= 0){
    str_length = QRC_DEF_STR_LEN-1;// default length of the string field is 32. exp: szDevID, szDevMAC...
  } else {
    str_length = length_exp;
  }
  tag_name = goscam_qrcode_get_tagname(tag);
  _value = goscam_qrcode_get_tagptr(qrc, tag, &str_length);
  if(_value != NULL) {
    ret = tlv_box_get_string(box, tag, _value, &str_length);
  }
  if(ret != 0) {
      // Log("tlv_box_get_string(%s) failed !\n", tag_name);
  } else {
    ret = str_length;
  }
  // Log("%s(%d): %d, %s\n", tag_name, tag, str_length, _value);
  _value = NULL;
  return ret;
}

static int tlv_box_get_qrc_string(tlv_box_t *box, CGetQrCode *qrc, QRC_TAG tag){
  return tlv_box_get_qrc_string_exp(box, qrc, tag, QRC_DEF_STR_LEN);
}

static CGetQrCode *tlv_box_to_gqrc(tlv_box_t *box)
{
 
  CGetQrCode *qrc = NULL;
  unsigned char extra[1024];
  int action = QRC_ACTION_FACTORY;
  int str_length = 0;
  int ret = 0;
  char szDevType[3];
  char cWifiMod;
  ret = tlv_box_get_int(box, QRC_TAG_ACTION, &action);
  if (ret != 0) {
    Log("tlv_box_get_int(QRC_TAG_ACTION) failed !\n");
  }

  qrc = goscam_qrcode_create(action);

  ret = tlv_box_get_short(box, QRC_TAG_ENCRYPTMTH, &qrc->nEncryptMth);
  // if(ret != 0) {
  //   Log("tlv_box_get_short(QRC_TAG_ENCRYPTMTH) failed !\n");
  // }

  ret = tlv_box_get_short(box, QRC_TAG_VERSION, &qrc->nVersion);
  // if(ret != 0) {
  //   Log("tlv_box_get_short(QRC_TAG_VERSION) failed !\n");
  // }

  Log("tlv_box_to_gqrc: action=%d, enc_mth=%d, ver=%d\n",
    qrc->nAction, qrc->nEncryptMth, qrc->nVersion);

  if(action != QRC_ACTION_FACTORY_V1){
    ret = tlv_box_get_int(box, QRC_TAG_IPC_ABI, &qrc->nDevCap);
  }
  // if(ret != 0) {
  //   Log("tlv_box_get_int(QRC_TAG_IPC_ABI) failed !\n");
  // }

  str_length = tlv_box_get_qrc_string(box, qrc, QRC_TAG_IPC_ID);
  if(str_length > 0)
    Log("qrc->szDevID: %d, %s\n", str_length, qrc->szDevID);

  str_length = tlv_box_get_qrc_string(box, qrc, QRC_TAG_IPC_MAC);
  if(str_length > 0)
    Log("qrc->szDevMAC: %d, %s\n", str_length, qrc->szDevMAC);

  str_length = tlv_box_get_qrc_string(box, qrc, QRC_TAG_STREAM_USR);
  if(str_length > 0)
    Log("qrc->szUser: %d, %s\n", str_length, qrc->szUser);

  str_length = tlv_box_get_qrc_string(box, qrc, QRC_TAG_STREAM_PWD);
  if(str_length > 0)
    Log("qrc->szPwd: %d, %s\n", str_length, qrc->szPwd);

  str_length = tlv_box_get_qrc_string(box, qrc, QRC_TAG_SMART_SSID);
  if(str_length > 0)
    Log("qrc->szWifiSSID: %d, %s\n", str_length, qrc->szWifiSSID);

  str_length = tlv_box_get_qrc_string(box, qrc, QRC_TAG_SMART_PWD);
  if(str_length > 0)
    Log("qrc->szWifiPwd: %d, %s\n", str_length, qrc->szWifiPwd);

  str_length = tlv_box_get_qrc_string(box, qrc, QRC_TAG_RESERVE);
  if(str_length > 0)
    Log("qrc->szWifiPwd: %d, %s\n", str_length, qrc->szWifiPwd);

  // if(qrc->nAction == QRC_ACTION_FACTORY_V1) {
  //   memset(extra, '\0', 1024);
  //   ret = tlv_box_get_string(box, QRC_TAG_IPC_EXTRA, extra, &str_length);
  //   if(str_length >= 4){
  //     // �Ժ��ڴ���չ����������, �̶���ʽ:
  //     // AAAB...
  //     // AAA: �豸����, 900=����; 901=���Ӱ�; 100=����; 101=����
  //     // B: ֧��Smart��WiFiģ��: 0��֧��; 1=bilian7601; 2=rtl8188;
  //     Log("extra: %d, %s\n", str_length, qrc->szWifiPwd);
  //     memcpy(szDevType, extra, 3);
  //     qrc->nDevType = strtol(szDevType, NULL, 10);
  //     qrc->cWifiMod = extra[3];
  //     Log("qrc->nDevType=%d, qrc->cWifiMod=%c\n", qrc->nDevType, qrc->cWifiMod);
  //   }
  // }
  Log("###### tlv_box_to_gqrc end ######\n");
  return qrc;
}

static tlv_box_t *gqrc_to_tlv_box(CGetQrCode *qrc){
  char extra[1024];
  tlv_box_t *box = tlv_box_create();
  if(strlen(qrc->szDevID) > 0) {
    tlv_box_put_string(box, QRC_TAG_IPC_ID, qrc->szDevID);
  }
  if(strlen(qrc->szDevMAC) > 0) {
    tlv_box_put_string(box, QRC_TAG_IPC_MAC, qrc->szDevMAC);
  }
  if(strlen(qrc->szUser) > 0) {
    tlv_box_put_string(box, QRC_TAG_STREAM_USR, qrc->szUser);
  }
  if(strlen(qrc->szPwd) > 0) {
    tlv_box_put_string(box, QRC_TAG_STREAM_PWD, qrc->szPwd);
  }
  if(strlen(qrc->szWifiSSID) > 0) {
    tlv_box_put_string(box, QRC_TAG_SMART_SSID, qrc->szWifiSSID);
  }
  if(strlen(qrc->szWifiPwd) > 0) {
    tlv_box_put_string(box, QRC_TAG_SMART_PWD, qrc->szWifiPwd);
  }
  if(strlen(qrc->reserve) > 0) {
    tlv_box_put_string(box, QRC_TAG_RESERVE, qrc->reserve);
  }
  switch (qrc->nAction) {
    case QRC_ACTION_FACTORY:
      tlv_box_put_int(box, QRC_TAG_IPC_ABI, qrc->nDevCap);
      // tlv_box_put_string(box, QRC_TAG_IPC_ID, qrc->szDevID);
      // tlv_box_put_string(box, QRC_TAG_IPC_MAC, qrc->szDevMAC);
      break;
    case QRC_ACTION_IPC_SHARING:
      // tlv_box_put_string(box, QRC_TAG_IPC_ID, qrc->szDevID);
      // tlv_box_put_string(box, QRC_TAG_STREAM_USR, qrc->szUser);
      // tlv_box_put_string(box, QRC_TAG_STREAM_PWD, qrc->szPwd);
      break;
    case QRC_ACTION_SMART_CONFIG:
      // tlv_box_put_string(box, QRC_TAG_IPC_ID, qrc->szWifiSSID);
      // tlv_box_put_string(box, QRC_TAG_IPC_ID, qrc->szWifiPwd);
      break;
  //   case QRC_ACTION_FACTORY_V1:
  //     tlv_box_put_int(box, QRC_TAG_IPC_ABI, qrc->nDevCap);
  //     if(qrc->nDevType != 0) {
  //       // �Ժ��ڴ���չ����������, �̶���ʽ:
  //       // AAAB...
  //       // AAA: �豸����, 900=����; 901=���Ӱ�; 100=����; 101=����
  //       // B: ֧��Smart��WiFiģ��: 0��֧��; 1=bilian7601; 2=rtl8188;
  //       memset(extra, '\0', 1024);
  // #if (defined _WINDOWS) || (defined WIN32)
  //       sprintf_s(extra, 1024, "%03d%c", qrc->nDevType, qrc->cWifiMod);
  // #else
  //       sprintf(extra, "%03d%c", qrc->nDevType, qrc->cWifiMod);
  // #endif
  //       tlv_box_put_string(box, QRC_TAG_IPC_EXTRA, extra);
  //     }
  //     break;
    default:
      break;
  }
  // tlv_box_put_short(box, QRC_TAG_ENCRYPTMTH, qrc->nEncryptMth);
  // tlv_box_put_short(box, QRC_TAG_VERSION, qrc->nVersion);
  tlv_box_put_int(box, QRC_TAG_ACTION, qrc->nAction);
  return box;
}

CGetQrCode* goscam_qrcode_recognize(const unsigned char *qrctext, int qrtext_len){
  CGetQrCode *qrc = NULL;
  tlv_box_t *box = NULL;
  // char *dst = (char *) malloc(src_len * 3 / 4);
  unsigned char dst[1024];
  char* temp = NULL;
  int dst_len = 0;
  int rawtext_len = 0;
  if(qrctext == NULL || qrtext_len == 0){
    Log("qrctext cannot be NULL\n");
  }
  else if(qrtext_len == 28
    && strncmp(qrctext+16, QRC_TUTK_POSTFIX, strlen(QRC_TUTK_POSTFIX)) == 0){
    // 1122334455667788111A
    Log("###### recognisze UID ######\n");
    Log("qrctext:(size=%d), %s\n", qrtext_len, qrctext);
    qrc = (CGetQrCode*) malloc(sizeof(CGetQrCode));
    memset(qrc, '\0', sizeof(CGetQrCode));
    qrc->nAction = QRC_ACTION_IPC_SHARING;
    qrc->nDevCap = 0;
    // the OLD protocol should support the SmartWiFi
    qrc->nDevCap |= QRC_BIT_SMART_WIFI;
    qrc->cIsRawID = 1;
    memcpy(qrc->szDevID, qrctext, qrtext_len);
    memcpy(qrc->szUser, QRC_DEFAULT_USR, strlen(QRC_DEFAULT_USR));
    memcpy(qrc->szPwd, QRC_DEFAULT_PWD, strlen(QRC_DEFAULT_PWD));
    // result = (jlong) qrc;
  } else if(qrtext_len > QRC_GOSCAM_PREFIX_LEN &&
    strncmp(qrctext, QRC_GOSCAM_PREFIX, strlen(QRC_GOSCAM_PREFIX)) == 0){
    // goscam@01:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    Log("###### recognisze Goscam QRC ######\n");
    Log("qrctext:(size=%d), %s\n", qrtext_len, qrctext);
    Base64_decode((unsigned char *)qrctext+QRC_GOSCAM_PREFIX_LEN, qrtext_len-QRC_GOSCAM_PREFIX_LEN, (unsigned char*)dst, &dst_len);
    // Log("Base64Dec: text=%s, len=%d\n", dst, dst_len);
    Log("to_uncompress:(size=%d) \n", dst_len);
    PRINT_HEX_TEXT(dst, dst_len);
    rawtext_len = goscam_text_uncompress(dst, (unsigned int)dst_len, (char**)&qrc, NULL);
    Log("uncompressed:(size=%d) \n", rawtext_len);
    if(rawtext_len == sizeof(CGetQrCode)) {
      // result = (jlong) qrc;
      if(qrc != NULL) {
        // the OLD protocol should support the SmartWiFi
        qrc->nDevCap |= QRC_BIT_SMART_WIFI;
      }
    } else {
      Log("error qrtext: rawtext_len=%d, sizeof(CGetQrCode)=%d\n",rawtext_len, sizeof(CGetQrCode));
      free(qrc);
    }
  } else if(qrtext_len > QRC_GOSCAM_PREFIX_LEN_V1
    && strncmp(qrctext, QRC_GOSCAM_PREFIX_V1, strlen(QRC_GOSCAM_PREFIX_V1)) == 0) {
    // QRC://G.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx, ???????
    Log("###### recognisze Goscam QRC V1 ######\n");
    Log("qrctext:(size=%d), %s\n", qrtext_len, qrctext);
    Base64_decode((unsigned char *)qrctext+QRC_GOSCAM_PREFIX_LEN_V1,
      qrtext_len-QRC_GOSCAM_PREFIX_LEN_V1, (unsigned char*)dst, &dst_len);
    // Log("Base64Dec: text=%s, len=%d\n", dst, dst_len);
    // Log("to_uncompress:(size=%d) \n", dst_len);
    // PRINT_HEX_TEXT(dst, dst_len);
    // rawtext_len = goscam_text_uncompress(dst, (unsigned int)dst_len, &temp, NULL);
    // Log("uncompressed:(size=%d) \n", rawtext_len);
    if(dst_len <= 0) {
      return NULL;
    }
    box = tlv_box_parse(dst, dst_len);
    if(box == NULL)
      return NULL;
    qrc = tlv_box_to_gqrc(box);
    tlv_box_destroy(box);
    // if(rawtext_len == sizeof(CGetQrCode)) {
    //   // result = (jlong) qrc;
    // } else {
    //   Log("error qrtext: rawtext_len=%d, sizeof(CGetQrCode)=%d\n",rawtext_len, sizeof(CGetQrCode));
    //   free(qrc);
    // }
  } else if(qrtext_len > QRC_GOSCAM_PREFIX_LEN_RAW
    && strncmp(qrctext, QRC_GOSCAM_PREFIX_RAW, strlen(QRC_GOSCAM_PREFIX_RAW)) == 0) {
    //  QRC://R.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    box = tlv_box_parse((unsigned char *)qrctext+QRC_GOSCAM_PREFIX_LEN_RAW, qrtext_len-QRC_GOSCAM_PREFIX_LEN_RAW);
    if(box == NULL)
      return NULL;
    qrc = tlv_box_to_gqrc(box);
    tlv_box_destroy(box);
  } else {
    Log("wrong qrtext\n");
  }
  goscam_qrcode_print(qrc);
  Log("########### recognisze end ##########\n");
  return qrc;
}

void goscam_qrcode_recognize_compat(const unsigned char *qrctext, int qrtext_len, E_QRC_VERSION *version, char **dest)
{
  CGQRCodeCompatV1 *qrc_v1 = NULL;
  tlv_box_t *box = NULL;
  CGetQrCode *qrc = NULL;
  char capabilities[64];// 3+13=16;// 3+(3*8)+13*1+1=45;
  char szDevType[3+1];
  char szSmartConn[3+1];
  int str_length = 0;
  int cap_offset = 0;
  int ret = -1;
  *version = E_QRC_VERSION_UNKNOWN;
  if(qrtext_len > QRC_GOSCAM_PREFIX_LEN_NONE
    && strncmp(qrctext, QRC_GOSCAM_PREFIX_NONE, strlen(QRC_GOSCAM_PREFIX_NONE)) == 0)
  {
    Log("###### recognisze Goscam QRC ######\n");
    Log("qrctext:(size=%d), %s\n", qrtext_len, qrctext);
    // 00301 105809goscam12304805admin018140011223344556677111A
    box = tlv_box_parse(qrctext, qrtext_len);
    if(box == NULL)
      return;
    qrc_v1 = (CGQRCodeCompatV1*)malloc(sizeof(CGQRCodeCompatV1));
    qrc_v1->have_abi = 0;
    qrc = tlv_box_to_gqrc(box);
    memcpy(&qrc_v1->qrc, qrc, sizeof(CGetQrCode));
    Log("ACT: %c, %c\n", qrctext[QRC_GOSCAM_PREFIX_LEN_NONE], QRC_ACTION_FACTORY_V1+'0');
    if(qrctext[QRC_GOSCAM_PREFIX_LEN_NONE] == (QRC_ACTION_FACTORY_V1 + '0'))
	{
      *version = E_QRC_VERSION_V1;
      Log("00301: *version = E_QRC_VERSION_V1=%d\n", E_QRC_VERSION_V1);
      qrc_v1->have_abi = 1;
      // int tlv_box_get_string(tlv_box_t *box,int type,char *_value,int* length)
      str_length = 16;
      memset(capabilities, '\0', 64/*17*/);
	  memset(szDevType, '\0', 3+1);
      ret = tlv_box_get_string(box, QRC_TAG_IPC_ABI, capabilities, &str_length);
      // printf("capabilities: ret=%d, %d, %s, %d\n", ret, str_length, capabilities, strlen(capabilities));
      if(str_length > 0 && str_length < 18){
        // qrc_v1->info = (T_SDK_DEVICE_ABILITY_INFO1*) malloc(sizeof(T_SDK_DEVICE_ABILITY_INFO1));
        memcpy(szDevType, capabilities, 3);
        cap_offset = 3;
        qrc_v1->info.c_device_type = strtol(szDevType, NULL, 16);
        // qrc_v1->info.un_resolution_0_flag= GEN_VIDEO_RESOLUTION(1280, 720);
        // qrc_v1->info.un_resolution_1_flag= GEN_VIDEO_RESOLUTION(720, 480);
        // qrc_v1->info.un_resolution_2_flag= GEN_VIDEO_RESOLUTION(640, 480);
        qrc_v1->info.c_encrypted_ic_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_pir_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_ptz_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_mic_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_speaker_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_sd_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_temperature_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_timezone_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_night_vison_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.ethernet_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_smart_connect_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_motion_detection_flag = capabilities[cap_offset++] - '0';
        qrc_v1->info.c_record_duration_flag = capabilities[cap_offset++] - '0';

      }
    } 
	else if(qrctext[QRC_GOSCAM_PREFIX_LEN_NONE] == (QRC_ACTION_FACTORY_V2 + '0'))
	{
		*version = E_QRC_VERSION_V2;
		qrc_v1->have_abi = 1;
		str_length = 20;

		memset(capabilities, '\0', 64/*17*/);

		memset(szDevType, '\0', 3+1);

		memset(szSmartConn, '\0', 3+1);

		ret = tlv_box_get_string(box, QRC_TAG_IPC_ABI, capabilities, &str_length);

		if(str_length > 0 && str_length < QRC_CAP_LEN_V2)
		{
			memcpy(szDevType, capabilities, 3);
			cap_offset = 3;
			qrc_v1->info2.c_device_type = strtol(szDevType, NULL, 16);
			qrc_v1->info2.c_encrypted_ic_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_pir_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_ptz_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_mic_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_speaker_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_sd_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_temperature_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_timezone_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_night_vison_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.ethernet_flag = capabilities[cap_offset++] - '0';

			memcpy(szSmartConn, capabilities+cap_offset, 3);
			qrc_v1->info2.c_smart_connect_flag = strtol(szSmartConn, NULL, 16);
			cap_offset += 3;
			//qrc_v1->info2.c_smart_connect_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_motion_detection_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_record_duration_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_light_flag = capabilities[cap_offset++] - '0';
			qrc_v1->info2.c_voice_detection_flag = capabilities[cap_offset++] - '0';
		}
	}
	else 
	{
        *version = E_QRC_VERSION_OLD;
        Log("00301: *version = E_QRC_VERSION_OLD=%d\n", E_QRC_VERSION_OLD);
    }
    tlv_box_destroy(box);
    // goscam_qrcode_print(&qrc_v1->qrc);
  }
  else 
  { // ! 00301xxxx
		Log("### ! 00301xxxx ###");
		qrc = goscam_qrcode_recognize(qrctext, qrtext_len);
		if(qrc != NULL)
		{
		  qrc_v1 = (CGQRCodeCompatV1*)malloc(sizeof(CGQRCodeCompatV1));
		  qrc_v1->have_abi = 0;
		  memcpy(&qrc_v1->qrc, qrc, sizeof(CGetQrCode));
		  *version = E_QRC_VERSION_OLD;
		  Log("oth: *version = E_QRC_VERSION_OLD=%d\n", E_QRC_VERSION_OLD);
		  // goscam_qrcode_print(&qrc_v1->qrc);
	   }
  }
  goscam_qrcode_destroy(qrc);
  if(qrc_v1 != NULL) 
  {
	Log("CGQRCodeCompatV1, memcpy, from qrc_v1\n");
	*dest = (char*) malloc(sizeof(CGQRCodeCompatV1));
	memset(*dest, '0', sizeof(CGQRCodeCompatV1));
	memcpy(*dest, qrc_v1, sizeof(CGQRCodeCompatV1));
	free(qrc_v1);
  }
  Log("### goscam_qrcode_recognize_compat END ###\n");

}

void goscam_qrcode_destroy(CGetQrCode *qrc){
  if(qrc != NULL)
    free(qrc);
}

/**
 * generate the qrtext<br/>
 * @Deprecated <br/>
 */
static void goscam_qrcode_getqrtext_deprecated(CGetQrCode *qrc, char **qrtext, int *qrtext_len){
  char dst[1024];
  char *compressed = NULL;
  int length = 0;
  *qrtext_len = -1;
  if(*qrtext != NULL){
    return;
  }
  if(qrc == NULL) {
    Log("qrc instance NULL\n");
    return;
  }
  Log("###### build QRText goscam@1:xxxx begin ######\n");
  goscam_qrcode_print(qrc);
	length = goscam_text_compress((char*)qrc, sizeof(CGetQrCode), &compressed, NULL);
  if(length <= 0) {
    Log("compressing error=%d\n",length);
    return;
  }
  Log("compressed:(size=%d)\n", length);
  PRINT_HEX_TEXT(compressed, length);
  // snprintf(dst, QRC_GOSCAM_PREFIX_LEN, "%s%d:", QRC_GOSCAM_PREFIX,QRC_DEFAULT_ENCRYPT_METHOD);
#if (defined _WINDOWS) || (defined WIN32)
  sprintf_s(dst, sizeof(dst), "%s%1x:", QRC_GOSCAM_PREFIX, QRC_DEFAULT_ENCRYPT_METHOD);
#elif (defined ANDROID) || (defined __ANDROID__)
  sprintf(dst, "%s%1x:", QRC_GOSCAM_PREFIX, QRC_DEFAULT_ENCRYPT_METHOD);
#else
  sprintf(dst, "%s%1x:", QRC_GOSCAM_PREFIX, QRC_DEFAULT_ENCRYPT_METHOD);
#endif
  // dst =(char*) malloc(length *4 / 3);
  // void Base64_encode(unsigned char *src, int src_len, char *dst, int *dst_len);
  Base64_encode(compressed, length, dst+QRC_GOSCAM_PREFIX_LEN, &length);
  free(compressed);
  // Log("qrtext:(size=%d), %s\n", length, dst);
  if(length > 0){
    length += QRC_GOSCAM_PREFIX_LEN + 1;
    *qrtext = (char*) malloc(length);
    memset(*qrtext, '\0', length);
    memcpy(*qrtext, dst, length);
    Log("qrtext:(size=%d), %s\n", length, *qrtext);
  }
  *qrtext_len = length/* +1 */;
  Log("########### build QRText goscam@1:xxxx end ##########\n");
}

/**
 *
 */
static void goscam_qrcode_getqrtext_qrcr(CGetQrCode *qrc, char **qrtext, int *qrtext_len) {
  tlv_box_t *box;
  char* buffer = NULL;
  int length = 0;

  *qrtext = NULL;
  *qrtext_len = 0;

  if(*qrtext != NULL){
    return;
  }
  if(qrc == NULL) {
    Log("qrc instance NULL\n");
    return;
  }

  Log("###### build QRText QRC://R.xxxx begin ######\n");
  goscam_qrcode_print(qrc);
  box = gqrc_to_tlv_box(qrc);

  if (tlv_box_serialize(box) == 0){
    length = tlv_box_get_size(box);
    buffer = tlv_box_get_buffer(box);
    if(length > 0 && buffer != NULL){
      *qrtext_len = length + QRC_GOSCAM_PREFIX_LEN_RAW + 1;
      *qrtext = (char*) malloc(*qrtext_len);
      memset(*qrtext, '\0', *qrtext_len);
      memcpy(*qrtext, QRC_GOSCAM_PREFIX_RAW, QRC_GOSCAM_PREFIX_LEN_RAW);
      memcpy(*qrtext+QRC_GOSCAM_PREFIX_LEN_RAW, buffer, length);
    }
  }
  buffer = NULL;
  tlv_box_destroy(box);
  Log("qrtext:(size=%d), %s\n", length, *qrtext);
  Log("########### build QRText QRC://R.xxxx end ##########\n");
}

static void goscam_qrcode_getqrtext_raw(CGetQrCode *qrc, char **qrtext, int *qrtext_len) {
  tlv_box_t *box;
  char* buffer;
  int length = 0;

  *qrtext = NULL;
  *qrtext_len = 0;

  if(*qrtext != NULL){
    return;
  }
  if(qrc == NULL) {
    Log("qrc instance NULL\n");
    return;
  }

  Log("###### build QRText 00301xxxx begin ######\n");
  goscam_qrcode_print(qrc);
  box = gqrc_to_tlv_box(qrc);

  if (tlv_box_serialize(box) == 0){
    length = tlv_box_get_size(box);
    buffer = tlv_box_get_buffer(box);
    if(length > 0 && buffer != NULL){
      *qrtext_len = length;// + QRC_GOSCAM_PREFIX_LEN_RAW + 1;
      *qrtext = (char*) malloc(*qrtext_len+1);
      memset(*qrtext, '\0', *qrtext_len+1);
      // memcpy(*qrtext, QRC_GOSCAM_PREFIX_RAW, QRC_GOSCAM_PREFIX_LEN_RAW);
      memcpy(*qrtext/*+QRC_GOSCAM_PREFIX_LEN_RAW*/, buffer, length);
    }
  }
  buffer = NULL;
  tlv_box_destroy(box);
  Log("qrtext:(size=%d), %s\n", length, *qrtext);
  Log("########### build QRText 00301xxxx end ##########\n");
}
/**
 *
 */
static void goscam_qrcode_getqrtext_qrcg(CGetQrCode *qrc, char **qrtext, int *qrtext_len){
  tlv_box_t *box;
  char dst[1024];
  char* buffer = NULL;
  char *compressed = NULL;
  int length = 0;
  int buffer_len = 0;
  int ret = -1;
  *qrtext_len = -1;
  if(*qrtext != NULL){
    return;
  }
  if(qrc == NULL) {
    Log("qrc instance NULL\n");
    return;
  }

  Log("###### build QRText QRC://G.xxxx ######\n");
  goscam_qrcode_print(qrc);
  box = gqrc_to_tlv_box(qrc);

  ret = tlv_box_serialize(box);
  if (ret == 0){
    buffer_len = tlv_box_get_size(box);
    buffer = tlv_box_get_buffer(box);
  } else {
    Log("qrc tlv_box_serialize failed! \n");
    // return;
  }

  if(buffer_len > 0 && buffer != NULL) {
  //   length = goscam_text_compress(buffer, buffer_len, &compressed, NULL);
  //   Log("goscam_text_compress: length=%d, buffer_len=%d\n", length, buffer_len);
  // }
  // if(length > 0) {
    // Log("compressed:(size=%d)\n", length);
    // PRINT_HEX_TEXT(compressed, length);
    // snprintf(dst, QRC_GOSCAM_PREFIX_LEN, "%s%d:", QRC_GOSCAM_PREFIX,QRC_DEFAULT_ENCRYPT_METHOD);
    memset(dst, '\0', 1024);
    // sprintf(dst, "%s", QRC_GOSCAM_PREFIX_V1);
    memcpy(dst, QRC_GOSCAM_PREFIX_V1, QRC_GOSCAM_PREFIX_LEN_V1);
    // dst =(char*) malloc(length *4 / 3);
    // void Base64_encode(unsigned char *src, int src_len, char *dst, int *dst_len);
    // Base64_encode(compressed, length, dst+QRC_GOSCAM_PREFIX_LEN_V1, &length);
    // Log("dst=%s, %d, %s, %d\n", dst, buffer_len, buffer, QRC_GOSCAM_PREFIX_LEN_V1);
    Base64_encode(buffer, buffer_len, dst+QRC_GOSCAM_PREFIX_LEN_V1, &length);
  // } else {
  //   Log("compressing error=%d\n",length);
  }
  buffer = NULL;
  tlv_box_destroy(box);
  // if(compressed)
  //   free(compressed);
  // Log("qrtext:(size=%d), %s\n", length, dst);
  if(length > 0){
    length += QRC_GOSCAM_PREFIX_LEN_V1 + 1;
    *qrtext = (char*) malloc(length);
    memset(*qrtext, '\0', length);
    memcpy(*qrtext, dst, length);
    Log("qrtext:(size=%d), %s\n", length, *qrtext);
  }
  *qrtext_len = length/* +1 */;
  Log("########### build QRText QRC://G.xxxx end ##########\n");
}

void goscam_qrcode_getqrtext(CGetQrCode *qrc, char **qrtext, int *qrtext_len){
  goscam_qrcode_getqrtext_raw(qrc, qrtext, qrtext_len);
  // goscam_qrcode_getqrtext_deprecated(qrc, qrtext, qrtext_len);
  // goscam_qrcode_getqrtext_qrcr(qrc, qrtext, qrtext_len);
  // goscam_qrcode_getqrtext_qrcg(qrc, qrtext, qrtext_len);
}

void goscam_qrcode_getqrtext_pro(CGetQrCode *qrc, int gqrc_version, char **qrtext, int *qrtext_len){
  if(gqrc_version == -1) {//??��,?????,?????????
    // qrtext = goscam@1:xxxx
    goscam_qrcode_getqrtext_deprecated(qrc, qrtext, qrtext_len);
  } else if(gqrc_version == -2) {
    // qrtext = QRC://G.xxxx
    goscam_qrcode_getqrtext_qrcg(qrc, qrtext, qrtext_len);
  } else if(gqrc_version == -3) {
    // qrtext = QRC://R.xxxx
    goscam_qrcode_getqrtext_qrcr(qrc, qrtext, qrtext_len);
  } else if(gqrc_version < 0) {
    // qrtext = goscam@1:xxxx
    goscam_qrcode_getqrtext_deprecated(qrc, qrtext, qrtext_len);
  } else if(gqrc_version == 0) {//
    goscam_qrcode_getqrtext_raw(qrc, qrtext, qrtext_len);
  } else { // >= 1,
    goscam_qrcode_getqrtext(qrc, qrtext, qrtext_len);
  }
}

void goscam_qrcode_print(CGetQrCode *qrc) {
  Log("####### goscam_qrcode_print begin #######\n");
  if(qrc != NULL) {
    Log("## nAction=%d, nDevCap=%d, id=%s, mac=%s, usr=%s, pwd=%s, nDevType=%d, cWifiMod=%c\nbin(nDevCap)=",
       qrc->nAction, qrc->nDevCap, qrc->szDevID, qrc->szDevMAC, qrc->szUser, qrc->szPwd, qrc->nDevType, qrc->cWifiMod);
    PRINT_BIN_TEXT(qrc->nDevCap);
    goscam_qrcode_print_abilities(qrc->nDevCap);
  } else {
    Log("CGetQrCode obj NULL!\n");
  }
  Log("####### goscam_qrcode_print end #######\n");
}

void goscam_qrcode_list_abilities() {
  Log("goscam.capabilities:\n");
  Log("0x%08x=QRC_BIT_ENCRYPTED_IC\n", QRC_BIT_ENCRYPTED_IC);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_ENCRYPTED_IC));
  Log("0x%08x=QRC_BIT_PIR\n", QRC_BIT_PIR);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_PIR));
  Log("0x%08x=QRC_BIT_PTZ\n", QRC_BIT_PTZ);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_PTZ));
  Log("0x%08x=QRC_BIT_MICROPHONE\n", QRC_BIT_MICROPHONE);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_MICROPHONE));
  Log("0x%08x=QRC_BIT_SPEAKER\n", QRC_BIT_SPEAKER);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_SPEAKER));
  Log("0x%08x=QRC_BIT_SDCARD_SLOT\n", QRC_BIT_SDCARD_SLOT);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_SDCARD_SLOT));
  Log("0x%08x=QRC_BIT_TEMPERATURE\n", QRC_BIT_TEMPERATURE);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_TEMPERATURE));
  Log("0x%08x=QRC_BIT_AUTO_TIMEZONE\n", QRC_BIT_AUTO_TIMEZONE);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_AUTO_TIMEZONE));
  Log("0x%08x=QRC_BIT_NIGHT_VISON\n", QRC_BIT_NIGHT_VISON);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_NIGHT_VISON));
  Log("0x%08x=QRC_BIT_ETHERNET_SLOT\n", QRC_BIT_ETHERNET_SLOT);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_ETHERNET_SLOT));
  Log("0x%08x=QRC_BIT_SMART_WIFI\n", QRC_BIT_SMART_WIFI);
  PRINT_BIN_TEXT(((unsigned) QRC_BIT_SMART_WIFI));
}

static inline int goscam_qrcode_count_abilities(int abilities)
{
  ipc_abilities *ipccap = (ipc_abilities*) &abilities;
  return ipccap->unused +
       ipccap->bit_encrypted_ic +
       ipccap->bit_pir +
       ipccap->bit_ptz +
       ipccap->bit_microphone +
       ipccap->bit_speaker +
       ipccap->bit_sdcard_slot +
       ipccap->bit_temperature +
       ipccap->bit_timezone +
       ipccap->bit_night_vison +
       ipccap->bit_ethernet_slot +
       ipccap->bit_smart_wifi;
}

static inline void goscam_qrcode_wrap_abilities(int abilities, unsigned char* caps){
  ipc_abilities *ipccap = (ipc_abilities*) &abilities;
  int index = 0;
  caps[index] = (unsigned char) ipccap->unused;
  index++;
  caps[index] = (unsigned char) ipccap->bit_encrypted_ic;
  index++;
  caps[index] = (unsigned char) ipccap->bit_pir;
  index++;
  caps[index] = (unsigned char) ipccap->bit_ptz;
  index++;
  caps[index] = (unsigned char) ipccap->bit_microphone;
  index++;
  caps[index] = (unsigned char) ipccap->bit_speaker;
  index++;
  caps[index] = (unsigned char) ipccap->bit_sdcard_slot;
  index++;
  caps[index] = (unsigned char) ipccap->bit_temperature;
  index++;
  caps[index] = (unsigned char) ipccap->bit_timezone;
  index++;
  caps[index] = (unsigned char) ipccap->bit_night_vison;
  index++;
  caps[index] = (unsigned char) ipccap->bit_ethernet_slot;
  index++;
  caps[index] = (unsigned char) ipccap->bit_smart_wifi;
}

void goscam_qrcode_print_abilities(int abilities){
  int inused = QRC_BIT_INUSED;

  unsigned char ipccap[QRC_CAP_BITS];
  char enabled[1024];
  char disabled[1024];
  int i = 0, en_offset = 0, dis_offset = 0;
  int count = 0;
  const char* descriptions[] = {
	  "", "ENCRYPTED_IC", "PIR", "PTZ", "MICROPHONE", "SPEAKER",
    "SDCARD-SLOT", "TEMPERATURE", "TIMEZONE", "NIGHT-VISON",
    "ETHERNET-SLOT", "SMART-WIFI", "MOTION_DETEC", "RECORD_DURATION",
  };
  count = goscam_qrcode_count_abilities(abilities);

  memset(enabled, '\0', 1024);
  memset(disabled, '\0', 1024);
  goscam_qrcode_wrap_abilities(abilities, ipccap);
  // Log("count=%d\n", count);
  for(i = 1; i < inused; i++) {
    if(ipccap[i] != 0){
      // sprintf(enabled+en_offset, "%s", descriptions[i]);
      memcpy(enabled+en_offset, descriptions[i], strlen(descriptions[i]));
      en_offset += strlen(descriptions[i]);
      if(--count == 0){
        memcpy(enabled+en_offset, "\n", 2);
      } else if(count > 0) {
        memcpy(enabled+en_offset, ", ", 2);
        en_offset += strlen(", ");
      }
    } else {
      memcpy(disabled+dis_offset, descriptions[i], strlen(descriptions[i]));
      dis_offset += strlen(descriptions[i]);
      if((i == inused - 1) || (i == inused - 2 && count == 1)){
        memcpy(disabled+dis_offset, "\n", 2);
      } else {
        memcpy(disabled+dis_offset, ", ", 2);
        dis_offset += strlen(", ");
      }
    }
  }
  Log("## enabled: %s\n", enabled);
  Log("## disabled: %s\n", disabled);
}

/**
 * qrc[in]:
 * flag[in]:
 * opt[in & out]
 */
void goscam_qrcode_check(CGetQrCode *qrc, QRC_BIT _bit, E_QRC_OPTION *opt) {
  if(qrc == NULL) {
    *opt = E_QRC_OPTION_FAILED;
    return;
  }
  goscam_qrcode_check_int(&qrc->nDevCap, _bit, opt);
  // switch(*opt){
  //   case E_QRC_OPTION_ENABLE:
  //     // enable
  //     qrc->nDevCap = qrc->nDevCap | _bit;
  //     break;
  //   case E_QRC_OPTION_DISABLE:
  //     // disable
  //     qrc->nDevCap = qrc->nDevCap & (~_bit);
  //     break;
  //   case E_QRC_OPTION_QUERY:
  //   default:
  //     break;
  // }
  // *opt = (qrc->nDevCap & _bit) == _bit;
}

void goscam_qrcode_check_int(int *abilities, QRC_BIT _bit, E_QRC_OPTION *opt){
  switch(*opt){
    case E_QRC_OPTION_ENABLE:
      // enable
      *abilities = *abilities | _bit;
      break;
    case E_QRC_OPTION_DISABLE:
      // disable
      *abilities = *abilities & (~_bit);
      break;
    case E_QRC_OPTION_QUERY:
    default:
      break;
  }
  if((*abilities & _bit) == _bit){
    *opt = E_QRC_OPTION_ENABLE;
  } else {
    *opt = E_QRC_OPTION_DISABLE;
  }
}

void goscam_qrcode_chk_encryptedIC(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_ENCRYPTED_IC, opt);
}

void goscam_qrcode_chk_pir(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_PIR, opt);
}

void goscam_qrcode_chk_ptz(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_PTZ, opt);
}

void goscam_qrcode_chk_mic(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_MICROPHONE, opt);
}

void goscam_qrcode_chk_speaker(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_SPEAKER, opt);
}

void goscam_qrcode_chk_sdcard(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_SDCARD_SLOT, opt);
}

void goscam_qrcode_chk_temperature(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_TEMPERATURE, opt);
}

void goscam_qrcode_chk_timezoneAuto(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_AUTO_TIMEZONE, opt);
}

void goscam_qrcode_chk_nightVison(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_NIGHT_VISON, opt);
}

void goscam_qrcode_chk_ethernet(CGetQrCode *qrc, E_QRC_OPTION *opt){
  goscam_qrcode_check(qrc, QRC_BIT_ETHERNET_SLOT, opt);
}

void goscam_qrcode_chk_smartwifi(CGetQrCode *qrc, E_QRC_OPTION *opt) {
  goscam_qrcode_check(qrc, QRC_BIT_SMART_WIFI, opt);
}

void goscam_qrcode_eanble_all(CGetQrCode *qrc){
  if(qrc != NULL) {
    qrc->nDevCap = 0xFFFFFFFF;
    // qrc->nDevCap |= QRC_BIT_ENCRYPTED_IC;
    // qrc->nDevCap |= QRC_BIT_PIR;
    // qrc->nDevCap |= QRC_BIT_PTZ;
    // qrc->nDevCap |= QRC_BIT_MICROPHONE;
    // qrc->nDevCap |= QRC_BIT_SPEAKER;
    // qrc->nDevCap |= QRC_BIT_SDCARD_SLOT;
    // qrc->nDevCap |= QRC_BIT_TEMPERATURE;
    // qrc->nDevCap |= QRC_BIT_AUTO_TIMEZONE;
    // qrc->nDevCap |= QRC_BIT_NIGHT_VISON;
    // qrc->nDevCap |= QRC_BIT_ETHERNET_SLOT;
    // qrc->nDevCap |= QRC_BIT_SMART_WIFI;
  }
}

void goscam_qrcode_disable_all(CGetQrCode *qrc){
  if(qrc != NULL) {
    qrc->nDevCap = 0;
  }
}

void Base64_decode(unsigned char *src, int src_len, char *dst, int *dst_len)
 {
	 int i = 0, j = 0;
	 unsigned char base64_decode_map[256] =
	 {
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255,  62, 255, 255, 255,  63,  52,  53,  54,  55,  56,  57,  58,  59,
		 60,  61, 255, 255, 255,   0, 255, 255, 255,   0,   1,   2,   3,   4,
		 5,   6,   7,   8,   9,  10,  11,  12,  13,  14,  15,  16,  17,  18,
		 19,  20,  21,  22,  23,  24,  25, 255, 255, 255, 255, 255, 255,  26,
		 27,  28,  29,  30,  31,  32,  33,  34,  35,  36,  37,  38,  39,  40,
		 41,  42,  43,  44,  45,  46,  47,  48,  49,  50,  51, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
		 255, 255, 255, 255
	 };

	 if (src_len % 4 != 0)		//make sure the src_len is
		 src_len -= src_len % 4;
	 for (; i < src_len; i += 4)
	 {
		 dst[j++] = base64_decode_map[src[i]] << 2 | base64_decode_map[src[i + 1]] >> 4;
		 dst[j++] = base64_decode_map[src[i + 1]] << 4 | base64_decode_map[src[i + 2]] >> 2;
		 dst[j++] = base64_decode_map[src[i + 2]] << 6 | base64_decode_map[src[i + 3]];
	 }

	 dst[j]   = '\0';
	 if (dst_len)
		 *dst_len = j;
 }

 void Base64_encode(unsigned char *src, int src_len, char *dst, int *dst_len)
 {
	 int i = 0, j = 0;
	 char base64_map[65] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	 if(src == NULL || dst == NULL)
		 return ;
	 for (; i < src_len - src_len % 3; i += 3)
	 {
		 dst[j++] = base64_map[(src[i]  >> 2) & 0x3F];
		 dst[j++] = base64_map[((src[i] << 4) & 0x30) + ((src[i + 1] >> 4) & 0xF)];
		 dst[j++] = base64_map[((src[i + 1] << 2) & 0x3C) + ((src[i + 2] >> 6) & 0x3)];
		 dst[j++] = base64_map[src[i + 2] & 0x3F];
	 }

	 if (src_len % 3 == 1)
	 {
		 dst[j++] = base64_map[(src[i] >> 2) & 0x3F];
		 dst[j++] = base64_map[(src[i] << 4) & 0x30];
		 dst[j++] = '=';
		 dst[j++] = '=';
	 }
	 else if (src_len % 3 == 2)
	 {
		 dst[j++] = base64_map[(src[i] >> 2) & 0x3F];
		 dst[j++] = base64_map[((src[i] << 4) & 0x30) + ((src[i + 1] >> 4) & 0xF)];
		 dst[j++] = base64_map[(src[i + 1] << 2) & 0x3C];
		 dst[j++] = '=';
	 }
	 dst[j] = '\0';
	 if (dst_len)
		 *dst_len = j;
 }
