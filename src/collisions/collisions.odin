package collisions

import rl "vendor:raylib"
import "core:math"

Polygon :: struct {
	vertices: [dynamic]rl.Vector2,
}

Collision_Data :: struct {
	collided: bool,
	normal: rl.Vector2,
	depth: f32,
}




checkCollision :: proc(a, b: Polygon) -> Collision_Data {
	minDepth := math.INF_F32
	pushNormal := rl.Vector2{}

	polygons := [2]Polygon{a, b}
	for poly in polygons {
		for i := 0; i < len(poly.vertices); i += 1 {
			v1 : rl.Vector2 = poly.vertices[i]
			v2 : rl.Vector2 = poly.vertices[(i+1) % len(poly.vertices)]

			edge := v2 - v1

			axis := rl.Vector2{-edge.y, edge.x}
			axis = rl.Vector2Normalize(axis)

			minA, maxA := project_polygon(a, axis)
			minB, maxB := project_polygon(b, axis)

			if (minA >= maxB || minB >= maxA) {
				return Collision_Data{collided = false}
			}

			axisDepth := math.min(maxA, maxB) - math.max(minA, minB)

			if (axisDepth < minDepth) {
				minDepth = axisDepth
				pushNormal = axis
			}
		}
	}

	centerA := get_polygon_centre(a)
	centerB := get_polygon_centre(b)
	dir := centerB - centerA
	if (rl.Vector2DotProduct(dir, pushNormal) < 0) {
		pushNormal = -pushNormal
	}

	return {
		collided = true,
		normal= pushNormal,
		depth = minDepth,
	}
}

project_polygon :: proc(poly: Polygon, axis: rl.Vector2) -> (f32, f32) {
	minVal := rl.Vector2DotProduct(poly.vertices[0], axis)
	maxVal := minVal

	for i := 1; i < len(poly.vertices); i += 1 {
		proj := rl.Vector2DotProduct(poly.vertices[i], axis)
		if proj < minVal do minVal = proj
		if proj > maxVal do maxVal = proj
	}

	return minVal, maxVal
}

get_polygon_centre :: proc(poly: Polygon) -> rl.Vector2 {
	total := rl.Vector2{}
	for v in poly.vertices {
		total += v
	}
	return total / f32(len(poly.vertices))
}

