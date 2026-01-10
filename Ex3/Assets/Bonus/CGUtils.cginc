#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData
{ 
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    // All the calculation from TA5
    float r = sqrt((pos.x * pos.x) + (pos.y * pos.y) + (pos.z * pos.z));
    float theta = atan2(pos.z, pos.x);
    float phi = acos(pos.y / r);

    float u = 0.5 + (theta / (2 * PI));
    float v = 1 - (phi / PI);
    return float2(u, v);
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
    fixed4 ambient = ambientIntensity * albedo;
    fixed4 diffuse = max(0, dot(n, l)) * albedo;
    float3 h = normalize(l + v); 
    fixed4 specular = pow(max(0, dot(n, h)), shininess) * specularity;
    return ambient.rgb + diffuse.rgb + specular.rgb;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{   
    // i.uv is p in the TA slides
    
    // slope in the v direction
    // f_v’(p) ≈ [f(p + dv) – f(p)] / dv
    float slope_v = (tex2D(i.heightMap, i.uv + float2(0, i.dv)).r - tex2D(i.heightMap, i.uv).r) / i.dv;
    fixed3 t_v = float3(0, 1, slope_v * i.bumpScale);

    // slope in the u direction
    // this is the formula f_u’(p) ≈ [f(p + du) – f(p)] / du
    float slope_u = (tex2D(i.heightMap, i.uv + float2(i.du, 0)).r - tex2D(i.heightMap, i.uv).r) / i.du;
    fixed3 t_u = float3(1, 0, slope_u * i.bumpScale);
    
    // n_h = cross(t_u, t_v)
    float3 n_h = cross(t_u, t_v);
    n_h = normalize(n_h);

    // t and n to world space
    float3 worldTangent = normalize(i.tangent);
    float3 worldNormal = normalize(i.normal);

    // b = cross(n, t)
    float3 worldBitangent = normalize(cross(worldNormal, worldTangent));

    // n_world = world space normal
    float3 n_world = n_h.x * worldTangent  + n_h.z * worldNormal + n_h.y * worldBitangent;
    return normalize(n_world);
}


#endif // CG_UTILS_INCLUDED
