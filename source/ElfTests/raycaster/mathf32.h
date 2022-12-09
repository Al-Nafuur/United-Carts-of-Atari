
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

#ifndef MATHF32_H
#define MATHF32_H

#include <stdint.h>

//
// f32 fixed point type (32 bit)
//
// Based on code from the SGDK Genesis development kit
// https://code.google.com/p/sgdk
//

typedef int32_t f32;

#define F32_INT_BITS              22
#define F32_FRAC_BITS             (32 - F32_INT_BITS)
#define F32_INT_MASK              (((1 << F32_INT_BITS) - 1) << F32_FRAC_BITS)
#define F32_FRAC_MASK             ((1 << F32_FRAC_BITS) - 1)

#define F32(value)                ((f32) ((value) * (1 << F32_FRAC_BITS)))

#define IntToF32(value)           ((value) << F32_FRAC_BITS)
#define F32ToInt(value)           ((value) >> F32_FRAC_BITS)

#define F32Frac(value)            ((value) & F32_FRAC_MASK)
#define F32Int(value)             ((value) & F32_INT_MASK)

#define F32Add(val1, val2)        ((val1) + (val2))
#define F32Sub(val1, val2)        ((val1) - (val2))
#define F32Mul(val1, val2)        (((val1) * (val2)) >> F32_FRAC_BITS)
#define F32Div(val1, val2)        (((val1) << F32_FRAC_BITS) / (val2))
#define F32Neg(value)             (0 - (value))

//
// f32 fixed point 2D vector type
//

typedef struct 
{
  f32 x, y;

} Vec2f32;

Vec2f32 VecSet(f32 x, f32 y);

Vec2f32 VecAdd(Vec2f32 v0, Vec2f32 v1);

Vec2f32 VecSub(Vec2f32 v0, Vec2f32 v1);

Vec2f32 VecMul(f32 s, Vec2f32 v);

Vec2f32 VecDiv(Vec2f32 v, f32 s);

#endif