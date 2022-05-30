#include "librtmp/amf.h"
#include "librtmp/log.h"
#include "librtmp/rtmp.h"

void RTMPEXT_Open(RTMP *rtmp);

size_t RTMPEXT_MakeVideoNALUTag(const int32_t timestamp, const uint8_t *nalu, size_t nalu_length, uint8_t *buffer, size_t buffer_size);

size_t RTMPEXT_MakeVideoMetadataTag(const uint8_t *sps, size_t sps_size, const uint8_t *pps, size_t pps_size, uint8_t *buffer, size_t buffer_size);

size_t RTMPEXT_MakeAVCDecoderConfigurationRecord(const uint8_t *sps, size_t sps_size, const uint8_t *pps, size_t pps_size, uint8_t *buffer, size_t buffer_size);