#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//version 1.0 (20050707)
//by shevious
//Thanks to thakis for yaz0dec 1.0.

typedef unsigned char u8;
typedef unsigned int u32;

#define MAX_RUNLEN (0xFF + 0x12)

// simple and straight encoding scheme for Yaz0
static u32 simpleEnc(u8 *src, int size, int pos, u32 *pMatchPos)
{
	int startPos = pos - 0x1000;
	int i, j;
	u32 numBytes = 1;
	u32 matchPos = 0;

	int end = size - pos;
	// maximum runlength for 3 byte encoding
	if (end > MAX_RUNLEN)
		end = MAX_RUNLEN;

	if (startPos < 0)
		startPos = 0;
	for (i = startPos; i < pos; i++) {
		for (j = 0; j < end; j++) {
			if (src[i + j] != src[j + pos])
				break;
		}
		if (j > numBytes) {
			numBytes = j;
			matchPos = i;
		}
	}

	*pMatchPos = matchPos;

	if (numBytes == 2)
		numBytes = 1;

	return numBytes;
}

// a lookahead encoding scheme for ngc Yaz0
static u32 nintendoEnc(u8 *src, int size, int pos, u32 *pMatchPos)
{
	u32 numBytes = 1;
	static u32 numBytes1;
	static u32 matchPos;
	static int prevFlag = 0;

	// if prevFlag is set, it means that the previous position
	// was determined by look-ahead try.
	// so just use it. this is not the best optimization,
	// but nintendo's choice for speed.
	if (prevFlag == 1) {
		*pMatchPos = matchPos;
		prevFlag = 0;
		return numBytes1;
	}

	prevFlag = 0;
	numBytes = simpleEnc(src, size, pos, &matchPos);
	*pMatchPos = matchPos;

	// if this position is RLE encoded, then compare to copying 1 byte and next position(pos+1) encoding
	if (numBytes >= 3) {
		numBytes1 = simpleEnc(src, size, pos + 1, &matchPos);
		// if the next position encoding is +2 longer than current position, choose it.
		// this does not guarantee the best optimization, but fairly good optimization with speed.
		if (numBytes1 >= numBytes + 2) {
			numBytes = 1;
			prevFlag = 1;
		}
	}
	return numBytes;
}

static int encodeYaz0(u8 *src, u8 *dst, int srcSize)
{
	int srcPos = 0;
	int dstPos = 0;
	int bufPos = 0;

	u8 buf[24]; // 8 codes * 3 bytes maximum

	u32 validBitCount = 0; // number of valid bits left in "code" byte
	u8 currCodeByte = 0;

	while (srcPos < srcSize) {
		u32 numBytes;
		u32 matchPos;

		numBytes = nintendoEnc(src, srcSize, srcPos, &matchPos);
		if (numBytes < 3) {
			// straight copy
			buf[bufPos] = src[srcPos];
			bufPos++;
			srcPos++;
			//set flag for straight copy
			currCodeByte |= (0x80 >> validBitCount);
		} else {
			//RLE part
			u32 dist = srcPos - matchPos - 1;
			u8 byte1, byte2, byte3;

			if (numBytes >= 0x12) { // 3 byte encoding
				byte1 = 0 | (dist >> 8);
				byte2 = dist & 0xFF;
				buf[bufPos++] = byte1;
				buf[bufPos++] = byte2;
				// maximum runlength for 3 byte encoding
				if (numBytes > MAX_RUNLEN)
					numBytes = MAX_RUNLEN;
				byte3 = numBytes - 0x12;
				buf[bufPos++] = byte3;
			} else { // 2 byte encoding
				byte1 = ((numBytes - 2) << 4) | (dist >> 8);
				byte2 = dist & 0xFF;
				buf[bufPos++] = byte1;
				buf[bufPos++] = byte2;
			}
			srcPos += numBytes;
		}

		validBitCount++;

		// write eight codes
		if (validBitCount == 8) {
			dst[dstPos++] = currCodeByte;
			for (int j = 0; j < bufPos; j++)
				dst[dstPos++] = buf[j];

			currCodeByte = 0;
			validBitCount = 0;
			bufPos = 0;
		}
	}

	if (validBitCount > 0) {
		dst[dstPos++] = currCodeByte;
		for (int j = 0; j < bufPos; j++)
			dst[dstPos++] = buf[j];

		currCodeByte = 0;
		validBitCount = 0;
		bufPos = 0;
	}

	return dstPos;
}

void decompress(u8 *src, u8 *dst, int uncompressedSize)
{
	int srcPlace = 0, dstPlace = 0; // current read/write positions

	u32 validBitCount = 0; // number of valid bits left in "code" byte
	u8 currCodeByte = 0;

	while (dstPlace < uncompressedSize) {
		// read new "code" byte if the current one is used up
		if (validBitCount == 0) {
			currCodeByte = src[srcPlace];
			++srcPlace;
			validBitCount = 8;
		}

		if ((currCodeByte & 0x80) != 0) {
			// straight copy
			dst[dstPlace] = src[srcPlace];
			dstPlace++;
			srcPlace++;
		} else {
			// RLE part
			u8 byte1 = src[srcPlace];
			u8 byte2 = src[srcPlace + 1];
			srcPlace += 2;

			u32 dist = ((byte1 & 0xF) << 8) | byte2;
			u32 copySource = dstPlace - (dist + 1);

			u32 numBytes = byte1 >> 4;
			if (numBytes == 0) {
				numBytes = src[srcPlace] + 0x12;
				srcPlace++;
			} else {
				numBytes += 2;
			}

			// copy run
			int i;
			for(i = 0; i < numBytes; ++i) {
				dst[dstPlace] = dst[copySource];
				copySource++;
				dstPlace++;
			}
		}

		// use next bit from "code" byte
		currCodeByte <<= 1;
		validBitCount--;
	}
}

int main(int argc, char *argv[])
{
	for (int i = 1; i < argc; i++) {
		FILE *f = fopen(argv[i], "rb");

		if (f == NULL) {
			perror(argv[1]);
			exit(1);
		}

		fseek(f, 0, SEEK_END);
		long size = ftell(f);
		fseek(f, 0, SEEK_SET);

		u8 *bufi = malloc(size);
		fread(bufi, 1, size, f);

		fclose(f);

		if (size > 0x10
			&& bufi[0] == 'Y'
			&& bufi[1] == 'a'
			&& bufi[2] == 'z'
			&& bufi[3] == '0') {
			long usize = (bufi[4] << 24)
				| (bufi[5] << 16)
				| (bufi[6] << 8)
				| bufi[7];
			u8 *bufo = malloc(usize);
			decompress(bufi + 16, bufo, usize);
			fwrite(bufo, usize, 1, stdout);
			free(bufo);
		} else {
			// we don't know how big the "compressed" file could get,
			// so over-allocate!
			// modern systems have more RAM than the largest Yaz0 file, so...
			u8 *bufo = malloc(size * 2);

			// write 4 bytes yaz0 header
			bufo[0] = 'Y';
			bufo[1] = 'a';
			bufo[2] = 'z';
			bufo[3] = '0';

			// write 4 bytes uncompressed size
			bufo[4] = (size >> 24) & 0xFF;
			bufo[5] = (size >> 16) & 0xFF;
			bufo[6] = (size >> 8) & 0xFF;
			bufo[7] = (size >> 0) & 0xFF;

			// write 8 bytes unused dummy
			bufo[8] = 0;
			bufo[9] = 0;
			bufo[10] = 0;
			bufo[11] = 0;
			bufo[12] = 0;
			bufo[13] = 0;
			bufo[14] = 0;
			bufo[15] = 0;

			long csize = encodeYaz0(bufi, bufo + 16, size) + 16;

			fwrite(bufo, csize, 1, stdout);
			free(bufo);
		}
		free(bufi);
	}
}
