#ifndef _QRCODE_CONFIG_H_
#define _QRCODE_CONFIG_H_

// ��ά��Э���һЩĬ��ֵ
#define QRC_DEFAULT_USR "admin"
#define QRC_DEFAULT_PWD "goscam123"
#define QRC_DEFAULT_ENCRYPT_METHOD QRC_ENCRYPT_MTH_BASE64

#define SIZEOF_CGetQrCode_Origin 256 // CGetQrCode ԭʼ��С, �汾���ݹ�����, �˴���Ҫ����


#define QRC_DEF_STR_LEN 64
#define QRC_CAP_BITS    32
#define QRC_RESERVE_LEN 46//52

typedef enum _QRC_BIT {
    QRC_BIT_ENCRYPTED_IC		= 0x2,			// �Ƿ��м���IC
    QRC_BIT_PIR					= 0x4,			// �Ƿ���PIR��������0:�ޣ�1:�У���ͬ
    QRC_BIT_PTZ					= 0x8,			// �Ƿ�����̨
    QRC_BIT_MICROPHONE			= 0x10,			// �Ƿ�����ͷ/��˷�
    QRC_BIT_SPEAKER				= 0x20,			// �Ƿ�������
    QRC_BIT_SDCARD_SLOT			= 0x40,			// �Ƿ���SD��
    QRC_BIT_TEMPERATURE			= 0x80,			// �Ƿ����¸�̽ͷ
    QRC_BIT_AUTO_TIMEZONE		= 0x100,		// �Ƿ�֧��ͬ��ʱ��
    QRC_BIT_NIGHT_VISON			= 0x200,		// �Ƿ�֧��ҹ��
    QRC_BIT_ETHERNET_SLOT		= 0x400,		// �Ƿ������
    QRC_BIT_SMART_WIFI			= 0x800,		// �豸��WiFiģ���Ƿ�֧��SmartConfig����
    QRC_BIT_MOTION_DETECTION	= 0x1000,		// �Ƿ�֧���ƶ����
    QRC_BIT_RECORD_DURATION		= 0x2000,		// �Ƿ�֧��¼��ʱ������
    QRC_BIT_LIGHT_FLAG			= 0x4000,		// �Ƿ������������ƿ���
    QRC_BIT_VOICE_DETECTION		= 0x8000,		// �Ƿ�֧��������ⱨ��
} QRC_BIT, E_AbilityInfo;

/*ע�⣺(-���ѷ���,+������)
 +	1. sizeof(CGetQrCode)  ҪС��1024
 -	2. ���ɶ�ά��֮ǰ ����ǰ����9���ֽ� �磺goscam@1:    @����ǰΪ������ @���ź�λ���뷽ʽ 1����base64���� ð�ź�Ϊ����
 ���������ƿ�Э�̶��壬Ŀǰ�̶����ȣ���
 + 2. ��ά��ṹ���Ա���CGetQrCode, ��ά���ı�����:
 #   00301xxxx QRC://G.xxxx  QRC://R.xxxx
 */
typedef struct {
    unsigned int   nAction;		                  // 0.����;1.����;2.
    unsigned int   nDevCap; 		                // �豸������ ��Ӧ E_AbilityInfo
    unsigned char  szDevID   [QRC_DEF_STR_LEN]; // �豸ID
    unsigned char  szDevMAC  [QRC_DEF_STR_LEN];	// �豸MAC
    unsigned char  szUser    [QRC_DEF_STR_LEN]; // ȡ���û���
    unsigned char  szPwd     [QRC_DEF_STR_LEN];	// ȡ������
    unsigned char  szWifiSSID[QRC_DEF_STR_LEN]; // ����Wifi: SSID
    unsigned char  szWifiPwd [QRC_DEF_STR_LEN]; // ����Wifi: ����
    unsigned char  reserve   [QRC_RESERVE_LEN]; // Ԥ��
    unsigned char  cIsRawID;                    // �Ƿ���UIDʶ��Ķ�ά��: 0��������; 1������
    unsigned char  cWifiMod;                    // �Ƿ�֧��smartɨ��	0������֧�֣�1����7601smart  2����8188smart
    unsigned int   nDevType;                    // �豸����:900���԰�;901���Ӱ�;101����;100����
    unsigned short nEncryptMth;                 // �ӽ���/����뷽��
    unsigned short nVersion;                    // �汾��
} CGetQrCode;

//IPC �������ṹ�壬��Ҫ���ڸ�APP���ṩ���ػ���ʾ��ؼ�UI ������
typedef struct
{
    unsigned int   c_device_type; //�豸����900���԰�101����100����
    unsigned int   un_resolution_0_flag;	//�������ֱ��ʴ�С Width:��16λ Height:��16λ  Ming@2016.06.14
    unsigned int   un_resolution_1_flag;	//������
    unsigned int   un_resolution_2_flag;	//��3·����
    unsigned char  c_encrypted_ic_flag;	//�Ƿ��м���IC
    unsigned char  c_pir_flag; 			//�Ƿ���PIR��������0:�ޣ�1:�У���ͬ
    unsigned char  c_ptz_flag; 			//�Ƿ�����̨
    unsigned char  c_mic_flag; 			//�Ƿ�����ͷ
    unsigned char  c_speaker_flag; 		//�Ƿ�������
    unsigned char  c_sd_flag;			//�Ƿ���SD��
    unsigned char  c_temperature_flag; 	//�Ƿ����¸�̽ͷ
    unsigned char  c_timezone_flag;		//�Ƿ�֧��ͬ��ʱ��
    unsigned char  c_night_vison_flag;	//�Ƿ�֧��ҹ��
    
    unsigned char  ethernet_flag;	//�Ƿ������
    unsigned char  c_smart_connect_flag;	//�Ƿ�֧��smartɨ��	0������֧�֣�1����7601smart  2����8188smart
    unsigned char  c_motion_detection_flag; //�Ƿ�֧���ƶ����
    unsigned char  c_record_duration_flag;
}T_SDK_DEVICE_ABILITY_INFO1;


// wwei add begin 20161107
typedef struct
{
    unsigned int   c_device_type; //�豸����   900���԰�     101����     100����	    901������
    unsigned int   un_resolution_0_flag;	//�������ֱ��ʴ�С Width:��16λ Height:��16λ  Ming@2016.06.14
    unsigned int   un_resolution_1_flag;	//������
    unsigned int   un_resolution_2_flag;	//��3·����
    unsigned char  c_encrypted_ic_flag;	//�Ƿ��м���IC
    unsigned char  c_pir_flag; 			//�Ƿ���PIR��������0:�ޣ�1:�У���ͬ
    unsigned char  c_ptz_flag; 			//�Ƿ�����̨
    unsigned char  c_mic_flag; 			//�Ƿ�����ͷ
    
    unsigned char  c_speaker_flag; 		//�Ƿ�������
    unsigned char  c_sd_flag;			//�Ƿ���SD��
    unsigned char  c_temperature_flag; 	//�Ƿ����¸�̽ͷ
    unsigned char  c_timezone_flag;		//�Ƿ�֧��ͬ��ʱ��
    
    unsigned char  c_night_vison_flag;	//�Ƿ�֧��ҹ��
    unsigned char  ethernet_flag;		//�Ƿ������0:wifi 1����2wifi������
    unsigned char  c_smart_connect_flag;	/* �Ƿ�֧��smartɨ��
                                             0������֧�֣�
                                             1����7601smart
                                             2����8188smart
                                             3����ap6212
                                             101������ά��ɨ��+7601smart
                                             102������ά��ɨ��+8188smart
                                             */
    unsigned char  c_motion_detection_flag; //�Ƿ�֧���ƶ����
    
    unsigned char  c_record_duration_flag; // �Ƿ�������¼��¼��ʱ��
    unsigned char  c_light_flag; // �Ƿ������������ƿ���
    unsigned char  c_voice_detection_flag; //�Ƿ�֧��������ⱨ��
    unsigned char  align1;	 // �����ֽڶ���
    unsigned char  reserver_default_off[32]; // Ԥ��������Ĭ�Ϲر�
    unsigned char  reserver_default_on[32]; // Ԥ��������Ĭ�Ͽ���
}T_SDK_DEVICE_ABILITY_INFO2;	
// wwei add end 20161107

typedef enum {
    E_QRC_VERSION_UNKNOWN = -1,
    E_QRC_VERSION_OLD = 0,
    E_QRC_VERSION_V1  = 1,
    E_QRC_VERSION_V2  = 2,
} E_QRC_VERSION;

typedef struct {
    CGetQrCode qrc;
    T_SDK_DEVICE_ABILITY_INFO1 info;
    T_SDK_DEVICE_ABILITY_INFO2 info2;
    int have_abi;
} CGQRCodeCompatV1;

#endif //_QRCODE_CONFIG_H_