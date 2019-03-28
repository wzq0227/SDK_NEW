//#include <ctype.h>
//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
//#include <time.h>
//
//#include "parser.h"
//
//
//////////////////////////////////////////////////////////////////
////CParser Class
//CParser::CParser(ANC_SP_CALLBACK sp_cb, unsigned long nUser,bool bSort )
//{
//       m_bAllowAudioFirst =false;
//    m_FrameLen=0;
//    m_bOpened =false;
//    m_bfirstFrm = true;
//    m_expPacketNo=-1;
//    m_expFrameNo =-1;
//    m_gotFrameHead=0;
//    m_gotFrameTail=0;
//    m_FrameData = NULL;
//    m_bSort = bSort;
//    m_sp_cb=sp_cb;
//    m_nUser=nUser;
//    memset(&frame_info,0x00,sizeof(frame_info));
//}
//
//CParser::~CParser()
//{
//
//}
//
//int CParser::IsValidData(unsigned char* buf)
//{
//    ANC_NET_PACKET_HEAD* pkt = (ANC_NET_PACKET_HEAD*)buf;
//
//    if(pkt->nNetFlag != ANC_MAGIC_FLAG)
//    {
//        printf("IsValidData: nNetFlag=%0x error\r\n",pkt->nNetFlag);
//        return -1;
//    }
//    else
//    {
//       // printf("IsValidData nFrameNo = %d,nPakcetNo = %d\r\n",pkt->nFrameNo,pkt->nPakcetNo);
//        if(m_expFrameNo==-1)
//        {
//            m_expFrameNo = pkt->nFrameNo;
//            m_expPacketNo=0;
//            return 1;
//        }
//        else if(m_expFrameNo < pkt->nFrameNo)
//        {
//            m_expFrameNo = pkt->nFrameNo;
//            m_expPacketNo= 0;
//
//            return 1;
//        }
//        else if(m_expFrameNo>pkt->nFrameNo)
//        {
//            printf("IsValidData: frame lost--> exp=[%d,%ld]->[%ld,%ld]\r\n",m_expFrameNo,m_expPacketNo, pkt->nFrameNo, pkt->nPakcetNo);
//
//            if((m_expFrameNo - pkt->nFrameNo)<FRAME_MAX_DRIFT)
//            {
//                printf("IsValidData: frame drift\r\n");
//                return -1;
//            }
//            else
//            {
//                m_expFrameNo = pkt->nFrameNo;
//                m_expPacketNo= 0;
//
//                return 1;
//            }
//        }
//
//        if(m_expPacketNo==pkt->nPakcetNo)
//        {
//            m_expPacketNo++;
//        }
//        else
//        {
//            printf("IsValidData: packet miss-->exp=[%ld,%ld]->[%ld,%ld of %ld]\r\n",m_expFrameNo,m_expPacketNo, pkt->nFrameNo, pkt->nPakcetNo,pkt->nPakcetCount);
//
//            m_expPacketNo = pkt->nPakcetNo+1;
//        }
//
//        return 0;
//    }
//}
//
//
//bool CParser::IsFrameEnd(unsigned char* buf)
//{
//    if(m_gotFrameHead && m_gotFrameTail)
//    {
//        FRAMEINFO_t  *pFrameHead=(FRAMEINFO_t*)m_FrameData;
//
//        if(m_FrameLen != (pFrameHead->nByteNum+sizeof(FRAMEINFO_t)))
//        {
//            printf("IsFrameEnd: frame crupt [exp=%ld]-[%ld]\r\n",pFrameHead->nByteNum+sizeof(FRAMEINFO_t),m_FrameLen);
//        }
//
//        if(m_FrameLen > (pFrameHead->nByteNum+sizeof(FRAMEINFO_t))/2)
//        {
//            return true;
//        }
//    }
//
//    return false;
//}
//
//int CParser::IsValidData_Sort(unsigned char* buf)
//{
//    ANC_NET_PACKET_HEAD* pkt = (ANC_NET_PACKET_HEAD*)buf;
//
////    if(pkt->nPakcetNo ==0) {
////        FRAMEINFO_t *info = (FRAMEINFO_t*)(buf+sizeof(ANC_NET_PACKET_HEAD));
////        printf("IsValidData_Sort nFrameNo = %d,nPakcetNo = %d, nBufferSize = %d, nPakcetCount=%d,reserve2 = %d,sizeof = %d\r\n",pkt->nFrameNo,pkt->nPakcetNo, pkt->nBufferSize, pkt->nPakcetCount,info->reserve2,sizeof(FRAMEINFO_t));
////    } else {
////        printf("IsValidData_Sort nFrameNo = %d,nPakcetNo = %d, nBufferSize = %d, nPakcetCount=%d\r\n",pkt->nFrameNo,pkt->nPakcetNo, pkt->nBufferSize, pkt->nPakcetCount);
////
////    }
//
//    if(pkt->nNetFlag != ANC_MAGIC_FLAG)
//    {
//        printf("IsValidData_Sort: nNetFlag=%0x error\r\n",pkt->nNetFlag);
//        return -1;
//    }
//    else if(pkt->nFrameNo < m_LastFrameNum)
//    {
//        if((m_LastFrameNum - pkt->nFrameNo)<FRAME_MAX_DRIFT)
//        {
//            printf("IsValidData_Sort: frame[%d] is later than last frame[%d]\r\n",pkt->nFrameNo, m_LastFrameNum);
//            return -1;
//        }
//        else
//            return 0;
//    }
//    else
//    {
//        return 0;
//    }
//}
//
//
//int CParser::GetDataLen(unsigned char* buf)
//{
//    ANC_NET_PACKET_HEAD* pkt = (ANC_NET_PACKET_HEAD*)buf;
//    return pkt->nBufferSize;
//}
//
//int CParser::Open(bool bAllowAudioFirst)
//{
//    m_bAllowAudioFirst = bAllowAudioFirst;
//
//    if(!m_bSort)
//    {
//        m_FrameData = (unsigned char *)malloc(ANC_MAX_FRAME_LEN);
//        if(!m_FrameData)
//            return ERR_MEM_ALLOC_FAIL;
//        m_FrameLen = 0;
//        m_gotFrameHead=0;
//        m_gotFrameTail=0;
//    }
//    else
//    {
//        m_LastFrameNum=0;
//        memset(&m_FrameBuf, 0, sizeof(m_FrameBuf));
//        for(int i  = 0; i < FRAME_NUM_STORE; i++)
//        {
//            memset(m_FrameBuf+i, 0x00,sizeof(FrameInfo));
//            m_FrameBuf[i].bUsed = 0;
//            m_FrameBuf[i].pbuf =NULL;
//            m_FrameBuf[i].pbuf = (unsigned char*)malloc(ANC_MAX_FRAME_LEN);
//            if(!m_FrameBuf[i].pbuf)
//            {
//                for(int j  = 0; j < i; j++)
//                {
//                    free(m_FrameBuf[j].pbuf);
//                }
//                return ERR_MEM_ALLOC_FAIL;
//            }
//        }
//    }
//    m_bOpened = true;
//
//    return 0;
//}
//
//
//int CParser::Close()
//{
//    if(!m_bSort)
//    {
//        if(m_FrameData)
//            free(m_FrameData);
//    }
//    else
//    {
//        for(int i  = 0; i < FRAME_NUM_STORE; i++)
//        {
//            free(m_FrameBuf[i].pbuf);
//        }
//
//    }
//    m_bOpened = false;
//
//    return 0;
//}
//
//int CParser::GetFrame(unsigned char* pBuf,unsigned int Len)
//{
//    if(m_bSort)
//        return GetFrame_Sort(pBuf,Len);
//    else
//        return GetFrame_NSort(pBuf,Len);
//}
//
//
//int CParser::GetFrame_NSort(unsigned char* pBuf,unsigned int Len)
//{
//    if(!m_bOpened)
//    {
//        return ERR_NOT_OPEN;
//    }
//
//    int nRet = IsValidData(pBuf);
//    if(nRet==-1)
//    {
//        return ERR_INVALID_DATA;
//    }
//    else if(nRet==1)
//    {
//        m_FrameLen = 0;
//        m_gotFrameHead=0;
//        m_gotFrameTail=0;
//    }
//
//
//    ANC_NET_PACKET_HEAD* pkt = (ANC_NET_PACKET_HEAD*)pBuf;
//
////    {
////        char buf[128];
////        sprintf(buf,"pkt: nFrameNo=%d, nPakcetNo=%d, nPakcetCount=%d, nBufferSize=%d\r\n", pkt->nFrameNo, pkt->nPakcetNo,pkt->nPakcetCount,pkt->nBufferSize);
////        printf(buf);
////    }
//
//
//    int datalen = GetDataLen(pBuf);
//
//    if (pkt->nPakcetNo == 0 && pkt->nPakcetCount > 1) {
//
//        FRAMEINFO_t *pFrameHead = (FRAMEINFO_t *)(pBuf + sizeof(ANC_NET_PACKET_HEAD));
////         printf("GetFrame_NSort codec_id = %d,flags = %d,cam_index = %d,onlineNum = %d,nByteNum = %d\r\n",pFrameHead->codec_id,pFrameHead->flags,pFrameHead->cam_index,pFrameHead->onlineNum,pFrameHead->nByteNum);
//    }
//
//    if(m_FrameLen+datalen >= ANC_MAX_FRAME_LEN)
//    {
//        //reset
//        m_FrameLen = 0;
//        m_gotFrameHead=0;
//        m_gotFrameTail=0;
//        m_expPacketNo=-1;
//        m_expFrameNo =-1;
//        if(m_FrameLen+datalen >= ANC_MAX_FRAME_LEN)
//        {
////            printf("GetFrame_NSort 333 : frame length[%ld] is more than limit[%ld]\r\n",m_FrameLen+datalen,ANC_MAX_FRAME_LEN);
////            return ERR_INVALID_DATA;
//        }
//    }
//
////    if (((pkt->nFrameFlag&0xff) == ANC_FRAME_FLAG_VI) && (pkt->nPakcetNo != 0)){
////        FRAMEINFO_t *pFrameHead = (FRAMEINFO_t *)m_FrameData;
////        printf("GetFrame_NSort111 codec_id = %d,flags = %d,cam_index = %d,onlineNum = %d,nByteNum = %d, m_FrameLen=%d, nFrameNo = %d,nPakcetNo=%d \r\n",pFrameHead->codec_id,pFrameHead->flags,pFrameHead->cam_index,pFrameHead->onlineNum,pFrameHead->nByteNum,m_FrameLen,pkt->nFrameNo,pkt->nPakcetNo);
////    }
//
////    memcpy(m_FrameData + m_FrameLen, pBuf + sizeof(ANC_NET_PACKET_HEAD), datalen);
//    memcpy(m_FrameData + pkt->nPakcetNo * ANC_NET_PACKET_DATA_SIZE, pBuf + sizeof(ANC_NET_PACKET_HEAD), pkt->nBufferSize);
//    m_FrameLen += datalen;
//
////    if ((pkt->nFrameFlag&0xff) == ANC_FRAME_FLAG_VI)
////    {
////        FRAMEINFO_t *pFrameHead = (FRAMEINFO_t *)m_FrameData;
////        printf("GetFrame_NSort 2222 codec_id = %d,flags = %d,cam_index = %d,onlineNum = %d,nByteNum = %d, m_FrameLen=%d, nFrameNo = %d,nPakcetNo=%d, datalen=%d\r\n",pFrameHead->codec_id,pFrameHead->flags,pFrameHead->cam_index,pFrameHead->onlineNum,pFrameHead->nByteNum,m_FrameLen,pkt->nFrameNo,pkt->nPakcetNo,datalen);
////    }
//
//    if(pkt->nPakcetNo == 0)
//        m_gotFrameHead=1;
//
//    if(pkt->nPakcetNo == pkt->nPakcetCount-1)
//        m_gotFrameTail=1;
//
//    if(IsFrameEnd(pBuf))
//    {
//        frame_info.nRequence=pkt->nFrameNo;
//        //printf("pkt->nFrameNo = %d,pkt->nPakcetCount = %d\r\n",pkt->nFrameNo,pkt->nPakcetCount);
//        return 0;
//    }
//    else
//    {
//        return ERR_FRM_NOT_END;
//    }
//}
//
//int CParser::GetFrame_Sort(unsigned char* pBuf,unsigned int Len)
//{
//    if(!m_bOpened)
//        return ERR_NOT_OPEN;
//
//    if(IsValidData_Sort(pBuf)==-1)
//        return ERR_INVALID_DATA;
//
//    ANC_NET_PACKET_HEAD* pkthead = (ANC_NET_PACKET_HEAD*)pBuf;
//
//    int i;
//    bool bFirstPkt = true;
//    //printf("FrameNo:%u FrameType:%d TS:%u\n", pkthead->nFrameNo, pkthead->frameHead.streamFlag, pkthead->frameHead.nTimestamp);
//
//    for(i = 0; i < FRAME_NUM_STORE; i ++)
//    {
//        if( (m_FrameBuf[i].bUsed == 1) && (m_FrameBuf[i].nFrameNo == pkthead->nFrameNo))
//        {
//            //TRACE("FrameNo:%u index:%d \n", m_FrameBuf[i].nFrameNo, i);
//            memcpy(m_FrameBuf[i].pbuf + pkthead->nPakcetNo * ANC_NET_PACKET_DATA_SIZE, pBuf + sizeof(ANC_NET_PACKET_HEAD), pkthead->nBufferSize);
//            m_FrameBuf[i].nRecvSize += pkthead->nBufferSize;
//
//            bFirstPkt = false;
//
//            if((m_FrameBuf[i].nFrameLength==0) && (pkthead->nPakcetNo==0))
//            {
//                FRAMEINFO_t *pFrameHead = (FRAMEINFO_t *)(m_FrameBuf[i].pbuf);
//
//                m_FrameBuf[i].nFrameLength = pFrameHead->nByteNum + sizeof(FRAMEINFO_t);
//
//                unsigned int nFrameType=0;
//                if(pFrameHead->codec_id==MEDIA_CODEC_AUDIO_AAC)
//                {
//                    nFrameType=ANC_FRAME_FLAG_A;
//                }
//                else if(pFrameHead->codec_id==MEDIA_CODEC_AUDIO_G711A)
//                {
//                    nFrameType=ANC_FRAME_FLAG_A;
//                }
//
//                if(pFrameHead->flags == IPC_FRAME_FLAG_IFRAME)
//                    nFrameType=ANC_FRAME_FLAG_VI;
//                else if(pFrameHead->flags == IPC_FRAME_FLAG_PBFRAME)
//                    nFrameType=ANC_FRAME_FLAG_VP;
//
//                m_FrameBuf[i].nFrameType = nFrameType;
//
//                if(m_FrameBuf[i].nFrameLength >= ANC_MAX_FRAME_LEN)
//                {
//                    printf("GetFrame_Sort: frame length[%ld] is more than limit[%ld]\r\n",m_FrameBuf[i].nFrameLength,ANC_MAX_FRAME_LEN);
//                }
//
//                if(((m_FrameBuf[i].nFrameType&0x0f) != ANC_FRAME_FLAG_A)&&((m_FrameBuf[i].nFrameType&0x0f) != ANC_FRAME_FLAG_REC_A))
//                    m_FrameBuf[i].nTimestamp = pFrameHead->timestamp;
//                else
//                    m_FrameBuf[i].nTimestamp = pFrameHead->timestamp - 5;
//
//            }
//
//            break;
//        }
//    }
//
//    if(bFirstPkt)
//    {
//        for(i = 0; i < FRAME_NUM_STORE; i ++)
//        {
//            if(m_FrameBuf[i].bUsed == 0)
//            {
//                memcpy(m_FrameBuf[i].pbuf + pkthead->nPakcetNo * ANC_NET_PACKET_DATA_SIZE, pBuf + sizeof(ANC_NET_PACKET_HEAD), pkthead->nBufferSize);
//                m_FrameBuf[i].nRecvSize = pkthead->nBufferSize;
//                m_FrameBuf[i].nFrameNo = pkthead->nFrameNo;
//                m_FrameBuf[i].nFrameLength = 0;
//                m_FrameBuf[i].nFrameType = 0;
//
//                bFirstPkt = false;
//                m_FrameBuf[i].bUsed = 1;
//
//                if((m_FrameBuf[i].nFrameLength==0) && (pkthead->nPakcetNo==0))
//                {
//                    FRAMEINFO_t *pFrameHead = (FRAMEINFO_t *)(m_FrameBuf[i].pbuf);
//
//                    m_FrameBuf[i].nFrameLength = pFrameHead->nByteNum + sizeof(FRAMEINFO_t);
//
//                    unsigned int nFrameType=0;
//                    if(pFrameHead->codec_id==MEDIA_CODEC_AUDIO_AAC)
//                    {
//                        nFrameType=ANC_FRAME_FLAG_A;
//                    }
//                    else if(pFrameHead->codec_id==MEDIA_CODEC_AUDIO_G711A)
//                    {
//                        nFrameType=ANC_FRAME_FLAG_A;
//                    }
//
//                    if(pFrameHead->flags == IPC_FRAME_FLAG_IFRAME)
//                        nFrameType=ANC_FRAME_FLAG_VI;
//                    else if(pFrameHead->flags == IPC_FRAME_FLAG_PBFRAME)
//                        nFrameType=ANC_FRAME_FLAG_VP;
//
//                    m_FrameBuf[i].nFrameType = nFrameType;
//
//                    if(m_FrameBuf[i].nFrameLength >= ANC_MAX_FRAME_LEN)
//                    {
//                        printf("GetFrame_Sort: frame length[%ld] is more than limit[%ld]\r\n",m_FrameBuf[i].nFrameLength,ANC_MAX_FRAME_LEN);
//                    }
//
//                    if(((m_FrameBuf[i].nFrameType&0x0f) != ANC_FRAME_FLAG_A)&&((m_FrameBuf[i].nFrameType&0x0f) != ANC_FRAME_FLAG_REC_A))
//                        m_FrameBuf[i].nTimestamp = pFrameHead->timestamp;
//                    else
//                        m_FrameBuf[i].nTimestamp = pFrameHead->timestamp - 5;
//
//                }
//                break;
//            }
//        }
//    }
//
//    if(bFirstPkt)   //No free buf for store this pkt
//    {
//        int OldestFrameIndex = getOldestFrameIndex();
//        if(OldestFrameIndex != -1)
//        {
//            printf("getOldestFrameIndex: obsolete frame[nFrameType=%d,No=%d, nFrameLength=%d, nRecvSize=%d] !!!\r\n",m_FrameBuf[OldestFrameIndex].nFrameType,m_FrameBuf[OldestFrameIndex].nFrameNo,m_FrameBuf[OldestFrameIndex].nFrameLength,m_FrameBuf[OldestFrameIndex].nRecvSize);
//
//            memcpy(m_FrameBuf[OldestFrameIndex].pbuf + pkthead->nPakcetNo * ANC_NET_PACKET_DATA_SIZE, pBuf + sizeof(ANC_NET_PACKET_HEAD), pkthead->nBufferSize);
//            m_FrameBuf[OldestFrameIndex].nRecvSize = pkthead->nBufferSize;
//            m_FrameBuf[OldestFrameIndex].nFrameNo = pkthead->nFrameNo;
//            m_FrameBuf[OldestFrameIndex].nFrameType = 0;
//            m_FrameBuf[OldestFrameIndex].nFrameLength = 0;
//
//            m_FrameBuf[OldestFrameIndex].bUsed = 1;
//            bFirstPkt = false;
//
//            if((m_FrameBuf[OldestFrameIndex].nFrameLength==0) && (pkthead->nPakcetNo==0))
//            {
//                FRAMEINFO_t *pFrameHead = (FRAMEINFO_t *)(m_FrameBuf[OldestFrameIndex].pbuf);
//                if (pFrameHead == NULL) {
//                    return 0;
//                }
//
//                m_FrameBuf[OldestFrameIndex].nFrameLength = pFrameHead->nByteNum + sizeof(FRAMEINFO_t);
//
//                unsigned int nFrameType=0;
//                if(pFrameHead->codec_id==MEDIA_CODEC_AUDIO_AAC)
//                {
//                    nFrameType=ANC_FRAME_FLAG_A;
//                }
//                else if(pFrameHead->codec_id==MEDIA_CODEC_AUDIO_G711A)
//                {
//                    nFrameType=ANC_FRAME_FLAG_A;
//                }
//
//                if(pFrameHead->flags == IPC_FRAME_FLAG_IFRAME)
//                    nFrameType=ANC_FRAME_FLAG_VI;
//                else if(pFrameHead->flags == IPC_FRAME_FLAG_PBFRAME)
//                    nFrameType=ANC_FRAME_FLAG_VP;
//
//                m_FrameBuf[OldestFrameIndex].nFrameType = nFrameType;
//
//                if(m_FrameBuf[OldestFrameIndex].nFrameLength >= ANC_MAX_FRAME_LEN)
//                {
//                    printf("GetFrame_Sort: frame length[%ld] is more than limit[%ld]\r\n",m_FrameBuf[OldestFrameIndex].nFrameLength,ANC_MAX_FRAME_LEN);
//                }
//
//                if(((m_FrameBuf[OldestFrameIndex].nFrameType&0x0f) != ANC_FRAME_FLAG_A)&&((m_FrameBuf[OldestFrameIndex].nFrameType&0x0f) != ANC_FRAME_FLAG_REC_A))
//                    m_FrameBuf[OldestFrameIndex].nTimestamp = pFrameHead->timestamp;
//                else
//                    m_FrameBuf[OldestFrameIndex].nTimestamp = pFrameHead->timestamp - 5;
//
//            }
//        }
//        else
//            return ERR_MEM_ALLOC_FAIL;
//    }
//
//    int nAvtiveFrameNum=0;
//    for(i = 0; i < FRAME_NUM_STORE; i ++)
//    {
//        if(m_FrameBuf[i].bUsed == 1)
//            nAvtiveFrameNum++;
//    }
//
//    if( nAvtiveFrameNum >FRAME_NUM_DISPLAY)
//    {
//        return 0;
//    }
//    else
//        return ERR_FRM_NOT_END;
//
//}
//
//int CParser::getOldestFrameIndex()
//{
//    int IFrame_Index=-1;
//    int PFrame_Index=-1;
//    int bak_index=-1;
//    int i;
//    unsigned int nMinPFrameNum = MAX_FRAMENUM;
//    unsigned int nMinIFrameNum = MAX_FRAMENUM;
//
//    for(i = 0; i < FRAME_NUM_STORE; i ++)
//    {
//        if(m_FrameBuf[i].bUsed == 0)
//        {
//            bak_index=i;
//            continue;
//        }
//
//        if(m_FrameBuf[i].nFrameLength == 0)
//        {
//            bak_index=i;
//            continue;
//        }
//
//        if((nMinPFrameNum > m_FrameBuf[i].nFrameNo) && (ANC_FRAME_FLAG_VP == m_FrameBuf[i].nFrameType))
//        {
//            nMinPFrameNum = m_FrameBuf[i].nFrameNo;
//            PFrame_Index = i;
//        }
//
//        if((nMinIFrameNum > m_FrameBuf[i].nFrameNo) && (ANC_FRAME_FLAG_VI == m_FrameBuf[i].nFrameType))
//        {
//            nMinIFrameNum = m_FrameBuf[i].nFrameNo;
//            IFrame_Index = i;
//        }
//
//
//    }
//
//    if((PFrame_Index ==-1) && (IFrame_Index ==-1))
//        return bak_index;
//    else if(PFrame_Index ==-1)
//        return IFrame_Index;
//    else
//        return PFrame_Index;
//}
//
//int CParser::GetDisplayFrameIndex()
//{
//    int i;
//    int index=-1;
//    unsigned int nMinFrameNum = MAX_FRAMENUM;
//
//    for(i = 0; i < FRAME_NUM_STORE; i ++)
//    {
//        if(m_FrameBuf[i].bUsed == 0)
//            continue;
//
//        if(m_FrameBuf[i].nFrameLength == 0)
//            continue;
//
//        if(m_FrameBuf[i].nFrameNo < m_LastFrameNum)
//        {
//            m_FrameBuf[i].bUsed = 0;
//            m_FrameBuf[i].nFrameNo = 0;
//            m_FrameBuf[i].nFrameLength = 0;
//            m_FrameBuf[i].nFrameType = 0;
//            m_FrameBuf[i].nRecvSize = 0;
//            m_FrameBuf[i].nTimestamp = 0;
//        }
//        else if((m_FrameBuf[i].nFrameNo <= nMinFrameNum) && (m_FrameBuf[i].nRecvSize >= m_FrameBuf[i].nFrameLength ))
//        {
//            nMinFrameNum = m_FrameBuf[i].nFrameNo;
//            index=i;
//        }
//    }
//
//    if(nMinFrameNum == MAX_FRAMENUM)
//        return -1;
//    else
//    {
//        return index;
//    }
//}
//
//
//ANC_FRAME_INFO* CParser::ParseFrame()
//{
//    if(!m_bOpened)
//        return NULL;
//
//    if(m_bSort)
//    {
//        int nRet= 0;
//        do {
//            nRet= ParseFrame_Sort();
//        }while(nRet== ERR_GETFRM_MORE);
//
//        if(nRet)
//            return NULL;
//    }
//    else
//    {
//        if(ParseFrame_NSort())
//            return NULL;
//    }
//
//    return (&frame_info);
//}
//
//int CParser::ParseFrame_NSort()
//{
//    if(!m_bOpened)
//        return ERR_NOT_OPEN;
//
//    if(m_FrameLen==0)
//        return ERR_NULL_DATA;
//
//    int err= GetFrameInfo(m_FrameData, (int)m_FrameLen);
//    m_FrameLen = 0;
//    m_gotFrameHead=0;
//    m_gotFrameTail=0;
//    return err;
//}
//
//void CParser::ObsoleteFrame_Sort(int nFrameNumBefore)
//{
//    for(int index = 0; index < FRAME_NUM_STORE; index ++)
//    {
//        if((m_FrameBuf[index].bUsed == 1) &&(m_FrameBuf[index].nFrameNo < nFrameNumBefore))
//        {
//            printf("ObsoleteFrame_Sort: obsolete frame[nFrameType=%d, No=%d, nFrameLength=%d, nRecvSize=%d] !!!\r\n",m_FrameBuf[index].nFrameType,m_FrameBuf[index].nFrameNo,m_FrameBuf[index].nFrameLength,m_FrameBuf[index].nRecvSize);
//
//            m_FrameBuf[index].bUsed = 0;
//            m_FrameBuf[index].nFrameNo = 0;
//            m_FrameBuf[index].nFrameLength = 0;
//            m_FrameBuf[index].nFrameType = 0;
//            m_FrameBuf[index].nRecvSize = 0;
//            m_FrameBuf[index].nTimestamp = 0;
//        }
//    }
//
//}
//
//int CParser::ParseFrame_Sort()
//{
//    int index;
//
//    if(!m_bOpened)
//        return ERR_NOT_OPEN;
//
//    index = GetDisplayFrameIndex();
//    if (index < 0)
//        return ERR_GETFRM_ERR;
//
//    if(m_FrameBuf[index].bUsed == 1)
//    {
//        int err = GetFrameInfo(m_FrameBuf[index].pbuf, (int)m_FrameBuf[index].nFrameLength);
//        if(err==0)
//        {
//            frame_info.nRequence=m_FrameBuf[index].nFrameNo;
//            m_LastFrameNum = m_FrameBuf[index].nFrameNo;
//            ObsoleteFrame_Sort(m_FrameBuf[index].nFrameNo);
//            m_FrameBuf[index].bUsed = 0;
//            m_FrameBuf[index].nFrameNo = 0;
//            m_FrameBuf[index].nFrameLength = 0;
//            m_FrameBuf[index].nFrameType = 0;
//            m_FrameBuf[index].nRecvSize = 0;
//            m_FrameBuf[index].nTimestamp = 0;
//            return 0;
//        }
//        else
//        {
//            m_FrameBuf[index].bUsed = 0;
//            m_FrameBuf[index].nFrameNo = 0;
//            m_FrameBuf[index].nFrameLength = 0;
//            m_FrameBuf[index].nFrameType = 0;
//            m_FrameBuf[index].nRecvSize = 0;
//            m_FrameBuf[index].nTimestamp = 0;
//            return ERR_GETFRM_MORE;
//        }
//    }
//    else
//        return ERR_GETFRM_ERR;
//
//}
//
////typedef struct _FRAMEINFO
////{
////    unsigned short codec_id;    //“Ù ”∆µ±‡Ω‚¬Î∆˜¿‡–Õ
////    unsigned char flags;        //÷°¿‡–Õ£¨I÷°/P÷°/B÷°
////    unsigned char cam_index;    //…„œÒÕ∑–Ú∫≈£¨‘› ±√ª”√µΩ∏√±‰¡ø
////    unsigned char onlineNum;    //µ±«∞‘⁄œﬂª·ª∞ ˝
////    unsigned int  nByteNum;     // ÷°≥§,≤ª∞¸∫¨÷°Õ∑
////    unsigned char reserve1[1];    //±£¡ÙŒª£¨‘› ±√ª”√µΩ∏√±‰¡ø
////    unsigned int reserve2;        // ”∆µ÷ ¡ø≤Œ ˝£¨0£∫∏ﬂ«Â£¨1£∫±Í«Â
////    unsigned int timestamp;        //÷° ±º‰¥¡
////}FRAMEINFO_t;
//
//int CParser::GetFrameInfo(unsigned char* pBuf, int nSize)
//{
//    FRAMEINFO_t  *pFrameHead=(FRAMEINFO_t*)pBuf;
////    if (pFrameHead->flags == 0x01)
//    {
////            printf("GetFrameInfo sss codec_id = %d,flags = %d,cam_index = %d,onlineNum = %d,nByteNum = %d\r\n",pFrameHead->codec_id,pFrameHead->flags,pFrameHead->cam_index,pFrameHead->onlineNum,pFrameHead->nByteNum);
//    }
//
//    int   data_len;
//
//    int nFrameType=0;
//    int nCodecType=0;
//
//    if(pFrameHead->codec_id==MEDIA_CODEC_VIDEO_H264)
//        nCodecType=ANC_CAPTURE_COMP_H264;
//    else if(pFrameHead->codec_id==MEDIA_CODEC_VIDEO_MJPEG)
//        nCodecType=ANC_CAPTURE_COMP_MJPG;
//    else if(pFrameHead->codec_id==MEDIA_CODEC_AUDIO_AAC)
//    {
//        nCodecType=ANC_AUDIO_AAC;
//        nFrameType=ANC_FRAME_FLAG_A;
//    }
//    else if(pFrameHead->codec_id==MEDIA_CODEC_AUDIO_G711A)
//    {
//        nCodecType=ANC_AUDIO_PCM_ALAW;
//        nFrameType=ANC_FRAME_FLAG_A;
//    }
//
//    if(pFrameHead->flags == IPC_FRAME_FLAG_IFRAME)
//        nFrameType=ANC_FRAME_FLAG_VI;
//    else if(pFrameHead->flags == IPC_FRAME_FLAG_PBFRAME)
//        nFrameType=ANC_FRAME_FLAG_VP;
//
//    if(m_bfirstFrm)
//    {
//        if(m_bAllowAudioFirst && (((nFrameType&0x0f) == ANC_FRAME_FLAG_A)  || ((nFrameType&0x0f) ==ANC_FRAME_FLAG_REC_A)))
//        {
//            m_bfirstFrm = false;
//        }
//        else if((nFrameType&0x0f) == ANC_FRAME_FLAG_VI)
//        {
//            printf("GetFrameInfo: I-Frame\r\n");
//            m_bfirstFrm = false;
//        }
//        else
//        {
//           // printf("GetFrameInfo: No I-Frame\r\n");
//            return -1;
//        }
//    }
//
//    if( (((nFrameType&0x0f) == ANC_FRAME_FLAG_VI)  || ((nFrameType&0x0f) ==ANC_FRAME_FLAG_VP))&&(nCodecType!=ANC_CAPTURE_COMP_DIVX_MPEG4)&& (nCodecType!=ANC_CAPTURE_COMP_H264) &&(nCodecType!=ANC_CAPTURE_COMP_MS_MPEG4) ||\
//        (((nFrameType&0x0f) == ANC_FRAME_FLAG_A) || ((nFrameType&0x0f) ==ANC_FRAME_FLAG_REC_A))&&(nCodecType!=ANC_AUDIO_PCM_ULAW)&& (nCodecType!=ANC_AUDIO_G722)&&(nCodecType!=ANC_AUDIO_AAC)&& (nCodecType!=ANC_AUDIO_PCM_ALAW)&& (nCodecType!=ANC_AUDIO_ADPCM))
//    {
//        printf("GetFrameInfo: nCodecType[%x] error\r\n",nCodecType);
//        return -1;
//    }
//
//    if(((nFrameType&0x0f) != ANC_FRAME_FLAG_VI)  && ((nFrameType&0x0f) !=ANC_FRAME_FLAG_VP) &&
//       ((nFrameType&0x0f) != ANC_FRAME_FLAG_A)  && ((nFrameType&0x0f) !=ANC_FRAME_FLAG_REC_A))
//    {
//        printf("GetFrameInfo: nFrameType = %d error\r\n",nFrameType);
//        printf("codec_id = %d,flags = %d,cam_index = %d,onlineNum = %d,nByteNum = %d\r\n",pFrameHead->codec_id,pFrameHead->flags,pFrameHead->cam_index,pFrameHead->onlineNum,pFrameHead->nByteNum);
//        return -1;
//    }
//
//
//    data_len = nSize-sizeof(FRAMEINFO_t);
//
//    frame_info.pHeader = pBuf;
//    frame_info.pContent = pBuf+(nSize-data_len);
//    frame_info.nLength = nSize;
//    frame_info.nFrameLength = data_len;
//
//    if(((nFrameType&0x0f) == ANC_FRAME_FLAG_A)||((nFrameType&0x0f) == ANC_FRAME_FLAG_REC_A))
//       {
//           frame_info.nType = ANC_FRAME_TYPE_AUDIO;
//        if((nFrameType&0x0f) == ANC_FRAME_FLAG_A)
//           {
//               frame_info.nSubType = ANC_FRAME_TYPE_AUDIO_LIVE;
//        }
//        else
//               frame_info.nSubType = ANC_FRAME_TYPE_AUDIO_REC;
//    }
//       else if((nFrameType&0x0f) == ANC_FRAME_FLAG_VI)
//       {
//        if( nCodecType ==ANC_CAPTURE_COMP_DIVX_MPEG4)
//               frame_info.nEncodeType = ANC_STREAM_MPEG4;
//        else if(nCodecType ==ANC_CAPTURE_COMP_H264)
//               frame_info.nEncodeType = ANC_STREAM_H264;
//        else if(nCodecType ==ANC_CAPTURE_COMP_MS_MPEG4)
//               frame_info.nEncodeType = ANC_STREAM_HIK;
//
//
//           frame_info.nType = ANC_FRAME_TYPE_VIDEO;
//           frame_info.nSubType = ANC_FRAME_TYPE_VIDEO_I_FRAME;
//
//       }
//    else if((nFrameType&0x0f) == ANC_FRAME_FLAG_VP)
//       {
//        if( nCodecType ==ANC_CAPTURE_COMP_DIVX_MPEG4)
//               frame_info.nEncodeType = ANC_STREAM_MPEG4;
//        else if(nCodecType ==ANC_CAPTURE_COMP_H264)
//               frame_info.nEncodeType = ANC_STREAM_H264;
//        else if(nCodecType ==ANC_CAPTURE_COMP_MS_MPEG4)
//               frame_info.nEncodeType = ANC_STREAM_HIK;
//
//           frame_info.nType = ANC_FRAME_TYPE_VIDEO;
//           frame_info.nSubType = ANC_FRAME_TYPE_VIDEO_P_FRAME;
//    }
//    else
//       {
//        if( nCodecType ==ANC_CAPTURE_COMP_DIVX_MPEG4)
//               frame_info.nEncodeType = ANC_STREAM_MPEG4;
//        else if(nCodecType ==ANC_CAPTURE_COMP_H264)
//               frame_info.nEncodeType = ANC_STREAM_H264;
//        else if(nCodecType ==ANC_CAPTURE_COMP_MS_MPEG4)
//               frame_info.nEncodeType = ANC_STREAM_HIK;
//
//           frame_info.nType = ANC_FRAME_TYPE_VIDEO;
//           frame_info.nSubType = ANC_FRAME_TYPE_VIDEO_B_FRAME;
//    }
//
//    if((nCodecType==ANC_AUDIO_PCM_ULAW) || (nCodecType==ANC_AUDIO_PCM_ALAW) || (nCodecType==ANC_AUDIO_ADPCM))
//    {
//        frame_info.nChannels=1;
//        frame_info.nBitsPerSample=16;
//        frame_info.nSamplesPerSecond=8000;
//    }
//
//    frame_info.nTimeStamp = pFrameHead->timestamp;
//
///*
//    {
//        char buf[128];
//        sprintf(buf,"[%d-%d-%d:%d-%d-%d] headsize=%d, current_secs=%d, nFrameSeq=%d, nType=%d nSubType=%d size=%d\r\n", frame_info.nYear, frame_info.nMonth, frame_info.nDay,frame_info.nHour,frame_info.nMinute,frame_info.nSecond,sizeof(ANC_FRAME_HEAD),current_secs,pFrameHead->nFrameSeq,frame_info.nType,frame_info.nSubType,frame_info.nFrameLength);
//        OutputDebugString(buf);
//    }
//*/
//
//    return 0;
//}
//
//int CParser::Reset()
//{
//    m_bfirstFrm = true;
//    m_expPacketNo=-1;
//    m_expFrameNo =-1;
//
//    memset(&frame_info,0x00,sizeof(frame_info));
//
//    if(!m_bSort)
//    {
//        m_FrameLen = 0;
//        m_gotFrameHead=0;
//        m_gotFrameTail=0;
//    }
//    else
//    {
//        m_LastFrameNum = 0;
//        for(int i  = 0; i < FRAME_NUM_STORE; i++)
//        {
//            m_FrameBuf[i].bUsed = 0;
//            m_FrameBuf[i].nFrameNo = 0;
//            m_FrameBuf[i].nFrameType = 0;
//            m_FrameBuf[i].nFrameLength = 0;
//            m_FrameBuf[i].nRecvSize = 0;
//            m_FrameBuf[i].nTimestamp = 0;
//        }
//    }
//    return 0;
//}
//
//PARSERHANDLE ANC_SP_Init(ANC_SP_CALLBACK sp_cb, unsigned long nUser, bool bAllowAudioFirst,bool bSort)
//{
//    CParser *parser = new CParser(sp_cb, nUser,bSort);
//    if(!parser)
//        return (PARSERHANDLE)NULL;
//
//    if(parser->Open((bool)bAllowAudioFirst))
//    {
//        delete parser;
//        return (PARSERHANDLE)NULL;
//    }
//
//    return (PARSERHANDLE)parser;
//}
//
//int ANC_SP_Free(PARSERHANDLE hHandle)
//{
//    CParser *parser = (CParser *)hHandle;
//    if(!parser)
//        return -1;
//
//    parser->Close();
//    delete parser;
//
//    return 0;
//}
//
//int ANC_SP_InputData(PARSERHANDLE hHandle, unsigned char *byData, unsigned int dwLength)
//{
//    CParser *parser = (CParser *)hHandle;
//    if(!parser)
//        return -1;
//    return parser->GetFrame(byData,dwLength);
//}
//
//ANC_FRAME_INFO *ANC_SP_GetNextFrame(PARSERHANDLE hHandle)
//{
//    CParser *parser = (CParser *)hHandle;
//    if(!parser)
//        return NULL;
//
//       return parser->ParseFrame();
//}
//
//ANC_FRAME_INFO *ANC_SP_GetNextKeyFrame(PARSERHANDLE hHandle)
//{
//    ANC_FRAME_INFO *pFrame_Info;
//
//    CParser *parser = (CParser *)hHandle;
//    if(!parser)
//        return NULL;
//
//    pFrame_Info = parser->ParseFrame();
//    if(!pFrame_Info)
//        return NULL;
//
//    if(pFrame_Info->nSubType ==ANC_FRAME_TYPE_VIDEO_I_FRAME)
//        return pFrame_Info;
//    else
//        return NULL;
//}
//
//void ANC_SP_Reset(PARSERHANDLE hHandle, int nFlag)
//{
//    CParser *parser = (CParser *)hHandle;
//    if(!parser)
//        return;
//
//    parser->Reset();
//}
//
