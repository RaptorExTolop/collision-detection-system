package collisions

import rl "vendor:raylib"
import "core:math"

// struct polygon
Polygon :: struct($N: i32) {
	// N is a compile time constant -> super fast and allows for many different sizes.
	// Having N as a compile time constant allows the comipler to optimize to living shit
	// while also have dynamic sizes, which a dynamic array would not allow
	vertices: [N]rl.Vector2,
}

// all of the functions to conv different things into polys.
// for example, rotated_rect_to_poly rotates a given rec by a degree
// before returning a poly
to_poly :: proc{
	tri_to_poly, 
	rect_to_poly, 
	rotated_rect_to_poly,
} 

// convert a triangle consisting of 3 vertices into a polygon of size 3
@(private)
tri_to_poly :: proc(v1, v2, v3: rl.Vector2) -> Polygon(3) {
	tri: Polygon(3)

	tri.vertices[0] = v1
	tri.vertices[1] = v2
	tri.vertices[2] = v3

	return tri
}

// Convert an rl.Rectangle to a polygon
@(private)
rect_to_poly :: proc(rect: rl.Rectangle) -> Polygon(4) {
	poly: Polygon(4)
	poly.vertices[0] = {rect.x, rect.y}
	poly.vertices[1] = {rect.x + rect.width, rect.y}
	poly.vertices[2] = {rect.x + rect.width, rect.y + rect.height}
	poly.vertices[3] = {rect.x, rect.y + rect.height}

	return poly
}

// convert an rl.Rectangle that has been rotated degrees from the top left corner to a polygon
@(private)
rotated_rect_to_poly :: proc(rect: rl.Rectangle, rotation: f32) -> Polygon(4) {
	poly: Polygon(4)

	// conv the degrees (360) into numbers for sin/cos
	angle_rad := rotation * (math.PI / 180)

	// using the top left corner as the pivot location
	pivot := rl.Vector2{rect.x, rect.y}

	poly.vertices[0] = pivot
	poly.vertices[1] = rotate_point({rect.x + rect.width, rect.y}, pivot, angle_rad)
	poly.vertices[2] = rotate_point({rect.x + rect.width, rect.y + rect.height}, pivot, angle_rad)
	poly.vertices[3] = rotate_point({rect.x, rect.y + rect.height}, pivot, angle_rad)

	return poly
}

// the data for a collision
Collision_Data :: struct {
	// has the variables collided
	collided: bool,
	// what is the direction of the collision
	normal: rl.Vector2,
	// how far inside the shape is the collision
	depth: f32,
}

// check a collision against two polygons of size N and M
check_collision :: proc(a: ^Polygon($N), b: ^Polygon($M)) -> Collision_Data {
	return sat_collision(a, b)
}

// check for the SAT collision
@(private)
sat_collision :: proc(a: ^Polygon($N), b: ^Polygon($M)) -> Collision_Data {
	// set the min depth to the max value that be stored in an f32
	// this then lets us check each value to see if it is smaller than the last one
	// starting at the max number possible
	minDepth := math.INF_F32

	// the normal vector that the rectangle should be pushed in 
	pushNormal := rl.Vector2{}

	// Array of the two polygons so we can check each ones axis.
	// We do store the two polygons as arrays of verticies as 
	// there are problems with compile time constants and the
	// way they are accessed.
	polygons := [2][]rl.Vector2{a.vertices[:], b.vertices[:]}

	// for each polygon
	for poly in polygons {
		// for the polygons vertices
		for i := 0; i < len(poly); i += 1 {
			// the current vertex
			v1 : rl.Vector2 = poly[i]
			// the next vertex, wrapping around to 0
			v2 : rl.Vector2 = poly[(i+1) % len(poly)]

			// get the edge normal
			edge := v2 - v1

			// get the 90 degree angled axis 
			axis := rl.Vector2{-edge.y, edge.x}
			// normalize the axis to 1 so we don't have large as dot products
			axis = rl.Vector2Normalize(axis)

			// get the min and max projection values for A on the given axis
			minA, maxA := project_polygon(a, axis)
			// get the min and max projection values for B on the given axis
			minB, maxB := project_polygon(b, axis)

			// the rectangles are NOT colliding on the axis we can return early
			// saving computing power and returning collidied = false
			if (minA >= maxB || minB >= maxA) {
				return Collision_Data{collided = false}
			}

			// Get the depth of the axis we have just collided on
			// useful to see which axis we need to move the rectangles on
			axisDepth := math.min(maxA, maxB) - math.max(minA, minB)

			// If the current axis depth is the new lowest depth.
			// If it is we want this axis as the current min depth.
			// We also need the push normal for this push so we can 
			// push the polygon along that axis.
			if (axisDepth < minDepth) {
				minDepth = axisDepth
				pushNormal = axis
			}
		}
	}

	// get the centre of each polygon
	centerA := get_polygon_centre(a)
	centerB := get_polygon_centre(b)

	// get the direction between the centre
	dir := centerB - centerA

	// If the dot product between the current push normal and the direction
	// is less than the zero, that means we need to move the polygon in
	// a negative axis. We then flip the push normal
	if (rl.Vector2DotProduct(dir, pushNormal) > 0) {
		pushNormal = -pushNormal
	}

	// Return that we have collided, the normal to be pushed in and the amount to be pushed out.
	return {
		collided = true,
		normal= pushNormal,
		depth = minDepth,
	}
}

// Project the given polygon along an axis
@(private)
project_polygon :: proc(poly: ^Polygon($N), axis: rl.Vector2) -> (f32, f32) {
	minVal := rl.Vector2DotProduct(poly.vertices[0], axis)
	maxVal := minVal

	for i := 1; i < len(poly.vertices); i += 1 {
		proj := rl.Vector2DotProduct(poly.vertices[i], axis)
		if proj < minVal do minVal = proj
		if proj > maxVal do maxVal = proj
	}

	return minVal, maxVal
}

// gets the center coord of the given polygon
get_polygon_centre :: proc(poly: ^Polygon($N)) -> rl.Vector2 {
	total := rl.Vector2{}
	for v in poly.vertices {
		total += v
	}
	return total / f32(len(poly.vertices))
}

// rotate a point around a point an amunt of radians
@(private)
rotate_point :: proc(point, pivot: rl.Vector2, angleRadians: f32) -> rl.Vector2 {
	// get the sin and cos values of the radians
	cos := math.cos(angleRadians)
	sin := math.sin(angleRadians)

	translated := point - pivot

	rotated := rl.Vector2 {
		translated.x * cos - translated.y * sin,
		translated.x * sin + translated.y * cos,
	}

	return rotated + pivot
}	

