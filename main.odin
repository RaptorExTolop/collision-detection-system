package main

import rl "vendor:raylib"
import col "collision-system"

main :: proc() {
	rl.InitWindow(1280, 720, "Collision lib")
	rl.SetExitKey(.Q)

	static := rl.Rectangle{400, 400, 200, 200}
	moving := rl.Rectangle{0, 0, 200, 200}
	rotation : f32 = 0

	for (!rl.WindowShouldClose()) {
		if (rl.IsKeyDown(.Z)) {
			rotation -= 100 * rl.GetFrameTime()
		}

		if (rl.IsKeyDown(.X)) {
			rotation += 100 * rl.GetFrameTime()
		}

        mouse := rl.GetMousePosition()

		moving.x = mouse.x 
		moving.y = mouse.y

		staticPoly := col.to_poly(static)
		movingPoly := col.to_poly(moving, rotation)
        
        colData := col.check_collision(&movingPoly, &staticPoly)

		// A helper to easily apply the resolution directly to a rectangle
		if colData.collided {
			// Push the rectangle out of the collider using the calculated MTV
			moving.x += colData.normal.x * colData.depth
			moving.y += colData.normal.y * colData.depth
		}

        rl.BeginDrawing()
        rl.ClearBackground(rl.SKYBLUE)
		rl.DrawFPS(0, 0)

        // Draw Static Polygon (Using lines since it's a custom polygon struct)
		rl.DrawRectanglePro(static, {}, 0, rl.GRAY)
        

        // Draw Moving Polygon (Red if colliding, White if free)
        colour := colData.collided ? rl.RED : rl.WHITE
		rl.DrawRectanglePro(moving, {}, rotation, colour)

        rl.EndDrawing()
    }
}

