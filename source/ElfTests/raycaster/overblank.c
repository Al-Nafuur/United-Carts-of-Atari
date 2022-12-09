#include "assets.h"
#include "mathf32.h"
#include "vcsLib.h"

typedef struct
{
	f32 x;
	f32 y;
} vec2;

vec2 rotate(int radians, vec2 vec);

void rcfRender(vec2 position, int directionRads, uint8_t colors[40], uint32_t systemType);

static vec2 position = { F32(5), F32(5) };

static int frameCount = 0;

static unsigned char direction = 0;

static const uint8_t ntscPalette[5] = { 0xe2, 0x32, 0xb2, 0x9a, 0x02 };
static const uint8_t palPalette[5] = { 0x22, 0x42, 0x72, 0x9a, 0x02 };

void overblank(unsigned char but1, unsigned char joy1, uint8_t colors[40], uint32_t systemType)
{

	frameCount++;
	if (frameCount > 300)
	{
		frameCount = 0;
	}

	// Inputs
	if ((but1 & 0x80) == 0)
	{
		//pressed
	}
	f32 moveSpeed = F32Div(F32(5), F32(60));
	// move fowards if no wall in front of you
	if ((joy1 & 0x10) == 0)
	{
		f32 x = F32Add(position.x, F32Mul(SineLookup[direction], moveSpeed));
		f32 y = F32Add(position.y, F32Mul(SineLookup[(direction + 32) & 0x7f], moveSpeed));

		if (map[F32ToInt(x)][F32ToInt(position.y)] == 0)
		{
			position.x = x;
		}
		if (map[F32ToInt(position.x)][F32ToInt(y)] == 0)
		{
			position.y = y;
		}
	}
	// move backwards if no wall behind you
	if ((joy1 & 0x20) == 0)
	{
		f32 x = F32Sub(position.x, F32Mul(SineLookup[direction], moveSpeed));
		f32 y = F32Sub(position.y, F32Mul(SineLookup[(direction + 32) & 0x7f], moveSpeed));

		if (map[F32ToInt(x)][F32ToInt(position.y)] == 0)
		{
			position.x = x;
		}
		if (map[F32ToInt(position.x)][F32ToInt(y)] == 0)
		{
			position.y = y;
		}
	}

	//rotate to the right
	if ((joy1 & 0x80) == 0)
	{
		direction++;
	}
	//rotate to the left
	if ((joy1 & 0x40) == 0)
	{
		direction--;
	}

	direction &= 0x7f;
	// RAY CAST
	rcfRender(position, direction, colors, systemType);
}

void rcfRender(vec2 position, int directionRads, uint8_t colors[40], uint32_t systemType)
{
	static f32 width = F32(40);
	static f32 height = F32(64);
	vec2 cameraPlane;
	vec2 direction = { F32(0), F32(1) };
	direction = rotate(directionRads, direction);
	cameraPlane = rotate(32, direction);
	cameraPlane.x = F32Mul(cameraPlane.x, (int)(0.75 * F32(1))); //0.75
	cameraPlane.y = F32Mul(cameraPlane.y, (int)(0.75 * F32(1)));
	for (int i = 0; i < 40; i++)
	{
		int x = i;
		uint8_t color;
		int lineHeight, drawStart;
		//calculate ray position and direction
		f32 cameraX = F32Sub(F32Div(F32Mul(F32(2), F32(x)), width), F32(1)); //x-coordinate in camera space
		f32 rayPosX = position.x;
		f32 rayPosY = position.y;
		f32 rayDirX = F32Add(direction.x, F32Mul(cameraPlane.x, cameraX));
		f32 rayDirY = F32Add(direction.y, F32Mul(cameraPlane.y, cameraX));
		//which box of the map we're in
		int mapX = F32ToInt(rayPosX);
		int mapY = F32ToInt(rayPosY);

		//length of ray from current position to next x or y-side
		f32 sideDistX = INT32_MAX;
		f32 sideDistY = INT32_MAX;

		//length of ray from one x or y-side to next x or y-side
		f32 deltaDistX = rayDirX == 0 ? INT32_MAX : F32Div(F32(1), rayDirX);
		if (deltaDistX < 0)
		{
			deltaDistX = F32Mul(F32(-1), deltaDistX);
		}
		f32 deltaDistY = rayDirY == 0 ? INT32_MAX : F32Div(F32(1), rayDirY);
		if (deltaDistY < 0)
		{
			deltaDistY = F32Mul(F32(-1), deltaDistY);
		}

		f32 perpWallDist;

		//what direction to step in x or y-direction (either +1 or -1)
		int stepX = 0;
		int stepY = 0;

		int hit = 0; //was there a wall hit?
		int side = 0; //was a NS or a EW wall hit?
					 //calculate step and initial sideDist
		if (rayDirX < 0)
		{
			stepX = -1;
			sideDistX = F32Mul(F32Sub(rayPosX, F32(mapX)), deltaDistX);
		}
		else if (rayDirX > 0)
		{
			stepX = 1;
			sideDistX = F32Mul(F32Sub(F32Add(F32(mapX), F32(1)), rayPosX), deltaDistX);
		}
		if (rayDirY < 0)
		{
			stepY = -1;
			sideDistY = F32Mul(F32Sub(rayPosY, F32(mapY)), deltaDistY);
		}
		else if (rayDirY > 0)
		{
			stepY = 1;
			sideDistY = F32Mul(F32Sub(F32Add(F32(mapY), F32(1)), rayPosY), deltaDistY);
		}
		//perform DDA
		while (hit == 0)
		{
			//jump to next map square, OR in x-direction, OR in y-direction
			if (sideDistX < sideDistY)
			{
				sideDistX = F32Add(sideDistX, deltaDistX);
				mapX += stepX;
				side = 0;
			}
			else
			{
				sideDistY = F32Add(sideDistY, deltaDistY);
				mapY += stepY;
				side = 1;
			}
			if (mapX < 0 || mapX > 39 || mapY < 0 || mapY > 39)
				mapX = mapY = 1;
			//Check if ray has hit a wall
			hit = map[mapX][mapY];
		}
		//Calculate distance projected on camera direction (oblique distance will give fisheye effect!)
		if (side == 0)
		{
			perpWallDist = F32Div(F32Add(F32Sub(F32(mapX), rayPosX), F32((1 - stepX) / 2)), rayDirX);
		}
		else
		{
			perpWallDist = F32Div(F32Add(F32Sub(F32(mapY), rayPosY), F32((1 - stepY) / 2)), rayDirY);
		}

		//Calculate height of line to draw on screen
		lineHeight = perpWallDist == 0 ? 64 : F32ToInt(F32Div(height, perpWallDist));

		//calculate lowest and highest pixel to fill in current stripe
		drawStart = -lineHeight / 2 + F32ToInt(height) / 2;
		if (drawStart < 0)
		{
			drawStart = 0;
		}

		//choose wall color
		//give x and y sides different brightness
		color = (systemType == ST_NTSC_2600 ? ntscPalette[map[mapX][mapY]] : palPalette[map[mapX][mapY]]) + (side << 1);

		colors[i] = color;
		heights[x] = 32 - drawStart;
	}
}

vec2 rotate(int direction, vec2 vec)
{
	f32 s = SineLookup[direction];
	f32 c = SineLookup[((direction + 32) & 0x7f)];

	vec2 v =
	{
		F32Add(F32Mul(c, vec.x), F32Mul(s, vec.y)),
		F32Add(F32Mul(F32Mul(F32(-1), s), vec.x), F32Mul(c, vec.y))
	};
	return v;
}