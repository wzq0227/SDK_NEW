#ifndef _QRCODE_BASE_H_
#define _QRCODE_BASE_H_

typedef void* (*qrcode_create)(void *src);
typedef void* (*qrcode_recognize)(unsigned char* qrtext, int qrtext_len);
typedef void  (*qrcode_gettext)(void *wrapper, unsigned char* qrtext, int qrtext_len);
typedef void  (*qrcode_release)(void *wrapper);

typedef struct _qrc_origin{
  qrcode_create create;
  qrcode_recognize recognize;
  qrcode_gettext gettext;
  qrcode_release release;
} qrc_origin;

//
// typedef struct _qrc_stuff {
//   int action;
//   ...
// } qrc_stuff;
//
// typedef struct _qrc_stuff_wrapper {
//   int action;
//   ...
// } qrc_stuff_wrapper;
//
// qrc_stuff_wrapper* qrcode_create_impl_v1(qrc_stuff *src);
// qrc_stuff_wrapper* qrcode_recognize_impl_v1(unsigned char* qrtext, int qrtext_len);
// void  qrcode_gettext_impl_v1(qrc_stuff_wrapper *wrapper, unsigned char* qrtext, int qrtext_len);
// void  qrcode_release_impl_v1(qrc_stuff_wrapper *wrapper);
//
// static qrc_origin qrc_impl_v1 = {
// .create = qrcode_create_impl_v1,
// .recognize = qrcode_recognize_impl_v1,
// .gettext = qrcode_gettext_impl_v1,
// .release = qrcode_release_impl_v1,
// };

#endif // _QRCODE_BASE_H_
