const std = @import("std");
const rlib = @cImport({
    @cInclude("raylib.h");
});

const Self = @This();

const Gravity = enum { left, right, top, bottom, center, none };

rect: rlib.Rectangle = .{ .height = 20, .width = 20, .x = 0, .y = 0 },
bg_color: rlib.Color = rlib.WHITE,
color: rlib.Color = rlib.BLACK,
text: [*c]const u8 = "button",
font_size: c_int = 20,
roundness: f32 = 0,
margin: f32 = 0,
padding_left: f32 = 0,
padding_right: f32 = 0,
padding_top: f32 = 0,
padding_bottom: f32 = 0,
auto_height: bool = true,
auto_width: bool = true,
gravity: Gravity = .none,

fn init() *Self {
    return Self{};
}

const Cb = fn (btn: *Self) void;

fn onHover(self: *Self, cb: Cb) void {
    if (rlib.CheckCollisionPointRec(rlib.GetMousePosition(), self.rect) and rlib.IsCursorOnScreen()) {
        cb(self);
    }
}

fn onClick(self: *Self, cb: Cb) void {
    if (rlib.CheckCollisionPointRec(rlib.GetMousePosition(), self.rect) and rlib.IsCursorOnScreen() and rlib.IsMouseButtonDown(rlib.MOUSE_BUTTON_LEFT)) {
        cb(self);
    }
}

fn callbackhover(btn: *Self) void {
    btn.text = "hovered by user";
}

fn callbackclick(btn: *Self) void {
    btn.text = "clicked by user";
}

fn draw(self: *Self) void {
    const font_width: f32 = @floatFromInt(rlib.MeasureText(self.text, self.font_size));
    const font_height: f32 = @floatFromInt(self.font_size);
    if (self.rect.width < font_width + self.padding_left + self.padding_right and self.auto_width) {
        self.rect.width = font_width + self.padding_left + self.padding_right;
    }
    if (self.rect.height < font_height + self.padding_bottom + self.padding_top and self.auto_height) {
        self.rect.height = font_height + self.padding_bottom + self.padding_top;
    }
    //rlib.DrawRectangleRec(self.rect, self.bg_color);
    rlib.DrawRectangleRounded(self.rect, self.roundness, 1, self.bg_color);
    switch (self.gravity) {
        .none => rlib.DrawText(self.text, @intFromFloat(self.rect.x + self.padding_left), @intFromFloat(self.rect.y + self.padding_top), self.font_size, self.color),
        .right => rlib.DrawText(self.text, @intFromFloat(self.rect.x + self.rect.width - font_width), @intFromFloat(self.rect.y + self.padding_top), self.font_size, self.color),
        .left => rlib.DrawText(self.text, @intFromFloat(self.rect.x), @intFromFloat(self.rect.y + self.padding_top), self.font_size, self.color),
        .top => rlib.DrawText(self.text, @intFromFloat(self.rect.x + self.padding_left), @intFromFloat(self.rect.y), self.font_size, self.color),
        .bottom => rlib.DrawText(self.text, @intFromFloat(self.rect.x + self.padding_left), @intFromFloat(self.rect.y + self.rect.height - font_height), self.font_size, self.color),
        else =>
            rlib.DrawText(self.text,
            @intFromFloat(self.rect.x + self.rect.width/2 - font_width/2),
             @intFromFloat(self.rect.y + self.rect.height/2 - font_height/2),
              self.font_size, self.color)
    }
}

pub fn main() !void {
    rlib.InitWindow(600, 600, "button");
    rlib.SetTargetFPS(30);
    var btn = Self{ .rect = .{ .x = 0, .y = 0, .height = 0, .width = 0 },
     .bg_color = rlib.RED,
      .roundness = 0.1,
       .padding_right = 10,
        .padding_left = 20,
         .padding_bottom = 30,
          .padding_top = 20,
          .gravity = .center };
    while (!rlib.WindowShouldClose()) {
        rlib.BeginDrawing();
        rlib.ClearBackground(rlib.WHITE);
        btn.draw();
        btn.onClick(callbackclick);
        //rlib.CheckCollisionPointRec(, rec: Rectangle)
        rlib.EndDrawing();
    }

    rlib.CloseWindow();
}
