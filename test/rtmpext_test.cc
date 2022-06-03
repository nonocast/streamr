#include <gtest/gtest.h>
extern "C" {
#include "../src/bridge.h"
#include <librtmp/log.h>
}

typedef uint8_t byte;

namespace {
class RTMPExtTest : public testing::Test {
protected:
  void SetUp() override {
    RTMP_LogSetLevel(RTMP_LOGALL);
  }
};

TEST_F(RTMPExtTest, nalu_tag) {
  // int32_t timestamp = 0x0002aa00;
  int32_t timestamp = 0x0002aa01;

  size_t nalu_size = 10;
  byte nalu[nalu_size];
  memset(nalu, 0x00, nalu_size);
  nalu[0] = 0x1f;
  nalu[1] = 0xcf;
  nalu[nalu_size - 1] = 0xff;

  size_t buffer_size = nalu_size + 20;
  byte buffer[buffer_size];
  memset(buffer, 0x00, buffer_size);

  size_t expected_header_size = 16;
  const byte expected_header[] = {0x09, 0x00, 0x00, 0x13, 0x02, 0xaa, 0x01, 0x00, 0x00, 0x00, 0x00, 0x17, 0x01, 0x00, 0x00, 0x00};
  int count = RTMPEXT_MakeVideoNALUTag(timestamp, nalu, nalu_size, buffer, buffer_size);
  EXPECT_EQ(count, nalu_size + 4 + expected_header_size);

  // RTMP_LogHex(RTMP_LOGINFO, expected_header, expected_header_size);
  // RTMP_LogHex(RTMP_LOGINFO, buffer, expected_header_size);
  EXPECT_EQ(memcmp(buffer, expected_header, expected_header_size), 0);
  EXPECT_EQ(memcmp(buffer + 20, nalu, nalu_size), 0);
}

/*
 * 09 00 00 23 02 0f 58 00 00 00 00 17 00 00 00 00
 * 01 4d 00 15 ff e1 00 0f 27 4d 00 15 ab 61 a3 7c
 * b2 cd 40 40 40 40 80 01 00 04 28 ee 3c 80
 */
TEST_F(RTMPExtTest, video_meta_tag) {
  GTEST_SKIP();

  size_t sps_size = 15;
  const byte sps[] = {0x27, 0x4d, 0x00, 0x15, 0xab, 0x61, 0xa3, 0x7c, 0xb2, 0xcd, 0x40, 0x40, 0x40, 0x40, 0x80};

  size_t pps_size = 4;
  const byte pps[] = {0x28, 0xee, 0x3c, 0x80};

  size_t buffer_size = 512;
  byte buffer[buffer_size];
  memset(buffer, 0, buffer_size);
  buffer[0] = 0x01;

  size_t expected_size = 46;
  const byte expected[] = {0x09, 0x00, 0x00, 0x23, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x17, 0x00, 0x00, 0x00, 0x00, 0x01, 0x4d, 0x00, 0x15, 0xff, 0xe1, 0x00,
                           0x0f, 0x27, 0x4d, 0x00, 0x15, 0xab, 0x61, 0xa3, 0x7c, 0xb2, 0xcd, 0x40, 0x40, 0x40, 0x40, 0x80, 0x01, 0x00, 0x04, 0x28, 0xee, 0x3c, 0x80};

  int32_t result_size = RTMPEXT_MakeVideoMetadataTag(sps, sps_size, pps, pps_size, buffer, buffer_size);
  RTMP_LogHex(RTMP_LOGINFO, buffer, expected_size);

  EXPECT_EQ(result_size, expected_size);
  EXPECT_EQ(memcmp(buffer, expected, expected_size), 0);
}

/*
 * 01 4d 00 15 ff e1 00 0f 27 4d 00 15 ab 61 a3 7c
 * b2 cd 40 40 40 40 80 01 00 04 28 ee 3c 80
 */
TEST_F(RTMPExtTest, avcheader) {
  GTEST_SKIP();

  size_t sps_size = 15;
  const byte sps[] = {0x27, 0x4d, 0x00, 0x15, 0xab, 0x61, 0xa3, 0x7c, 0xb2, 0xcd, 0x40, 0x40, 0x40, 0x40, 0x80};

  size_t pps_size = 4;
  const byte pps[] = {0x28, 0xee, 0x3c, 0x80};

  size_t buffer_size = 512;
  byte buffer[buffer_size];
  memset(buffer, 0, buffer_size);
  buffer[0] = 0x01;

  size_t expected_size = 30;
  const byte expected[] = {0x01, 0x4d, 0x00, 0x15, 0xff, 0xe1, 0x00, 0x0f, 0x27, 0x4d, 0x00, 0x15, 0xab, 0x61, 0xa3,
                           0x7c, 0xb2, 0xcd, 0x40, 0x40, 0x40, 0x40, 0x80, 0x01, 0x00, 0x04, 0x28, 0xee, 0x3c, 0x80};

  int32_t result_size = RTMPEXT_MakeAVCDecoderConfigurationRecord(sps, sps_size, pps, pps_size, buffer, buffer_size);

  RTMP_LogHex(RTMP_LOGINFO, buffer, expected_size);

  EXPECT_EQ(result_size, expected_size);
  EXPECT_EQ(memcmp(buffer, expected, expected_size), 0);
}
} // namespace