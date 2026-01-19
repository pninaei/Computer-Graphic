212125678 pnina_ei
207501594 elizabeth_p1

part 4.8:
First, the function calls intersectPlane using a temporary RayHit to compute the intersection point with the plane.
This ensures we reuse the correct plane–ray intersection logic without modifying the current best hit prematurely.

If the intersection is closer than the current best hit, the hit position is projected onto the XZ plane
and we scaled the coordinates by 0.5 to make them smaller and to fit to the checker size.
The coordinates are then converted to grid indices. We used the bit-wise AND with 1 (mod 2) to alternate between the two materials,
creating a checkerboard pattern.

part 5.3:
This function computes the intersection between a ray and a finite cylinder aligned with the Y axis.
First, it checks for intersections with the top and bottom circular caps by intersecting the ray with
two circles at the cylinder’s upper and lower Y positions.

Then, it computes the intersection with the cylindrical side surface by solving a quadratic equation
derived from the cylinder’s equation in the XZ plane. If a valid intersection is found, the hit point is
checked to ensure it lies within the cylinder’s height.

For a valid hit, the function updates the closest intersection data and computes the surface normal based on the hit position.
