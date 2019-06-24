#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//version 1.0 (20050707) by shevious
//Thanks to thakis for yaz0dec 1.0.

#define lament(...) fprintf(stderr, __VA_ARGS__)
#define error_when(cond, ...) do { \
        if ((cond) || errno) { \
            lament(__VA_ARGS__); \
            lament(": %s\n", strerror(errno)); \
            goto error; \
        } \
    } while (0)

typedef unsigned char u8;

enum {
    max_runlen = 0xFF + 0x12
};

// simple and straight encoding scheme for Yaz0
static long
simpleEnc(u8 *src, int size, int pos, long *pMatchPos)
{
    int startPos = pos - 0x1000;
    long numBytes = 1;
    long matchPos = 0;

    int end = size - pos;
    // maximum runlength for 3 byte encoding
    if (end > max_runlen)
        end = max_runlen;

    if (startPos < 0)
        startPos = 0;
    for (int i = startPos; i < pos; i++) {
        int j;
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
static long
nintendoEnc(u8 *src, int size, int pos, long *pMatchPos)
{
    long numBytes = 1;
    static long numBytes1;
    static long matchPos;
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

static int
encodeYaz0(u8 *src, u8 *dst, int srcSize)
{
    int srcPos = 0;
    int dstPos = 0;
    int bufPos = 0;

    u8 buf[24]; // 8 codes * 3 bytes maximum

    long validBitCount = 0; // number of valid bits left in "code" byte
    u8 currCodeByte = 0; // a bitfield, set bits meaning copy, unset meaning RLE

    while (srcPos < srcSize) {
        long numBytes;
        long matchPos;

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
            long dist = srcPos - matchPos - 1;
            u8 byte1, byte2, byte3;

            if (numBytes >= 0x12) { // 3 byte encoding
                byte1 = 0 | (dist >> 8);
                byte2 = dist & 0xFF;
                buf[bufPos++] = byte1;
                buf[bufPos++] = byte2;
                // maximum runlength for 3 byte encoding
                if (numBytes > max_runlen)
                    numBytes = max_runlen;
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

static void
decompress(u8 *src, u8 *dst, int uncompressedSize)
{
    int srcPlace = 0, dstPlace = 0; // current read/write positions

    long validBitCount = 0; // number of valid bits left in "code" byte
    u8 currCodeByte = 0;

    while (dstPlace < uncompressedSize) {
        // read new "code" byte if the current one is used up
        if (validBitCount == 0) {
            currCodeByte = src[srcPlace++];
            validBitCount = 8;
        }

        if ((currCodeByte & 0x80) != 0) {
            // straight copy
            dst[dstPlace++] = src[srcPlace++];
        } else {
            // RLE part
            u8 byte1 = src[srcPlace++];
            u8 byte2 = src[srcPlace++];

            long dist = ((byte1 & 0xF) << 8) | byte2;
            long copySource = dstPlace - (dist + 1);

            long numBytes = byte1 >> 4;
            if (numBytes == 0) {
                numBytes = src[srcPlace++] + 0x12;
            } else {
                numBytes += 2;
            }

            // copy run
            for(int i = 0; i < numBytes; ++i) {
                dst[dstPlace++] = dst[copySource++];
            }
        }

        // use next bit from "code" byte
        currCodeByte <<= 1;
        validBitCount--;
    }
}

int
process(const char *fpi, const char *fpo)
{
    u8 *bufi = NULL;
    u8 *bufo = NULL;
    FILE *fi = NULL;
    FILE *fo = NULL;
    long isize;
    long csize;
    long outsize;
    long i;

    fi = fopen(fpi, "rb");
    error_when(fi == NULL, "Error opening file for reading: %s", fpi);

    error_when(fseek(fi, 0, SEEK_END) != 0, "Error seeking in file: %s", fpi);
    isize = ftell(fi);
    error_when(isize < 0, "Error telling in file: %s", fpi);
    error_when(fseek(fi, 0, SEEK_SET) != 0, "Error seeking in file: %s", fpi);

    if (isize > 0) {
        bufi = malloc(isize);
        error_when(bufi == NULL, "Error allocating %li bytes", isize);
        error_when(fread(bufi, 1, isize, fi) != (size_t)isize,
                   "Error reading %li bytes from file: %s", isize, fpi);
    }

    error_when(fclose(fi) != 0, "Error closing file: %s", fpi);

    if (isize < 5) {
        // FIXME: encodeYaz0 segfaults in this case.
        lament("Error: input file must be at least 5 bytes.\n");
        goto error;
    }

    if (isize > 0x10
        && bufi[0] == 'Y'
        && bufi[1] == 'a'
        && bufi[2] == 'z'
        && bufi[3] == '0') {
        outsize = (bufi[4] << 24)
                | (bufi[5] << 16)
                | (bufi[6] << 8)
                |  bufi[7];
        bufo = malloc(outsize);
        error_when(bufo == NULL, "Error allocating %li bytes", outsize);
        decompress(bufi + 16, bufo, outsize);

    } else {
        // we don't know how big the "compressed" file could get,
        // so over-allocate!
        // modern systems have more RAM than the largest Yaz0 file, so...
        csize = 0x10 + isize * 2;
        bufo = malloc(csize);
        error_when(bufo == NULL, "Error allocating %li bytes", csize);

        // write 4 bytes yaz0 header
        bufo[0] = 'Y';
        bufo[1] = 'a';
        bufo[2] = 'z';
        bufo[3] = '0';

        // write 4 bytes uncompressed size
        bufo[4] = (isize >> 24) & 0xFF;
        bufo[5] = (isize >> 16) & 0xFF;
        bufo[6] = (isize >> 8) & 0xFF;
        bufo[7] = (isize >> 0) & 0xFF;

        // write 8 bytes unused dummy
        bufo[8] = 0;
        bufo[9] = 0;
        bufo[10] = 0;
        bufo[11] = 0;
        bufo[12] = 0;
        bufo[13] = 0;
        bufo[14] = 0;
        bufo[15] = 0;

        csize = encodeYaz0(bufi, bufo + 16, isize) + 16;

        // pad compressed file to be a multiple of 16 bytes.
        outsize = (csize + 15) & ~0xF;
        for (i = csize; i < outsize; i++) bufo[i] = 0;
    }

    fo = fopen(fpo, "wb");
    error_when(fo == NULL, "Error opening file for writing: %s", fpo);
    error_when(fwrite(bufo, 1, outsize, fo) != (size_t)outsize,
               "Error writing %li bytes to file: %s", outsize, fpo);
    error_when(fclose(fo) != 0, "Error closing file: %s", fpo);

    free(bufi);
    free(bufo);
    return 0;

error:
    if (bufi != NULL) free(bufi);
    if (bufo != NULL) free(bufo);
    if (fi != NULL) fclose(fi);
    if (fo != NULL) fclose(fo);
    return 1;
}

int
main(int argc, char *argv[])
{
    if (argc <= 0 || argv == NULL || argv[0] == NULL) {
        lament("You've met with a terrible fate.\n");
        return 1;
    }

    if (argc != 3) {
        lament("usage: %s {input file} {output file}\n", argv[0]);
        return 1;
    }

    return process(argv[1], argv[2]);
}
