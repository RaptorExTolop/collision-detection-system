package main

import rl "vendor:raylib"
import col "collisions"

main :: proc() {
	rl.InitWindow(1280, 720, "Collision lib")
	rl.SetExitKey(.Q)

	static := col.Polygon{}
	append(&static.vertices, rl.Vector2{100, 100})
	append(&static.vertices, rl.Vector2{280, 100})
	append(&static.vertices, rl.Vector2{280, 300})
	append(&static.vertices, rl.Vector2{100, 300})

	moving := col.Polygon{}
	append(&moving.vertices, rl.Vector2{0, 0})
	append(&moving.vertices, rl.Vector2{0, 0})
	append(&moving.vertices, rl.Vector2{0, 0})
	append(&moving.vertices, rl.Vector2{0, 0})

	for (!rl.WindowShouldClose()) {
        // 1. Grab the mouse position once
        mouse := rl.GetMousePosition()

        // 2. Define the polygon vertices cleanly based on the mouse position
        // FIXED: vertices[3] now correctly points to the bottom-left corner
        moving.vertices[0] = mouse
        moving.vertices[1] = {mouse.x + 250, mouse.y}
        moving.vertices[2] = {mouse.x + 250, mouse.y + 250}
        moving.vertices[3] = {mouse.x,       mouse.y + 250}

        // 3. Check for the collision
        colData := col.checkCollision(moving, static)

        // 4. Resolve the collision immediately so the shifted vertices are what get drawn
        if colData.collided {
            for i := 0; i < len(moving.vertices); i += 1 {
                moving.vertices[i] -= colData.normal * colData.depth
            }
        }

        // --- DRAWING ---
        rl.BeginDrawing()
        rl.ClearBackground(rl.SKYBLUE)

        // Draw Static Polygon (Using lines since it's a custom polygon struct)
        for i := 0; i < len(static.vertices); i += 1 {
            v1 := static.vertices[i]
            v2 := static.vertices[(i + 1) % len(static.vertices)]
            rl.DrawLineEx(v1, v2, 3, rl.DARKGRAY)
        }

        // Draw Moving Polygon (Red if colliding, White if free)
        color := colData.collided ? rl.RED : rl.WHITE
        for i := 0; i < len(moving.vertices); i += 1 {
            v1 := moving.vertices[i]
            v2 := moving.vertices[(i + 1) % len(moving.vertices)]
            rl.DrawLineEx(v1, v2, 3, color)
        }

        rl.EndDrawing()
    }
}
