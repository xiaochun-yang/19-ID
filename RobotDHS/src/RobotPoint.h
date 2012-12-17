#pragma once
#include <math.h>

//this is used by both cassette and robot itself
class PointCoordinate
{
public:
	enum ArmOrientation
	{
#ifdef EPSON_VB_4
		ARM_ORIENTATION_UNKNOWN = 0,
		ARM_ORIENTATION_RIGHTY = 1,
		ARM_ORIENTATION_LEFTY = 2
#else
		ARM_ORIENTATION_RIGHTY = 0,
		ARM_ORIENTATION_LEFTY = 1
#endif
	};
	float x;
	float y;
	float z;
	float u;
	short localNum;
    ArmOrientation o;    //orientation

	PointCoordinate( ):x(0), y(0), z(0), u(0), localNum(0), o(ARM_ORIENTATION_RIGHTY) { }
	PointCoordinate( float x_, float y_, float z_, float u_, ArmOrientation o_, short num ):
	x(x_),
	y(y_),
	z(z_),
	u(u_),
	o(o_),
	localNum(num)
	{
	}
	void clear( )
	{
		x = 0.0f;
		y = 0.0f;
		z = 0.0f;
		u = 0.0f;
		localNum = 0;
		o = ARM_ORIENTATION_RIGHTY;
	}

	float getRadius( ) const
	{
		return sqrtf( x * x + y * y );
	}
	float distance( const PointCoordinate& from ) const
	{
		float dx = from.x - x;
		float dy = from.y - y;
		float dz = from.z - z;
		return sqrtf( dx * dx + dy * dy + dz * dz );
	}
	PointCoordinate operator +(const PointCoordinate& another) const
	{
		return PointCoordinate( x + another.x, y + another.y, z + another.z, u + another.u, o, localNum );
	}
	PointCoordinate operator -(const PointCoordinate& another) const
	{
		return PointCoordinate( x - another.x, y - another.y, z - another.z, u - another.u, o, localNum );
	}
	PointCoordinate operator /(float d) const
	{
		return PointCoordinate( x / d, y / d, z / d, u / d, o, localNum );
	}
	PointCoordinate operator *(float d) const
	{
		return PointCoordinate( x * d, y * d, z * d, u * d, o, localNum );
	}

	PointCoordinate& operator /=(float d)
	{
		x /= d;
		y /= d;
		z /= d;
		u /= d;
		return *this;
	}
};
