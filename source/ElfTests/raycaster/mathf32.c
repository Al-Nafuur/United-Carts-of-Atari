
/*
; ********************************************************************
;  mathf32
;
;    Fixed point math routines
;
;    $Date: Sun, 24 Aug 2014 00:28:00 +0200 $
;    $Author: dietrich $
;    $Revision: 359 $
;
;  Copyright (C) 2014 Andreas Dietrich
; ********************************************************************
*/

#include "mathf32.h"

//
// f32 fixed point type (32 bit)
//
// Based on code from the SGDK Genesis development kit
// https://code.google.com/p/sgdk
//


inline Vec2f32 VecSet(f32 x, f32 y)
{
  Vec2f32 result = {x, y};

  return result;
};

inline Vec2f32 VecAdd(Vec2f32 v0, Vec2f32 v1)
{
  Vec2f32 result;

  result.x = F32Add(v0.x, v1.x);
  result.y = F32Add(v0.y, v1.y);

  return result;
};

inline Vec2f32 VecSub(Vec2f32 v0, Vec2f32 v1)
{
  Vec2f32 result;

  result.x = F32Sub(v0.x, v1.x);
  result.y = F32Sub(v0.y, v1.y);

  return result;
};

inline Vec2f32 VecMul(f32 s, Vec2f32 v)
{
  Vec2f32 result;

  result.x = F32Mul(s, v.x);
  result.y = F32Mul(s, v.y);

  return result;
};

inline Vec2f32 VecDiv(Vec2f32 v, f32 s)
{
  Vec2f32 result;

  result.x = F32Div(v.x, s);
  result.y = F32Div(v.y, s);

  return result;
};
