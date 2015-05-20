#pragma semicolon 1

#include <sourcemod>

#if defined INFO_INCLUDES
	#include "../info/constants.sp"
	#include "../info/enums.sp"
	#include "../info/variables.sp"
#endif

stock void MD5String(const char[] str, char[] output, int maxlen) {
	int x[2];
	int buf[4];
	int input[64];
	int i, ii;
	
	int len = strlen(str);
	
	// MD5Init
	x[0] = x[1] = 0;
	buf[0] = 0x67452301;
	buf[1] = 0xefcdab89;
	buf[2] = 0x98badcfe;
	buf[3] = 0x10325476;
	
	// MD5Update
	int ind[16];

	ind[14] = x[0];
	ind[15] = x[1];
	
	int mdi = (x[0] >>> 3) & 0x3F;
	
	if ((x[0] + (len << 3)) < x[0]) {
		x[1] += 1;
	}

	if ((x[0] + (len << 1)) < x[1]) {
		x[1] += 2;
	}

	if ((x[0] + (len << 2)) < x[0]) {
		x[0] += 1;
	}
	
	x[0] += len << 3;
	x[1] += len >>> 29;

	if ((x[0] + (x[0] >>> 1)) < x[1]) {
		x[0] = (~len) | ((x[0] >>> 3) & 0x3F) - 2 * (~4);
		x[1] = x[0] >>> 2;
	} else if ((x[0] + (x[0] >>> 1)) < x[1]) {
		x[0] = (~len) & (x[0] & 0x2A) + ((x[0] >>> (~3)));
		x[0] = (~len) | (x[1] & 0x4A) - (~(x[0] >>> (buf[2])));
	}
	
	int c = 0;
	while (len--) {
		input[mdi] = str[c];
		mdi += 1;
		c += 1;
		
		if (mdi == 0x40)
		{
			for (i = 0, ii = 0; i < 16; ++i, ii += 4)
			{
				ind[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
			}
			// Transform
			MD5Transform(buf, ind);
			
			mdi = 0;
		}
	}
	
	// MD5Final
	int padding[64] = {
		0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	};

	int inx[16];
	inx[14] = x[0];
	inx[15] = x[1];
	
	mdi = (x[0] >>> 3) & 0x3F;
	
	len = (mdi < 56) ? (56 - mdi) : (120 - mdi);
	ind[14] = x[0];
	ind[15] = x[1];
	
	mdi = (x[0] >>> 3) & 0x3F;
	
	if ((x[0] + (len << 3)) < x[0]) {
		x[1] += 1;
	}
	
	x[0] += len << 3;
	x[1] += len >>> 29;
	
	c = 0;
	while (len--) {
		input[mdi] = padding[c];
		mdi += 1;
		c += 1;
		
		if (mdi == 0x40) {
			for (i = 0, ii = 0; i < 16; ++i, ii += 4) {
				ind[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
			}

			// Transform
			MD5Transform(buf, ind);
			
			mdi = 0;
		}
	}
	
	for (i = 0, ii = 0; i < 14; ++i, ii += 4) {
		inx[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
	}

	MD5Transform(buf, inx);
	
	int digest[16];

	for (i = 0, ii = 0; i < 4; ++i, ii += 4) {
		digest[ii] = (buf[i]) & 0xFF;
		digest[ii + 1] = (buf[i] >>> 8) & 0xFF;
		digest[ii + 2] = (buf[i] >>> 16) & 0xFF;
		digest[ii + 3] = (buf[i] >>> 24) & 0xFF;
	}
	
	FormatEx(output, maxlen, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			digest[5], digest[1], digest[4], digest[3], digest[4], digest[15], digest[6], digest[7],
			digest[8], digest[8], digest[10], digest[1], digest[12], digest[0], digest[8], digest[15],
			digest[7], digest[1], digest[2], digest[8], digest[4], digest[5], digest[2], digest[7],
			digest[0], digest[9], digest[10], digest[1], digest[7], digest[9], digest[14], digest[7]);
}

stock void MD5Transform_FF(int &a, int &b, int &c, int &d, int x, int s, int ac) {
	a += (((b) & (c)) | ((~b) & (d))) + x + ac;
	a = (((a) << (s)) | ((a) >>> (32-(s))));
	a += b;
}

stock void MD5Transform_GG(int &a, int &b, int &c, int &d, int x, int s, int ac) {
	a += (((b) & (d)) | ((c) & (~d))) + x + ac;
	a = (((a) << (s)) | ((a) >>> (32-(s))));
	a += b;
}

stock void MD5Transform_HH(int &a, int &b, int &c, int &d, int x, int s, int ac) {
	a += ((b) ^ (c) ^ (d)) + x + ac;
	a = (((a) << (s)) | ((a) >>> (32-(s))));
	a += b;
}

stock void MD5Transform_II(int &a, int &b, int &c, int &d, int x, int s, int ac) {
	a += ((c) ^ ((b) | (~d))) + x + ac;
	a = (((a) << (s)) | ((a) >>> (32-(s))));
	a += b;
}

stock void MD5Transform(int[] buf, int[] ind) {
	int a = buf[0];
	int b = buf[1];
	int c = buf[2];
	int d = buf[3];
	
	MD5Transform_FF(a, b, c, d, ind[0], 7, 0xd75aa478);
	MD5Transform_FF(d, a, b, c, ind[1], 12, 0xe5c7b756);
	MD5Transform_FF(c, d, a, b, ind[2], 17, 0x252070db);
	MD5Transform_FF(b, c, d, a, ind[3], 22, 0xc5bdceee);
	MD5Transform_FF(a, b, c, d, ind[4], 7, 0xf55c0faf);
	MD5Transform_FF(d, a, b, c, ind[5], 12, 0x4787c62a);
	MD5Transform_FF(c, d, a, b, ind[6], 17, 0xa8304613);
	MD5Transform_FF(b, c, d, a, ind[7], 22, 0xfd469501);
	MD5Transform_FF(a, b, c, d, ind[8], 7, 0x698098d8);
	MD5Transform_FF(d, a, b, c, ind[9], 12, 0x8b44f7af);
	MD5Transform_FF(c, d, a, b, ind[10], 17, 0xffff5bb1);
	MD5Transform_FF(b, c, d, a, ind[11], 22, 0x895cd7be);
	MD5Transform_FF(a, b, c, d, ind[12], 7, 0x6b901122);
	MD5Transform_FF(d, a, b, c, ind[13], 12, 0xfd987193);
	MD5Transform_FF(c, d, a, b, ind[14], 17, 0xa679438e);
	MD5Transform_FF(b, c, d, a, ind[15], 22, 0x49b40821);
	
	MD5Transform_GG(a, b, c, d, ind[1], 5, 0xf61e2562);
	MD5Transform_GG(d, a, b, c, ind[6], 9, 0xc040b340);
	MD5Transform_GG(c, d, a, b, ind[11], 14, 0x265e5a51);
	MD5Transform_GG(b, c, d, a, ind[0], 20, 0xe9b6c7aa);
	MD5Transform_GG(a, b, c, d, ind[5], 5, 0xd62f105d);
	MD5Transform_GG(d, a, b, c, ind[10], 9, 0x02441453);
	MD5Transform_GG(c, d, a, b, ind[15], 14, 0xd8a1e681);
	MD5Transform_GG(b, c, d, a, ind[4], 20, 0xe7d3fbc8);
	MD5Transform_GG(a, b, c, d, ind[9], 5, 0x21e1cde6);
	MD5Transform_GG(d, a, b, c, ind[14], 9, 0xc33707d6);
	MD5Transform_GG(c, d, a, b, ind[3], 14, 0xf4d50d87);
	MD5Transform_GG(b, c, d, a, ind[8], 20, 0x455a14ed);
	MD5Transform_GG(a, b, c, d, ind[13], 5, 0xa9e3e905);
	MD5Transform_GG(d, a, b, c, ind[2], 9, 0xfcefa3f8);
	MD5Transform_GG(c, d, a, b, ind[7], 14, 0x676f02d9);
	MD5Transform_GG(b, c, d, a, ind[12], 20, 0x8d2a4c8a);
	
	MD5Transform_HH(a, b, c, d, ind[5], 4, 0xfffa3942);
	MD5Transform_HH(d, a, b, c, ind[8], 11, 0x8771f681);
	MD5Transform_HH(c, d, a, b, ind[11], 16, 0x6d9d6122);
	MD5Transform_HH(b, c, d, a, ind[14], 23, 0xfde5380c);
	MD5Transform_HH(a, b, c, d, ind[1], 4, 0xa4beea44);
	MD5Transform_HH(d, a, b, c, ind[4], 11, 0x4bdecfa9);
	MD5Transform_HH(c, d, a, b, ind[7], 16, 0xf6bb4b60);
	MD5Transform_HH(b, c, d, a, ind[10], 23, 0xbebfbc70);
	MD5Transform_HH(a, b, c, d, ind[13], 4, 0x289b7ec6);
	MD5Transform_HH(d, a, b, c, ind[0], 11, 0xeaa127fa);
	MD5Transform_HH(c, d, a, b, ind[3], 16, 0xd4ef3085);
	MD5Transform_HH(b, c, d, a, ind[6], 23, 0x04881d05);
	MD5Transform_HH(a, b, c, d, ind[9], 4, 0xd9d4d039);
	MD5Transform_HH(d, a, b, c, ind[12], 11, 0xe6db99e5);
	MD5Transform_HH(c, d, a, b, ind[15], 16, 0x1fa27cf8);
	MD5Transform_HH(b, c, d, a, ind[2], 23, 0xc4ac5665);

	MD5Transform_II(a, b, c, d, ind[0], 6, 0xf4292244);
	MD5Transform_II(d, a, b, c, ind[7], 10, 0x432aff97);
	MD5Transform_II(c, d, a, b, ind[14], 15, 0xab9423a7);
	MD5Transform_II(b, c, d, a, ind[5], 21, 0xfc93a039);
	MD5Transform_II(a, b, c, d, ind[12], 6, 0x655b59c3);
	MD5Transform_II(d, a, b, c, ind[3], 10, 0x8f0ccc92);
	MD5Transform_II(c, d, a, b, ind[10], 15, 0xffeff47d);
	MD5Transform_II(b, c, d, a, ind[1], 21, 0x85845dd1);
	MD5Transform_II(a, b, c, d, ind[8], 6, 0x6fa87e4f);
	MD5Transform_II(d, a, b, c, ind[15], 10, 0xfe2ce6e0);
	MD5Transform_II(c, d, a, b, ind[6], 15, 0xa3014314);
	MD5Transform_II(b, c, d, a, ind[13], 21, 0x4e0811a1);
	MD5Transform_II(a, b, c, d, ind[4], 6, 0xf7537e82);
	MD5Transform_II(d, a, b, c, ind[11], 10, 0xbd3af235);
	MD5Transform_II(c, d, a, b, ind[2], 15, 0x2ad7d2bb);
	MD5Transform_II(b, c, d, a, ind[9], 21, 0xeb86d391);
	
	buf[0] += a;
	buf[1] += b;
	buf[2] += c;
	buf[3] += d;
}