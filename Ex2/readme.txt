212125678 pnina_ei
207501594 elizabeth_p1


answer to 1.6:
Flat shading requires that each polygonal face be shaded using a single, uniform normal vector. 
This ensures that all points on the face receive the same lighting result, giving the characteristic “faceted” appearance.

By duplicating the vertices for every face, we ensure that no vertex is shared. 
Each copy can then be assigned the exact geometric normal of its corresponding face, without averaging. 
Because the three vertices of the triangle all hold the same normal, the interpolation across the triangle remains constant. 
As a result, the entire face receives a uniform shading value, and hard edges appear between faces.

In summary, separating vertices per face prevents normal sharing and averaging, allowing each face to maintain a single, un-interpolated normal vector.
This is precisely what produces flat shading.