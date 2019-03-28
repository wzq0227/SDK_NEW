#ifndef _QRCODE_TOOLS_H
#define _QRCODE_TOOLS_H

#include "quicklz.h"
#include "qrcode_config.h"

// ��ά���ı�ǰ׺
#define QRC_GOSCAM_PREFIX "goscam@"
#define QRC_GOSCAM_PREFIX_RAW  "QRC://R." //
#define QRC_GOSCAM_PREFIX_V1  "QRC://G."
#define QRC_GOSCAM_PREFIX_NONE "00301" //

// ��ά��ǰ׺ʵ�ʳ���
#define QRC_GOSCAM_PREFIX_LEN      strlen(QRC_GOSCAM_PREFIX)+2    // "goscam@1:"
#define QRC_GOSCAM_PREFIX_LEN_V1   strlen(QRC_GOSCAM_PREFIX_V1)   // "QRC://G."
#define QRC_GOSCAM_PREFIX_LEN_RAW  strlen(QRC_GOSCAM_PREFIX_RAW)  // "QRC://R."
#define QRC_GOSCAM_PREFIX_LEN_NONE strlen(QRC_GOSCAM_PREFIX_NONE) // 00301

// ��ά���ı�UID��׺, TUTK��UID��ά���ı�ʶ��
#define QRC_TUTK_POSTFIX "111A"

#define QRC_PROTOCOL_VER 0x0001 //short

#define QRC_CAP_LEN_V2		22

/// for GOSCAM-QRC V1
typedef enum _QRC_TAG {
  QRC_TAG_ACTION      = 0,	// ��ά����;
  QRC_TAG_IPC_ID      = 1,	// ID
  QRC_TAG_IPC_ABI     = 2,	// ������
  QRC_TAG_IPC_MAC     = 3,	// MAC
  QRC_TAG_STREAM_USR  = 4,	// ȡ���û���
  QRC_TAG_STREAM_PWD  = 5,	// ȡ������
  QRC_TAG_SMART_SSID  = 6,	// Smart����WiFi-SSID
  QRC_TAG_SMART_PWD   = 7,	// Smart����WiFi-����
  QRC_TAG_RESERVE     = 8,
  QRC_TAG_ENCRYPTMTH  = 9,	// �ӽ���/����뷽��
  QRC_TAG_VERSION     = 10,	// GQRC �汾��
  QRC_TAG_IPC_EXTRA   = 11,
  // ADD NEW TAGS HERE...
} QRC_TAG;

// ��ά���ı����뷽ʽ(��������)
typedef enum _QRC_ENCRYPT_MTH {
  QRC_ENCRYPT_MTH_NONE    = 0, // ��ʹ���κα���뷽��
  QRC_ENCRYPT_MTH_BASE64  = 1, // ʹ��Base64�����
  QRC_ENCRYPT_MTH_HUFFMAN = 2  // ʹ�ù����������
} QRC_ENCRYPT_MTH;

// ��ά���ı���;
typedef enum _QRC_ACTION {
  QRC_ACTION_UNKNOWN        = -1,
  QRC_ACTION_FACTORY        = 0, // ��������(������ά��, ������������, APPʶ��) ��һ��
  QRC_ACTION_IPC_SHARING    = 1, // �����豸, APP����(APP����, APPʶ��)
  QRC_ACTION_SMART_CONFIG   = 2, // WiFi����(APP����, IPCʶ��, �豸��[WiFiģ�鲻֧��Smart����]��WiFi���÷���)
  QRC_ACTION_FACTORY_V1     = 3, // ��������(������ά��, ������������, APPʶ��) �ڶ���
  QRC_ACTION_FACTORY_V2     = 4, // ��������(������ά��, ������������, APPʶ��) ������
  // add new action here
} QRC_ACTION;

// λ������ʶ
typedef enum _E_QRC_OPTION {
  E_QRC_OPTION_FAILED = -1,
  E_QRC_OPTION_DISABLE = 0,
  E_QRC_OPTION_ENABLE = 1,
  E_QRC_OPTION_QUERY = 2,
} E_QRC_OPTION;


#define QRC_BIT_INUSED 14
typedef struct {
	unsigned unused:1;
	unsigned bit_encrypted_ic:1;
	unsigned bit_pir:1;
	unsigned bit_ptz:1;
	unsigned bit_microphone:1;
	unsigned bit_speaker:1;
	unsigned bit_sdcard_slot:1;
	unsigned bit_temperature:1;
	unsigned bit_timezone:1;
	unsigned bit_night_vison:1;
	unsigned bit_ethernet_slot:1;
  unsigned bit_smart_wifi:1;
	unsigned bit_reserved:20;
} ipc_abilities;

void PRINT_BIN_TEXT(unsigned c);
void Base64_decode(unsigned char *src, int src_len, char *dst, int *dst_len);
void Base64_encode(unsigned char *src, int src_len, char *dst, int *dst_len);

// void goscam_qrcode_tlv_read(CGetQrCode* qrc, char* src, int length);
// void goscam_qrcode_tlv_write(CGetQrCode* qrc, char* src, int length);

/**
 * �򵥹���һ����ά�����ݽṹ��
 */
CGetQrCode* goscam_qrcode_create(int action);

void goscam_qrcode_sharing_v1(const char *szDevID, const char *szStreamUser, const char *szSteamPwd, char **qrtext, int *qrtext_len);

void goscam_qrcode_smartconfig_v1(const char *szDevID, const char *szWiFiSSID, const char *szWiFiPwd, char **qrtext, int *qrtext_len);

void goscam_qrcode_gettext_v1(const char *szDevID, T_SDK_DEVICE_ABILITY_INFO1 *info, char **qrtext, int *qrtext_len);

void goscam_qrcode_gettext_v2(const char *szDevID, T_SDK_DEVICE_ABILITY_INFO2 *info, char **qrtext, int *qrtext_len);

/**
 * ʶ���ά���ı�, �����ַ���������, ����ʶ����(NULL��ʾ��Ч�Ķ�ά���ı�)
 */
CGetQrCode* goscam_qrcode_recognize(const unsigned char *qrctext, int qrctext_len);

void goscam_qrcode_recognize_compat(const unsigned char *qrctext, int qrctext_len, E_QRC_VERSION *version, char **dest);

/**
 */
void goscam_qrcode_destroy(CGetQrCode *qrc);

/**
 * Ϊ������ǰ�汾, Ĭ��������Э���ȡ��ά������
 */
void goscam_qrcode_getqrtext(CGetQrCode *qrc, char **qrtext, int *qrtext_len);

/**
 * ���ݰ汾��ȡ��ά������, ���Ǳ�Ҫ, ��ʹ�� goscam_qrcode_getqrtext
 */
void goscam_qrcode_getqrtext_pro(CGetQrCode *qrc, int gqrc_version, char **qrtext, int *qrtext_len);

/**
 * ��ȡ��ǩ����
 */
char* goscam_qrcode_get_tagname(int tag);

/**
 * ���ݱ�ǩ��ȡ�ַ���ָ��
 */
char* goscam_qrcode_get_tagptr(CGetQrCode *qrc, QRC_TAG tag, int *str_length);
/**
 */
void goscam_qrcode_print(CGetQrCode *qrc);

void goscam_qrcode_list_abilities();

void goscam_qrcode_print_abilities(int abilities);

/**
 * qrc[in]:
 * _bit[in]:
 * opt[in & out]:  ��ѯ�Ƿ�֧��ĳ������; ������ĳ��������ʹ����Ч����ʧЧ<br/>
 * opt=E_QRC_OPTION_QUERY(��ѯ)||E_QRC_OPTION_ENABLE(��Ч||E_QRC_OPTION_DISABLE(ʧЧ)<br/>
 * optֵ�����ò�����, ����goscam_qrcode_check���ø�����������״̬(0:��ʧЧ;1:����Ч);<br/>
 */
void goscam_qrcode_check(CGetQrCode *qrc, QRC_BIT _bit, E_QRC_OPTION *opt);

void goscam_qrcode_check_int(int *abilities, QRC_BIT _bit, E_QRC_OPTION *opt);

void goscam_qrcode_eanble_all(CGetQrCode *qrc);

void goscam_qrcode_disable_all(CGetQrCode *qrc);

void goscam_qrcode_chk_encryptedIC(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_pir(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_ptz(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_mic(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_speaker(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_sdcard(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_temperature(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_timezoneAuto(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_nightVison(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_ethernet(CGetQrCode *qrc, E_QRC_OPTION *opt);
void goscam_qrcode_chk_smartwifi(CGetQrCode *qrc, E_QRC_OPTION *opt);


#endif