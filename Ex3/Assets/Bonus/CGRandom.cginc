#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED

// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
}

// Interpolates a given array v of 4 float values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [0]=====o==[1]
//         |
//         t
//         |
// [2]=====o==[3]
//
float bicubicInterpolation(float v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float v[4], float2 t)
{
    // Your implementation
    float2 u = t * t * t * (t * (t * 6.0 - 15.0) + 10.0); // Quintic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float v[8], float3 t)
{
    
    float3 u = t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);
    float x3 = lerp(v[4], v[5], u.x);
    float x4 = lerp(v[6], v[7], u.x);

    // Interpolate in the y direction
    float y1 = lerp(x1, x2, u.y);
    float y2 = lerp(x3, x4, u.y);

    // Interpolate in the z direction and return
    return lerp(y1, y2, u.z);

}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    float2 leftButtonCorner = floor(c);
    float2 rightButtonCorner = leftButtonCorner + float2(1, 0);
    float2 leftUpperCorner = leftButtonCorner + float2(0, 1);
    float2 rightUpperCorner = leftUpperCorner + float2(1, 0);

    float v00 = random2(leftButtonCorner).x;
    float v10 = random2(rightButtonCorner).x;
    float v01 = random2(leftUpperCorner).x;
    float v11 = random2(rightUpperCorner).x;
    float v[4] = { v00, v10, v01, v11 };
    return bicubicInterpolation(v, frac(c));
}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    float2 leftButtonCorner = floor(c);
    float2 rightButtonCorner = leftButtonCorner + float2(1, 0);
    float2 leftUpperCorner = leftButtonCorner + float2(0, 1);
    float2 rightUpperCorner = leftButtonCorner + float2(1, 1);

    // 2 pseudo-random number represent gradient vector at the corners
    float2 v00 = random2(leftButtonCorner);
    float2 v10 = random2(rightButtonCorner);
    float2 v01 = random2(leftUpperCorner);
    float2 v11 = random2(rightUpperCorner);

    // distance vectors from corners to c
    float2 d00 = c - leftButtonCorner;
    float2 d10 = c - rightButtonCorner;
    float2 d01 = c - leftUpperCorner;
    float2 d11 = c - rightUpperCorner;

    // dot between vectors to distance between them and c
    float s00 = dot(d00, v00);
    float s10 = dot(d10, v10);
    float s01 = dot(d01, v01);
    float s11 = dot(d11, v11);
    float v[4] = { s00, s10, s01, s11 };
    return biquinticInterpolation(v, frac(c));
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{    
    // front face                
    float3 frontLeftButtonCorner = floor(c);
    float3 frontRightButtonCorner = frontLeftButtonCorner + float3(1, 0, 0);
    float3 frontLeftUpperCorner = frontLeftButtonCorner + float3(0, 1, 0);
    float3 frontRightUpperCorner = frontLeftButtonCorner + float3(1, 1, 0);
    // back face
    float3 backLeftButtonCorner = floor(c) + float3(0, 0, 1);
    float3 backRightButtonCorner = backLeftButtonCorner + float3(1, 0, 0);
    float3 backLeftUpperCorner = backLeftButtonCorner + float3(0, 1, 0);
    float3 backRightUpperCorner = backLeftButtonCorner + float3(1, 1, 0);

    // 3 pseudo-random number represent gradient vector at the corners
    float3 v000 = random3(frontLeftButtonCorner);
    float3 v100 = random3(frontRightButtonCorner);
    float3 v010 = random3(frontLeftUpperCorner);
    float3 v110 = random3(frontRightUpperCorner);

    float3 v001 = random3(backLeftButtonCorner);
    float3 v101 = random3(backRightButtonCorner);
    float3 v011 = random3(backLeftUpperCorner);
    float3 v111 = random3(backRightUpperCorner);

    // distance vectors from corners to c
    float3 d000 = c - frontLeftButtonCorner;
    float3 d100 = c - frontRightButtonCorner;
    float3 d010 = c - frontLeftUpperCorner;
    float3 d110 = c - frontRightUpperCorner;

    float3 d001 = c - backLeftButtonCorner;
    float3 d101 = c - backRightButtonCorner;
    float3 d011 = c - backLeftUpperCorner;
    float3 d111 = c - backRightUpperCorner;

    // dot between vectors to distance between them and c
    float s000 = dot(d000, v000);
    float s100 = dot(d100, v100);
    float s010 = dot(d010, v010);
    float s110 = dot(d110, v110);

    float s001 = dot(d001, v001);
    float s101 = dot(d101, v101);
    float s011 = dot(d011, v011);
    float s111 = dot(d111, v111);

    float v[8] = { s000, s100, s010, s110, s001, s101, s011, s111 };
    return triquinticInterpolation(v, frac(c));
}


#endif // CG_RANDOM_INCLUDED
