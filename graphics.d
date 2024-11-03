module graphics;

import dransik;
import win32.wingdi;

// **********************************************************

buffer makeBmp(int x, int y, buffer data)
{
	assert(x*y == data.length);

	BITMAPINFOHEADER bmpInfoHeader;
	bmpInfoHeader.biSize = BITMAPINFOHEADER.sizeof;
	bmpInfoHeader.biBitCount = 8;
	bmpInfoHeader.biClrImportant = 256;
	bmpInfoHeader.biClrUsed = 256;
	bmpInfoHeader.biCompression = BI_RGB;
	bmpInfoHeader.biHeight = -x;
	bmpInfoHeader.biWidth = y;
	bmpInfoHeader.biPlanes = 1;
	bmpInfoHeader.biSizeImage = x*y; 

	BITMAPFILEHEADER bfh;
	bfh.bfType=0x4D42;
	bfh.bfOffBits = BITMAPINFOHEADER.sizeof + BITMAPFILEHEADER.sizeof + 256*4;
	bfh.bfSize = bfh.bfOffBits + bmpInfoHeader.biSizeImage;
	
	return toBuffer(bfh) ~ toBuffer(bmpInfoHeader) ~ palette ~ data;
}

ubyte[4][256] palette = 
[
	[0, 0, 0, 0],
	[168, 0, 0, 0],
	[0, 168, 0, 0],
	[168, 168, 0, 0],
	[0, 0, 168, 0],
	[168, 0, 168, 0],
	[0, 84, 168, 0],
	[168, 168, 168, 0],
	[84, 84, 84, 0],
	[252, 84, 84, 0],
	[84, 252, 84, 0],
	[252, 252, 84, 0],
	[84, 84, 252, 0],
	[252, 84, 252, 0],
	[84, 252, 252, 0],
	[252, 252, 252, 0],
	[252, 252, 252, 0],
	[240, 240, 240, 0],
	[228, 228, 228, 0],
	[216, 216, 216, 0],
	[208, 208, 208, 0],
	[196, 196, 196, 0],
	[184, 184, 184, 0],
	[172, 172, 172, 0],
	[160, 160, 160, 0],
	[152, 152, 152, 0],
	[140, 140, 140, 0],
	[128, 128, 128, 0],
	[116, 116, 116, 0],
	[108, 108, 108, 0],
	[96, 96, 96, 0],
	[84, 84, 84, 0],
	[72, 72, 72, 0],
	[64, 64, 64, 0],
	[52, 52, 52, 0],
	[40, 40, 40, 0],
	[28, 28, 28, 0],
	[16, 16, 16, 0],
	[8, 8, 8, 0],
	[0, 0, 0, 0],
	[216, 216, 252, 0],
	[184, 184, 244, 0],
	[152, 152, 240, 0],
	[124, 124, 236, 0],
	[96, 96, 232, 0],
	[68, 68, 224, 0],
	[44, 44, 220, 0],
	[16, 16, 216, 0],
	[0, 0, 212, 0],
	[0, 0, 188, 0],
	[0, 0, 168, 0],
	[0, 0, 148, 0],
	[0, 0, 124, 0],
	[0, 0, 104, 0],
	[0, 0, 84, 0],
	[0, 0, 64, 0],
	[252, 0, 252, 0],
	[224, 0, 224, 0],
	[196, 0, 196, 0],
	[168, 0, 168, 0],
	[144, 0, 144, 0],
	[116, 0, 116, 0],
	[88, 0, 88, 0],
	[64, 0, 64, 0],
	[216, 252, 252, 0],
	[184, 252, 252, 0],
	[156, 252, 252, 0],
	[124, 252, 252, 0],
	[92, 248, 252, 0],
	[64, 244, 252, 0],
	[32, 244, 252, 0],
	[0, 244, 252, 0],
	[0, 216, 228, 0],
	[0, 196, 204, 0],
	[0, 172, 180, 0],
	[0, 156, 156, 0],
	[0, 132, 132, 0],
	[0, 108, 112, 0],
	[0, 84, 88, 0],
	[0, 64, 64, 0],
	[176, 252, 208, 0],
	[160, 244, 196, 0],
	[148, 240, 184, 0],
	[136, 236, 168, 0],
	[124, 232, 156, 0],
	[112, 224, 144, 0],
	[100, 220, 132, 0],
	[88, 216, 120, 0],
	[80, 212, 104, 0],
	[68, 204, 92, 0],
	[56, 200, 80, 0],
	[48, 196, 68, 0],
	[40, 192, 56, 0],
	[28, 184, 40, 0],
	[12, 176, 20, 0],
	[4, 172, 4, 0],
	[4, 168, 4, 0],
	[0, 164, 4, 0],
	[0, 160, 4, 0],
	[0, 156, 4, 0],
	[0, 152, 4, 0],
	[0, 140, 4, 0],
	[0, 132, 4, 0],
	[0, 124, 4, 0],
	[0, 112, 4, 0],
	[0, 104, 4, 0],
	[0, 92, 4, 0],
	[0, 84, 4, 0],
	[0, 76, 4, 0],
	[0, 64, 4, 0],
	[0, 56, 4, 0],
	[0, 48, 4, 0],
	[92, 168, 252, 0],
	[76, 160, 252, 0],
	[64, 152, 252, 0],
	[48, 148, 252, 0],
	[36, 140, 252, 0],
	[20, 132, 252, 0],
	[8, 124, 252, 0],
	[0, 120, 252, 0],
	[0, 112, 240, 0],
	[0, 100, 216, 0],
	[0, 92, 196, 0],
	[0, 80, 172, 0],
	[0, 68, 152, 0],
	[0, 60, 128, 0],
	[0, 48, 108, 0],
	[0, 40, 88, 0],
	[252, 236, 216, 0],
	[244, 220, 196, 0],
	[240, 208, 176, 0],
	[232, 192, 160, 0],
	[228, 176, 140, 0],
	[220, 160, 124, 0],
	[216, 144, 108, 0],
	[208, 128, 92, 0],
	[204, 112, 80, 0],
	[196, 92, 64, 0],
	[192, 76, 52, 0],
	[184, 60, 40, 0],
	[180, 44, 28, 0],
	[176, 28, 16, 0],
	[168, 12, 4, 0],
	[164, 0, 0, 0],
	[164, 0, 0, 0],
	[156, 0, 0, 0],
	[148, 0, 0, 0],
	[144, 0, 0, 0],
	[136, 0, 0, 0],
	[128, 0, 0, 0],
	[124, 0, 0, 0],
	[116, 0, 0, 0],
	[108, 0, 0, 0],
	[104, 0, 0, 0],
	[96, 0, 0, 0],
	[88, 0, 0, 0],
	[84, 0, 0, 0],
	[76, 0, 0, 0],
	[68, 0, 0, 0],
	[64, 0, 0, 0],
	[252, 216, 240, 0],
	[252, 184, 228, 0],
	[252, 156, 216, 0],
	[252, 124, 208, 0],
	[252, 92, 200, 0],
	[252, 64, 188, 0],
	[252, 32, 180, 0],
	[252, 0, 168, 0],
	[228, 0, 152, 0],
	[204, 0, 128, 0],
	[180, 0, 116, 0],
	[156, 0, 96, 0],
	[132, 0, 80, 0],
	[112, 0, 68, 0],
	[88, 0, 52, 0],
	[64, 0, 40, 0],
	[220, 232, 252, 0],
	[208, 224, 248, 0],
	[196, 216, 244, 0],
	[184, 208, 240, 0],
	[176, 200, 236, 0],
	[164, 192, 232, 0],
	[156, 184, 228, 0],
	[144, 176, 228, 0],
	[136, 168, 224, 0],
	[128, 164, 220, 0],
	[116, 156, 216, 0],
	[108, 148, 212, 0],
	[100, 140, 208, 0],
	[92, 136, 204, 0],
	[84, 128, 200, 0],
	[76, 124, 200, 0],
	[176, 204, 220, 0],
	[156, 192, 208, 0],
	[136, 176, 200, 0],
	[120, 164, 192, 0],
	[104, 156, 180, 0],
	[88, 144, 172, 0],
	[76, 132, 164, 0],
	[64, 120, 152, 0],
	[52, 112, 144, 0],
	[40, 100, 136, 0],
	[28, 92, 124, 0],
	[20, 84, 116, 0],
	[12, 76, 108, 0],
	[4, 68, 96, 0],
	[0, 56, 88, 0],
	[0, 52, 80, 0],
	[48, 88, 136, 0],
	[44, 84, 128, 0],
	[44, 80, 120, 0],
	[40, 76, 116, 0],
	[36, 76, 108, 0],
	[36, 72, 104, 0],
	[32, 68, 96, 0],
	[28, 64, 88, 0],
	[28, 60, 84, 0],
	[24, 56, 76, 0],
	[24, 52, 72, 0],
	[20, 48, 64, 0],
	[16, 44, 56, 0],
	[16, 40, 52, 0],
	[12, 36, 44, 0],
	[12, 32, 40, 0],
	[0, 244, 252, 0],
	[8, 208, 228, 0],
	[16, 176, 204, 0],
	[24, 152, 180, 0],
	[28, 124, 156, 0],
	[28, 104, 132, 0],
	[28, 80, 108, 0],
	[28, 64, 88, 0],
	[0, 0, 252, 0],
	[0, 28, 252, 0],
	[0, 60, 252, 0],
	[0, 92, 252, 0],
	[0, 124, 252, 0],
	[0, 156, 252, 0],
	[0, 188, 252, 0],
	[0, 220, 252, 0],
	[252, 0, 252, 0],
	[0, 252, 0, 0],
	[0, 184, 28, 0],
	[0, 172, 52, 0],
	[0, 160, 76, 0],
	[0, 148, 96, 0],
	[0, 136, 112, 0],
	[24, 152, 180, 0],
	[0, 116, 140, 0],
	[0, 100, 156, 0],
	[0, 84, 172, 0],
	[0, 60, 188, 0],
	[0, 28, 204, 0],
	[0, 0, 252, 0],
	[64, 16, 140, 0],
	[184, 200, 220, 0],
];

ubyte findColour(uint colour)
{
	static ubyte[uint] cache;
	if(colour in cache)
		return cache[colour];
	
	ubyte r = GetRValue(colour);
	ubyte g = GetGValue(colour);
	ubyte b = GetBValue(colour);

	ubyte best;
	int bestDistance=int.max;
	foreach(i,c;palette)
	{
		int distance = abs(r-c[2]) + abs(g-c[1]) + abs(b-c[0]);
		if(distance<bestDistance)
		{
			bestDistance = distance;
			best = i;
		}
	}

	cache[colour] = best;
	return best;
}

uint interpolateColour(uint c1, uint c2, float point)
{
	ubyte r1 = GetRValue(c1);
	ubyte g1 = GetGValue(c1);
	ubyte b1 = GetBValue(c1);
	ubyte r2 = GetRValue(c2);
	ubyte g2 = GetGValue(c2);
	ubyte b2 = GetBValue(c2);
	ubyte r = interpolate(r1, r2, point);
	ubyte g = interpolate(g1, g2, point);
	ubyte b = interpolate(b1, b2, point);
	return RGB(r, g, b);
}

// **********************************************************

void textToBitmap(uint W,uint H)(ubyte[W][] result, char[] data, ubyte[char] map)
{
	//assert(data.length == W*H);
	assert(result.length == H);
	uint x, y;
	foreach(c;data)
		if(c in map)
		{
			result[y][x] = map[c];
			x++;
			y+=x/W;
			x%=W;
		}
}

ubyte[16][16] sprSolidTile, sprSolidObject, sprTileHighlight, sprMob;

static this()
{
	textToBitmap!(16u,16u)(sprSolidTile, "
		................
		................
		................
		....########....
		...#Rr#Rrrrr#...
		...#r/#rrrr/#...
		...##########...
		...#Rrrrr#Rr#...
		...#rrrr/#r/#...
		...##########...
		...#Rr#Rrrrr#...
		...#r/#rrrr/#...
		....########....
		................
		................
		................
", ['.':0xFE, '#':0x00, 'r':0x30, 'R':0x2D, '/':0x33]);
	textToBitmap!(16u,16u)(sprSolidObject, "
		................
		................
		................
		................
		......####......
		.....#Rrrr#.....
		....#Rr##rr#....
		....#r#..#r#....
		....#r#..#r#....
		....#rr##r/#....
		.....#rrr/#.....
		......####......
		................
		................
		................
		................
", ['.':0xFE, '#':0x00, 'r':0x30, 'R':0x2D, '/':0x33]);
	textToBitmap!(16u,16u)(sprMob, "
		................
		................
		................
		................
		.....#....#.....
		....#R####r#....
		.....#rr/r#.....
		....#R#rr#r#....
		....#rrRrrR#....
		....#rrrrrr#....
		....#/#r/#/#....
		.....#.##.#.....
		................
		................
		................
		................
", ['.':0xFE, '#':0x00, 'r':0x30, 'R':0x2D, '/':0x33]);
	textToBitmap!(16u,16u)(sprTileHighlight, "
		################
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		#..............#
		################
", ['.':0xFE, '#':0x45]);
}