#pragma semicolon 1

#include <sourcemod>

stock MD5String(const String:str[], String:output[], maxlen) {
	decl x[2];
	decl buf[4];
	decl input[64];
	new i, ii;
	
	new len = strlen(str);
	
	// MD5Init
	x[0] = x[1] = 0;
	buf[0] = 0x67452301;
	buf[1] = 0xefcdab89;
	buf[2] = 0x98badcfe;
	buf[3] = 0x10325476;
	
	// MD5Update
	new in[16];

	in[14] = x[0];
	in[15] = x[1];
	
	new mdi = (x[0] >>> 3) & 0x3F;
	
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
	
	new c = 0;
	while (len--) {
		input[mdi] = str[c];
		mdi += 1;
		c += 1;
		
		if (mdi == 0x40)
		{
			for (i = 0, ii = 0; i < 16; ++i, ii += 4)
			{
				in[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
			}
			// Transform
			MD5Transform(buf, in);
			
			mdi = 0;
		}
	}
	
	// MD5Final
	new padding[64] = {
		0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	};

	new inx[16];
	inx[14] = x[0];
	inx[15] = x[1];
	
	mdi = (x[0] >>> 3) & 0x3F;
	
	len = (mdi < 56) ? (56 - mdi) : (120 - mdi);
	in[14] = x[0];
	in[15] = x[1];
	
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
				in[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
			}

			// Transform
			MD5Transform(buf, in);
			
			mdi = 0;
		}
	}
	
	for (i = 0, ii = 0; i < 14; ++i, ii += 4) {
		inx[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
	}

	MD5Transform(buf, inx);
	
	new digest[16];

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

stock MD5Transform_FF(&a, &b, &c, &d, x, s, ac) {
	a += (((b) & (c)) | ((~b) & (d))) + x + ac;
	a = (((a) << (s)) | ((a) >>> (32-(s))));
	a += b;
}

stock MD5Transform_GG(&a, &b, &c, &d, x, s, ac) {
	a += (((b) & (d)) | ((c) & (~d))) + x + ac;
	a = (((a) << (s)) | ((a) >>> (32-(s))));
	a += b;
}

stock MD5Transform_HH(&a, &b, &c, &d, x, s, ac) {
	a += ((b) ^ (c) ^ (d)) + x + ac;
	a = (((a) << (s)) | ((a) >>> (32-(s))));
	a += b;
}

stock MD5Transform_II(&a, &b, &c, &d, x, s, ac) {
	a += ((c) ^ ((b) | (~d))) + x + ac;
	a = (((a) << (s)) | ((a) >>> (32-(s))));
	a += b;
}

stock MD5Transform(buf[], in[]) {
	new a = buf[0];
	new b = buf[1];
	new c = buf[2];
	new d = buf[3];
	
	MD5Transform_FF(a, b, c, d, in[0], 7, 0xd75aa478);
	MD5Transform_FF(d, a, b, c, in[1], 12, 0xe5c7b756);
	MD5Transform_FF(c, d, a, b, in[2], 17, 0x252070db);
	MD5Transform_FF(b, c, d, a, in[3], 22, 0xc5bdceee);
	MD5Transform_FF(a, b, c, d, in[4], 7, 0xf55c0faf);
	MD5Transform_FF(d, a, b, c, in[5], 12, 0x4787c62a);
	MD5Transform_FF(c, d, a, b, in[6], 17, 0xa8304613);
	MD5Transform_FF(b, c, d, a, in[7], 22, 0xfd469501);
	MD5Transform_FF(a, b, c, d, in[8], 7, 0x698098d8);
	MD5Transform_FF(d, a, b, c, in[9], 12, 0x8b44f7af);
	MD5Transform_FF(c, d, a, b, in[10], 17, 0xffff5bb1);
	MD5Transform_FF(b, c, d, a, in[11], 22, 0x895cd7be);
	MD5Transform_FF(a, b, c, d, in[12], 7, 0x6b901122);
	MD5Transform_FF(d, a, b, c, in[13], 12, 0xfd987193);
	MD5Transform_FF(c, d, a, b, in[14], 17, 0xa679438e);
	MD5Transform_FF(b, c, d, a, in[15], 22, 0x49b40821);
	
	MD5Transform_GG(a, b, c, d, in[1], 5, 0xf61e2562);
	MD5Transform_GG(d, a, b, c, in[6], 9, 0xc040b340);
	MD5Transform_GG(c, d, a, b, in[11], 14, 0x265e5a51);
	MD5Transform_GG(b, c, d, a, in[0], 20, 0xe9b6c7aa);
	MD5Transform_GG(a, b, c, d, in[5], 5, 0xd62f105d);
	MD5Transform_GG(d, a, b, c, in[10], 9, 0x02441453);
	MD5Transform_GG(c, d, a, b, in[15], 14, 0xd8a1e681);
	MD5Transform_GG(b, c, d, a, in[4], 20, 0xe7d3fbc8);
	MD5Transform_GG(a, b, c, d, in[9], 5, 0x21e1cde6);
	MD5Transform_GG(d, a, b, c, in[14], 9, 0xc33707d6);
	MD5Transform_GG(c, d, a, b, in[3], 14, 0xf4d50d87);
	MD5Transform_GG(b, c, d, a, in[8], 20, 0x455a14ed);
	MD5Transform_GG(a, b, c, d, in[13], 5, 0xa9e3e905);
	MD5Transform_GG(d, a, b, c, in[2], 9, 0xfcefa3f8);
	MD5Transform_GG(c, d, a, b, in[7], 14, 0x676f02d9);
	MD5Transform_GG(b, c, d, a, in[12], 20, 0x8d2a4c8a);
	
	MD5Transform_HH(a, b, c, d, in[5], 4, 0xfffa3942);
	MD5Transform_HH(d, a, b, c, in[8], 11, 0x8771f681);
	MD5Transform_HH(c, d, a, b, in[11], 16, 0x6d9d6122);
	MD5Transform_HH(b, c, d, a, in[14], 23, 0xfde5380c);
	MD5Transform_HH(a, b, c, d, in[1], 4, 0xa4beea44);
	MD5Transform_HH(d, a, b, c, in[4], 11, 0x4bdecfa9);
	MD5Transform_HH(c, d, a, b, in[7], 16, 0xf6bb4b60);
	MD5Transform_HH(b, c, d, a, in[10], 23, 0xbebfbc70);
	MD5Transform_HH(a, b, c, d, in[13], 4, 0x289b7ec6);
	MD5Transform_HH(d, a, b, c, in[0], 11, 0xeaa127fa);
	MD5Transform_HH(c, d, a, b, in[3], 16, 0xd4ef3085);
	MD5Transform_HH(b, c, d, a, in[6], 23, 0x04881d05);
	MD5Transform_HH(a, b, c, d, in[9], 4, 0xd9d4d039);
	MD5Transform_HH(d, a, b, c, in[12], 11, 0xe6db99e5);
	MD5Transform_HH(c, d, a, b, in[15], 16, 0x1fa27cf8);
	MD5Transform_HH(b, c, d, a, in[2], 23, 0xc4ac5665);

	MD5Transform_II(a, b, c, d, in[0], 6, 0xf4292244);
	MD5Transform_II(d, a, b, c, in[7], 10, 0x432aff97);
	MD5Transform_II(c, d, a, b, in[14], 15, 0xab9423a7);
	MD5Transform_II(b, c, d, a, in[5], 21, 0xfc93a039);
	MD5Transform_II(a, b, c, d, in[12], 6, 0x655b59c3);
	MD5Transform_II(d, a, b, c, in[3], 10, 0x8f0ccc92);
	MD5Transform_II(c, d, a, b, in[10], 15, 0xffeff47d);
	MD5Transform_II(b, c, d, a, in[1], 21, 0x85845dd1);
	MD5Transform_II(a, b, c, d, in[8], 6, 0x6fa87e4f);
	MD5Transform_II(d, a, b, c, in[15], 10, 0xfe2ce6e0);
	MD5Transform_II(c, d, a, b, in[6], 15, 0xa3014314);
	MD5Transform_II(b, c, d, a, in[13], 21, 0x4e0811a1);
	MD5Transform_II(a, b, c, d, in[4], 6, 0xf7537e82);
	MD5Transform_II(d, a, b, c, in[11], 10, 0xbd3af235);
	MD5Transform_II(c, d, a, b, in[2], 15, 0x2ad7d2bb);
	MD5Transform_II(b, c, d, a, in[9], 21, 0xeb86d391);
	
	buf[0] += a;
	buf[1] += b;
	buf[2] += c;
	buf[3] += d;
}