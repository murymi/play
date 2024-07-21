const std = @import("std");
const vec = std.ArrayList;
const Group = @import("radiogroup.zig");
const rlib = @cImport({
    @cInclude("raylib.h");
});
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const Self = @This();
pub const Cb = fn (radio: *Self) void;

text: vec(u8),
rect: rlib.Rectangle = .{ .x = 0, .y = 0, .height = 50, .width = 200 },
cursor_pos: usize = 0,
font_size: f32 = 20,
spacing: f32 = 2,

fn init() Self {
    return .{
        .text = vec(u8).init(gpa.allocator()),
    };
}

fn draw(self: *Self) !void {
    rlib.DrawRectangleLinesEx(self.rect, 2, rlib.BLACK);
    const font = rlib.GetFontDefault();
    const sf:f32 = self.font_size / @as(f32, @floatFromInt(font.baseSize)); 
    const before_cursor = if(@as(f32, @floatFromInt(self.cursor_pos)) 
    < self.rect.width/(sf * (@as(f32, @floatFromInt(font.baseSize)) + self.spacing)) )
        self.text.items[0..self.cursor_pos]
    else "";
    rlib.DrawTextEx(font, before_cursor.ptr, .{ .x = self.rect.x, .y = self.rect.y }, 
    self.font_size, self.spacing, rlib.BLACK);
    var xpos: f32 = 0;
    for(before_cursor) |c| {
        xpos += (font.recs[@intCast(c - 32)].width * sf) + self.spacing;
    }
    rlib.DrawLineEx(.{
        .x = self.rect.x + xpos,
        .y = self.rect.y
    }, .{
        .x = self.rect.x + xpos,
        .y = self.rect.y + self.font_size
    }, 1, rlib.RED);
}

pub fn main() !void {
    rlib.InitWindow(600, 600, "button");
    rlib.SetTargetFPS(30);
    var tx = Self.init();
    try tx.text.append(0);

    while (!rlib.WindowShouldClose()) {
        rlib.BeginDrawing();
        rlib.ClearBackground(rlib.WHITE);

        try tx.draw();

        switch (rlib.GetCharPressed()) {
            32...127 => |c| {
                try tx.text.insert(tx.cursor_pos, @intCast(c));
                tx.cursor_pos += 1;
            },
            else => {},
        }

        switch (rlib.GetKeyPressed()) {
            rlib.KEY_RIGHT => {
                if (tx.text.items.len > 1 and tx.cursor_pos+1 < tx.text.items.len) tx.cursor_pos += 1;
            },
            rlib.KEY_LEFT => {
                if (tx.cursor_pos > 0) tx.cursor_pos -= 1;
            },
            rlib.KEY_BACKSPACE => |key| {
                if (rlib.IsKeyDown(key)) {
                    if (tx.text.items.len > 0 and tx.cursor_pos > 0) {
                        _ = tx.text.orderedRemove(tx.cursor_pos - 1);
                        tx.cursor_pos -= 1;
                        tx.text.shrinkAndFree(tx.text.items.len);
                    }
                }
            },
            else => {},
        }

        rlib.EndDrawing();
    }

    rlib.CloseWindow();
}
