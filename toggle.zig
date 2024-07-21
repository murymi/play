const std = @import("std");
const rlib = @cImport({
    @cInclude("raylib.h");
});

const Self = @This();

rect: rlib.Rectangle = .{ .x = 0, .y = 10, .height = 20, .width = 40 },
color: rlib.Color = rlib.BLUE,
on: bool = false,

fn draw(self: *Self) void {
    const roundness = self.rect.height;
    rlib.DrawRectangleRoundedLines(self.rect, roundness, 1, 2, self.color);
    switch (self.on) {
        true => rlib.DrawCircleV(.{
            .x = self.rect.x + 20 + roundness / 2,
            .y = self.rect.y + roundness / 2,
        }, roundness / 2 - 2, self.color),
        false => rlib.DrawCircleV(.{
            .x = self.rect.x + roundness / 2,
            .y = self.rect.y + roundness / 2,
        }, roundness / 2 - 2, rlib.GRAY),
    }
}

const Cb = fn (btn: *Self) void;


fn onClick(self: *Self, cb: Cb) void {
    if (rlib.CheckCollisionPointRec(rlib.GetMousePosition(), self.rect) and rlib.IsCursorOnScreen() and rlib.IsMouseButtonDown(rlib.MOUSE_BUTTON_LEFT)) {
        cb(self);
    }
}

fn callbackClick(btn: *Self) void {
    btn.on = !btn.on;
}

pub fn main() !void {
    rlib.InitWindow(600, 600, "button");
    rlib.SetTargetFPS(30);
    var radio = Self{ .on = true };
    while (!rlib.WindowShouldClose()) {
        rlib.BeginDrawing();
        rlib.ClearBackground(rlib.WHITE);
        radio.draw();
        radio.onClick(callbackClick);
        rlib.EndDrawing();
    }

    rlib.CloseWindow();
}
