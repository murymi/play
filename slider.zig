const std = @import("std");
const vec = std.ArrayList;
const Group = @import("radiogroup.zig");
const rlib = @cImport({
    @cInclude("raylib.h");
});
//var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const Self = @This();
pub const Cb = fn (radio: *Self) void;


rect: rlib.Rectangle = .{.x = 20, .y = 20, .height = 10, .width = 100},
thumb_pos: f32 = 1,
color: rlib.Color = rlib.BLUE,

fn draw(self: *Self) void {
    rlib.DrawRectangleRounded(self.rect, 1,50, self.color);
    rlib.DrawCircleV(rlib.Vector2{
        .x = self.rect.width * self.thumb_pos + self.rect.x,
        .y = self.rect.y + self.rect.height/2
    }, self.rect.height, rlib.RED);
}

fn onclick(self: *Self, cb: Cb) void {
    if (rlib.CheckCollisionPointRec(rlib.GetMousePosition(), self.rect) and rlib.IsCursorOnScreen() and
        rlib.IsMouseButtonDown(rlib.MOUSE_BUTTON_LEFT))
    {
        //std.debug.print("=================\n", .{});
        cb(self);
    }
}

fn callback(self: *Self) void {
    const mouse_pos = rlib.GetMousePosition();
    self.thumb_pos = (mouse_pos.x - self.rect.x)/self.rect.width;
}

pub fn main() !void {
    rlib.InitWindow(600, 600, "button");
    rlib.SetTargetFPS(30);
    var slider = Self{};
    while (!rlib.WindowShouldClose()) {
        rlib.BeginDrawing();
        rlib.ClearBackground(rlib.WHITE);
        slider.draw();
        slider.onclick(callback);
        rlib.EndDrawing();
    }

    rlib.CloseWindow();
}