// Implements an adjusted version of the Blinn-Phong lighting model
float3 blinnPhong(float3 n, float3 v, float3 l, float shininess, float3 albedo)
{
    float3 Diffuse = max(0, dot(n, l)) * albedo; 
    float3 h = normalize(v + l); // half-vector: v + l / || v + l ||
    float3 Specular = pow(max(0, dot(n, h)), shininess) * 0.4;
    return Diffuse + Specular;
}

// Reflects the given ray from the given hit point
void reflectRay(inout Ray ray, RayHit hit)
{
    // reflection direction as we see in TA7 slide 65 - r = 2(v · n)n – v
    float3 r = (2 * dot(-ray.direction, hit.normal) * hit.normal) + ray.direction;
    ray.origin = (EPS * hit.normal) + hit.position; // offset position
    ray.direction = normalize(r);
    ray.energy *= hit.material.specular; // update energy
}

// Refracts the given ray from the given hit point
void refractRay(inout Ray ray, RayHit hit)
{
    // the formula from TA8 
    float eta_ratio = 1 / hit.material.refractiveIndex; // given
    float3 i = ray.direction;
    float3 normal = hit.normal;
    if (dot(i, hit.normal) > 0){// decide if we are exiting
        normal = -hit.normal;
        eta_ratio = hit.material.refractiveIndex; // update eta if we are exiting
    }
    float c1 = abs(dot(normal, i));
    float c2 = sqrt(1.0 - (eta_ratio * eta_ratio) * (1.0 - (c1 * c1)));
    //t = η i + (ηc1 – c2) n
    float3 t = (eta_ratio * i) + (((eta_ratio * c1) - c2) * normal);
    ray.origin = (EPS * t) + hit.position; // offset position
    ray.direction = normalize(t);
}

// Samples the _SkyboxTexture at a given direction vector
float3 sampleSkybox(float3 direction)
{
    float theta = acos(direction.y) / -PI;
    float phi = atan2(direction.x, -direction.z) / -PI * 0.5f;
    return _SkyboxTexture.SampleLevel(sampler_SkyboxTexture, float2(phi, theta), 0).xyz;
}