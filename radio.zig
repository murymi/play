const std = @import("std");
const vec = std.ArrayList;
const Group = @import("radiogroup.zig");
const rlib = @cImport({
    @cInclude("raylib.h");
});
//var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const Self = @This();
pub const Cb = fn (radio: *Self) void;

text: [*c]const u8 = "radio",
on: bool = false,
rect: rlib.Rectangle = .{ .x = 0, .y = 0, .height = 30, .width = 30 },
color: rlib.Color = rlib.BLUE,
group: ?*Group = null,

pub fn draw(self: *Self) void {
    rlib.DrawRectangleLinesEx(self.rect, 5, self.color);

    if (self.on) {
        rlib.DrawCircleV(rlib.Vector2{ .x = self.rect.x + self.rect.width/2,
         .y = self.rect.y + self.rect.height/2 }, 7,self.color);
    }
}

pub fn toggle(self: *Self) void {
    if (self.group) |g| {
        for (g.radios) |*r| {
            r.on = false;
        }
        self.on = true;
    } else {
        self.on = !self.on;
    }
}

pub fn onclick(self: *Self, cb: Cb) void {
    if (rlib.CheckCollisionPointRec(rlib.GetMousePosition(), self.rect) and rlib.IsCursorOnScreen() and
        rlib.IsMouseButtonDown(rlib.MOUSE_BUTTON_LEFT))
    {
        //std.debug.print("=================\n", .{});
        cb(self);
        
    }
}

fn callb(r: *Self) void {
    r.toggle();
}

pub fn main() !void {
    rlib.InitWindow(600, 600, "button");
    rlib.SetTargetFPS(30);
    var radio = Self{ .on = true };
    while (!rlib.WindowShouldClose()) {
        radio.onclick(callb);
        rlib.BeginDrawing();
        rlib.ClearBackground(rlib.WHITE);
        radio.draw();
        rlib.EndDrawing();
    }

    rlib.CloseWindow();
}
