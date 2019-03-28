#ifndef _QRCODE_TOOLS_H
#define _QRCODE_TOOLS_H

#include "quicklz.h"
#include "qrcode_config.h"

// 二维码文本前缀
#define QRC_GOSCAM_PREFIX "goscam@"
#define QRC_GOSCAM_PREFIX_RAW  "QRC://R." //
#define QRC_GOSCAM_PREFIX_V1  "QRC://G."
#define QRC_GOSCAM_PREFIX_NONE "00301" //

// 二维码前缀实际长度
#define QRC_GOSCAM_PREFIX_LEN      strlen(QRC_GOSCAM_PREFIX)+2    // "goscam@1:"
#define QRC_GOSCAM_PREFIX_LEN_V1   strlen(QRC_GOSCAM_PREFIX_V1)   // "QRC://G."
#define QRC_GOSCAM_PREFIX_LEN_RAW  strlen(QRC_GOSCAM_PREFIX_RAW)  // "QRC://R."
#define QRC_GOSCAM_PREFIX_LEN_NONE strlen(QRC_GOSCAM_PREFIX_NONE) // 00301

// 二维码文本UID后缀, TUTK裸UID二维码文本识别
#define QRC_TUTK_POSTFIX "111A"

#define QRC_PROTOCOL_VER 0x0001 //short

#define QRC_CAP_LEN_V2		22

/// for GOSCAM-QRC V1
typedef enum _QRC_TAG {
  QRC_TAG_ACTION      = 0,	// 二维码用途
  QRC_TAG_IPC_ID      = 1,	// ID
  QRC_TAG_IPC_ABI     = 2,	// 能力级
  QRC_TAG_IPC_MAC     = 3,	// MAC
  QRC_TAG_STREAM_USR  = 4,	// 取流用户名
  QRC_TAG_STREAM_PWD  = 5,	// 取流密码
  QRC_TAG_SMART_SSID  = 6,	// Smart配置WiFi-SSID
  QRC_TAG_SMART_PWD   = 7,	// Smart配置WiFi-密码
  QRC_TAG_RESERVE     = 8,
  QRC_TAG_ENCRYPTMTH  = 9,	// 加解密/编解码方法
  QRC_TAG_VERSION     = 10,	// GQRC 版本号
  QRC_TAG_IPC_EXTRA   = 11,
  // ADD NEW TAGS HERE...
} QRC_TAG;

// 二维码文本编码方式(不含加密)
typedef enum _QRC_ENCRYPT_MTH {
  QRC_ENCRYPT_MTH_NONE    = 0, // 不使用任何编解码方法
  QRC_ENCRYPT_MTH_BASE64  = 1, // 使用Base64编解码
  QRC_ENCRYPT_MTH_HUFFMAN = 2  // 使用哈夫曼编解码
} QRC_ENCRYPT_MTH;

// 二维码文本用途
typedef enum _QRC_ACTION {
  QRC_ACTION_UNKNOWN        = -1,
  QRC_ACTION_FACTORY        = 0, // 工厂生产(贴机二维码, 生产工具生成, APP识别) 第一版
  QRC_ACTION_IPC_SHARING    = 1, // 分享设备, APP功能(APP生成, APP识别)
  QRC_ACTION_SMART_CONFIG   = 2, // WiFi配置(APP生成, IPC识别, 设备端[WiFi模块不支持Smart功能]的WiFi配置方案)
  QRC_ACTION_FACTORY_V1     = 3, // 工厂生产(贴机二维码, 生产工具生成, APP识别) 第二版
  QRC_ACTION_FACTORY_V2     = 4, // 工厂生产(贴机二维码, 生产工具生成, APP识别) 第三版
  // add new action here
} QRC_ACTION;

// 位操作标识
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
 * 简单构造一个二维码内容结构体
 */
CGetQrCode* goscam_qrcode_create(int action);

void goscam_qrcode_sharing_v1(const char *szDevID, const char *szStreamUser, const char *szSteamPwd, char **qrtext, int *qrtext_len);

void goscam_qrcode_smartconfig_v1(const char *szDevID, const char *szWiFiSSID, const char *szWiFiPwd, char **qrtext, int *qrtext_len);

void goscam_qrcode_gettext_v1(const char *szDevID, T_SDK_DEVICE_ABILITY_INFO1 *info, char **qrtext, int *qrtext_len);

void goscam_qrcode_gettext_v2(const char *szDevID, T_SDK_DEVICE_ABILITY_INFO2 *info, char **qrtext, int *qrtext_len);

/**
 * 识别二维码文本, 传入字符串及长度, 返回识别结果(NULL表示无效的二维码文本)
 */
CGetQrCode* goscam_qrcode_recognize(const unsigned char *qrctext, int qrctext_len);

void goscam_qrcode_recognize_compat(const unsigned char *qrctext, int qrctext_len, E_QRC_VERSION *version, char **dest);

/**
 */
void goscam_qrcode_destroy(CGetQrCode *qrc);

/**
 * 为兼容以前版本, 默认以最新协议获取二维码内容
 */
void goscam_qrcode_getqrtext(CGetQrCode *qrc, char **qrtext, int *qrtext_len);

/**
 * 根据版本获取二维码内容, 若非必要, 请使用 goscam_qrcode_getqrtext
 */
void goscam_qrcode_getqrtext_pro(CGetQrCode *qrc, int gqrc_version, char **qrtext, int *qrtext_len);

/**
 * 获取标签名称
 */
char* goscam_qrcode_get_tagname(int tag);

/**
 * 根据标签获取字符串指针
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
 * opt[in & out]:  查询是否支持某种能力; 或设置某种能力，使其生效或者失效<br/>
 * opt=E_QRC_OPTION_QUERY(查询)||E_QRC_OPTION_ENABLE(生效||E_QRC_OPTION_DISABLE(失效)<br/>
 * opt值先设置操作码, 调用goscam_qrcode_check后获得该能力的最新状态(0:已失效;1:已生效);<br/>
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
