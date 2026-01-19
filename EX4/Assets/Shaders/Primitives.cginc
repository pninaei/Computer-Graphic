// Checks for an intersection between a ray and a sphere
// The sphere center is given by sphere.xyz and its radius is sphere.w
void intersectSphere(Ray ray, inout RayHit bestHit, Material material, float4 sphere)
{
    // We take that from TA7-page 30 
    float A = 1.0; // d∙d = 1
    float B = 2 * dot((ray.origin - sphere.xyz), ray.direction); // 2(o – c)∙d 
    float C = dot((ray.origin - sphere.xyz), (ray.origin - sphere.xyz)) - (sphere.w * sphere.w);// (o – c)∙(o – c) – r^2
    
    float discriminant = (B * B) - (4 * A * C);
    if (discriminant == 0) { // one hit point
        float t = -B / (2 * A);
        if (t > 0 && t < bestHit.distance) {
            bestHit.distance = t;
            bestHit.material = material;
            bestHit.position = ray.origin + t * ray.direction;
            bestHit.normal = normalize(bestHit.position - sphere.xyz);
        }
    }
    else if (discriminant > 0) { // two hit points
        float sqrtDiscriminant = sqrt(discriminant);
        float t1 = (-B - sqrtDiscriminant) / (2 * A);
        float t2 = (-B + sqrtDiscriminant) / (2 * A);
        
        
        float t_minimal = -1.0f;  // means "no valid intersection"

        if (t1 > 0 && t2 > 0) {
            t_minimal = min(t1, t2);
        } else if (t1 > 0) {
            t_minimal = t1;
        } else if (t2 > 0) {
            t_minimal = t2;
        }
        // Check the minimal root - according to slide 32 in TA7
        if (t_minimal > 0 && t_minimal < bestHit.distance) {
            bestHit.distance = t_minimal;
            bestHit.material = material;
            bestHit.position = ray.origin + t_minimal * ray.direction;
            bestHit.normal = normalize(bestHit.position - sphere.xyz);
        }
    }
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
void intersectPlane(Ray ray, inout RayHit bestHit, Material material, float3 c, float3 n)
{
    // As we see in TA7 slide 35 t = (– (o – c) ∙ n)  / d ∙ n
    float denominator = dot(ray.direction, n);
    if (denominator != 0) {
        float t = -(dot((ray.origin - c), n)) / denominator;
        // if t is not parallel to the plane
        if (t > 0 && t < bestHit.distance) {
            bestHit.distance = t;
            bestHit.material = material;
            bestHit.position = ray.origin + t * ray.direction;
            bestHit.normal = n;
        }
    }
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
// The material returned is either m1 or m2 in a way that creates a checkerboard pattern 
void intersectPlaneCheckered(Ray ray, inout RayHit bestHit, Material m1, Material m2, float3 c, float3 n)
{
    // calling the intersectPlane function to get the intersection details
    RayHit tempHit;
    tempHit = bestHit; // initialize tempHit with bestHit values
    intersectPlane(ray, tempHit, m1, c, n);
    if (tempHit.distance < bestHit.distance) {
        // Determine which material to use based on the hit position
        float2 uv = tempHit.position.xz / 0.5; // scale the xz coordinates
        int checkX = (int)floor(uv.x);
        int checkZ = (int)floor(uv.y);
        int check = (checkX + checkZ) & 1;
        if (check == 0) 
            tempHit.material = m1;
        else
            tempHit.material = m2;
        
        bestHit = tempHit;
    }
}


// Checks for an intersection between a ray and a triangle
// The triangle is defined by points a, b, c
void intersectTriangle(Ray ray, inout RayHit bestHit, Material material, float3 a, float3 b, float3 c, bool drawBackface = false)
{
   // As we see in TA7 slide 39 n = (a – c)×(b – c) / ||(a – c)×(b – c)||
    float3 n = normalize(cross((a-c), (b-c)));
    float denominator = dot(ray.direction, n);
    if (denominator == 0){
        return;
    }
    if (!drawBackface && denominator > 0.0) return; // the denominator is positive when the ray comes from the back face

    float t = -(dot((ray.origin - c), n)) / denominator;

    if (t > 0 && t < bestHit.distance){
        float3 p = ray.origin + (t * ray.direction);
        // (b – a)×(p – a) ∙ n ≥ 0
        float ab = dot(cross((b - a), (p - a)), n);
        // (c – b)×(p – b) ∙ n ≥ 0
        float bc = dot(cross((c - b), (p - b)), n);
        // (a – c)×(p – c) ∙ n ≥ 0
        float ac = dot(cross((a - c), (p - c)), n);

        if (ab >= 0 && bc >= 0 && ac >= 0){ // if the point p inside the triangle
            
            bestHit.distance = t;
            bestHit.material = material;
            bestHit.position = p;
            bestHit.normal = n;
        }
     }
    
}


// Checks for an intersection between a ray and a 2D circle
// The circle center is given by circle.xyz, its radius is circle.w and its orientation vector is n 
void intersectCircle(Ray ray, inout RayHit bestHit, Material material, float4 circle, float3 n, bool drawBackface = false)
{
    // check is intersect plane
    RayHit tempHit;
    tempHit = bestHit; // initialize tempHit with bestHit values
    intersectPlane(ray, tempHit, material, circle.xyz, n);
    float denominator = dot(ray.direction, n);
    
    if (!drawBackface && denominator > 0.0) return; // the denominator is positive when the ray comes from the back face

    if (tempHit.distance < bestHit.distance) {
        // check if the hit point is inside the circle
        float3 hitPoint = ray.origin + (tempHit.distance * ray.direction);
        float3 toCenter = hitPoint - circle.xyz;
        
        float distSquared = dot(toCenter, toCenter);
        if (distSquared <= (circle.w * circle.w)) { // if the point is inside the circle
            bestHit = tempHit;
        }
    }
}


// Checks for an intersection between a ray and a cylinder aligned with the Y axis
// The cylinder center is given by cylinder.xyz, its radius is cylinder.w and its height is h
void intersectCylinderY(Ray ray, inout RayHit bestHit, Material material, float4 cylinder, float h)
{
    // intersect with the top and bottom planes
    intersectCircle(ray, bestHit, material, float4(cylinder.x, cylinder.y + h / 2.0, cylinder.z, cylinder.w), float3(0, 1, 0));
    intersectCircle(ray, bestHit, material, float4(cylinder.x, cylinder.y - h / 2.0, cylinder.z, cylinder.w), float3(0, -1, 0));
    
    // intersect with the cylindrical surface
    // f(P) = (Px - Cx)^2 + (Pz - Cz)^2 - r^2 = 0  for infinite cylinder
    float A = pow(ray.direction.x, 2) + pow(ray.direction.z, 2);
    float B = 2 * ((ray.origin.x - cylinder.x) * ray.direction.x + (ray.origin.z - cylinder.z) * ray.direction.z);
    float C = pow(ray.origin.x - cylinder.x, 2) + pow(ray.origin.z - cylinder.z, 2) - (cylinder.w * cylinder.w);

    float discriminant = (B * B) - (4 * A * C);
    if (discriminant == 0) {

        float t = -B / (2 * A);
        if (t > 0 && t < bestHit.distance) {
            float3 hitPoint = ray.origin + t * ray.direction;
            // check if the hit point is within the height of the cylinder
            if (hitPoint.y >= (cylinder.y - h / 2.0) && hitPoint.y <= (cylinder.y + h / 2.0)) {
                bestHit.distance = t;
                bestHit.material = material;
                bestHit.position = hitPoint;
                bestHit.normal = normalize(float3(hitPoint.x - cylinder.x, 0, hitPoint.z - cylinder.z));
            }
        }
    }
    else if (discriminant > 0) {
        float sqrtDiscriminant = sqrt(discriminant);
        float t1 = (-B - sqrtDiscriminant) / (2 * A);
        float t2 = (-B + sqrtDiscriminant) / (2 * A);

        float t_minimal = -1.0f;  // means "no valid intersection"

        if (t1 > 0 && t2 > 0) {
            t_minimal = min(t1, t2);
        } else if (t1 > 0) {
            t_minimal = t1;
        } else if (t2 > 0) {
            t_minimal = t2;
        }

        // Check the minimal root
        if (t_minimal > 0 && t_minimal < bestHit.distance) {
            float3 hitPoint = ray.origin + t_minimal * ray.direction;
            // check if the hit point is within the height of the cylinder
            if (hitPoint.y >= (cylinder.y - h / 2.0) && hitPoint.y <= (cylinder.y + h / 2.0)) {
                bestHit.distance = t_minimal;
                bestHit.material = material;
                bestHit.position = hitPoint;
                bestHit.normal = normalize(float3(hitPoint.x - cylinder.x, 0, hitPoint.z - cylinder.z));
            }
        }
        
    }

}
