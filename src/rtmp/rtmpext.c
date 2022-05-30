#include <librtmp/log.h>
#include <librtmp/rtmp.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

void RTMPEXT_Open(RTMP *rtmp) {
  char *url = "rtmp://shgbit.xyz/app/x";

  if (RTMP_SetupURL(rtmp, url) < 0) {
    RTMP_Log(RTMP_LOGERROR, "RTMP_SetupURL FAILED: %s", url);
  }

  RTMP_EnableWrite(rtmp);

  if (RTMP_Connect(rtmp, NULL) < 0) {
    RTMP_Log(RTMP_LOGERROR, "Connect FAILED: %s", url);
  }

  if (RTMP_ConnectStream(rtmp, 0) < 0) {
    RTMP_Log(RTMP_LOGERROR, "ConnectStream FAILED");
  }
}

size_t RTMPEXT_MakeAVCDecoderConfigurationRecord(const uint8_t *sps, size_t sps_size, const uint8_t *pps, size_t pps_size, uint8_t *buffer, size_t buffer_size) {
  uint8_t *p = buffer;

  // byte 1: version
  *p++ = 0x01;

  // byte 2-4: sps 1-3
  for (int i = 0; i < 3; ++i) {
    *p++ = *(sps + 1 + i);
  }

  // byte 5
  *p++ = 0xff;
  // byte 6: 低4位表示sps num
  *p++ = 0xe1;

  // byte 7-8: sps_size
  // pps_size: 0x0f (15): 0f 00 00 00 00 00 00 00
  uint8_t *sps_size_ptr = (uint8_t *) &sps_size;
  *p++ = *(sps_size_ptr + 1);
  *p++ = *sps_size_ptr;

  // byte 9-(9+sps_size): sps
  for (int i = 0; i < sps_size; ++i) {
    *p++ = *(sps + i);
  }

  // byte (9+sps_size+1): pps num
  *p++ = 0x01;

  uint8_t *pps_size_ptr = (uint8_t *) &pps_size;
  *p++ = *(pps_size_ptr + 1);
  *p++ = *pps_size_ptr;

  // byte (9+sps_size+2 - 9+sps_size+2+pps_size)
  for (int i = 0; i < pps_size; ++i) {
    *p++ = *(pps + i);
  }
  return p - buffer;
}

/*
 * flv tag header (11 bytes: fixed)
 * video tag (VIDEODATA) header (1 byte, 0x17, FrameType UB4 - CodecID UB4)
 * AVCVIDEOPACKET
 *   - header (4 bytes):
 *       - AVCPacketType UI8 AVC sequence header (0)
 *       - CompositionTime SI24 0
 *   - AVCDecoderConfigrationRecord
 */
size_t RTMPEXT_MakeVideoMetadataTag(const uint8_t *sps, size_t sps_size, const uint8_t *pps, size_t pps_size, uint8_t *buffer, size_t buffer_size) {
  uint8_t *p = buffer;

  size_t record_size = RTMPEXT_MakeAVCDecoderConfigurationRecord(sps, sps_size, pps, pps_size, buffer + 16, buffer_size);

  // byte 1: type
  *p++ = 0x09;

  // byte 2-4: data size
  size_t data_size = record_size + 5;
  uint8_t *data_size_ptr = (uint8_t *) &data_size;
  *p++ = *(data_size_ptr + 2);
  *p++ = *(data_size_ptr + 1);
  *p++ = *data_size_ptr;

  // byte 5-8: timestamp+ext
  *p++ = 0x00;
  *p++ = 0x00;
  *p++ = 0x00;
  *p++ = 0x00;

  // byte 9-11: streamid
  *p++ = 0x00;
  *p++ = 0x00;
  *p++ = 0x00;

  // byte 12: Video tag (VIDEODATA) header
  *p++ = 0x17;

  // byte 13: AVCVIDEOPACKET - type
  *p++ = 0;

  // byte 14-16
  *p++ = 0x00;
  *p++ = 0x00;
  *p++ = 0x00;

  p += record_size;

  return p - buffer;
}

/*
 * flv tag header (11 bytes)
 * video tag header (1 byte) 0x17 or 0x27
 * AVCVIDEOPACKET header (4 bytes) AVCPacketType==AVC NALU, CompoistionTime
 */
size_t RTMPEXT_MakeVideoNALUTag(const int32_t timestamp, const uint8_t *nalu, size_t nalu_length, uint8_t *buffer, size_t buffer_size) {
  uint8_t *p = buffer;
  // byte 1: video (9)
  *p++ = 0x09;
  // byte 2-4: data size
  size_t len = nalu_length + 5;
  uint8_t *data_size_ptr = (uint8_t *) &len;
  *p++ = *(data_size_ptr + 2);
  *p++ = *(data_size_ptr + 1);
  *p++ = *data_size_ptr;

  // timestamp: 4
  RTMP_LogHex(RTMP_LOGINFO, &timestamp, sizeof(timestamp));

  uint8_t *timestamp_ptr = (uint8_t *) &timestamp;
  *p++ = *(timestamp_ptr + 2);
  *p++ = *(timestamp_ptr + 1);
  *p++ = *timestamp_ptr;
  *p++ = *(timestamp_ptr + 3);

  RTMP_LogHex(RTMP_LOGINFO, p - 4, 4);

  // *p++ = 0x00;
  // *p++ = 0x00;
  // *p++ = 0x01;
  // *p++ = 0x00;

  // stream id: 3
  *p++ = 0;
  *p++ = 0;
  *p++ = 0;

  // VIDEODATA header: 1
  *p++ = 0x17;

  // AVCVIDEOPACKET: 4
  *p++ = 0x01; // AVC NALU

  // composition time
  *p++ = 0;
  *p++ = 0;
  *p++ = 0;

  memcpy(buffer + 16, nalu, nalu_length);
  p += nalu_length;
  return p - buffer;
}