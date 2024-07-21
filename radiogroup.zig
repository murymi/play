const std = @import("std");
const vec = std.ArrayList;
const Radio = @import("radio.zig");
const rlib = @cImport({
    @cInclude("raylib.h");
});
//var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const Self = @This();

radios: []Radio,

fn arrange(self: *Self) void {
    for(self.radios, 0..)|*r, i| {
        r.rect.y += 50 * @as(f32,@floatFromInt(i));
        r.group = self;
    }

}

fn draw(self: *Self) void {
    var on_fond = false;
    for(self.radios) |*r| {
        if(r.on and on_fond) self.radios[0].toggle();
        if(r.on) on_fond = true;
    }
    if(!on_fond) self.radios[0].toggle();
    for(self.radios)|*r| r.draw();
}


fn cb(r: *Radio) void {
    r.toggle();
}



pub fn main() !void {
    rlib.InitWindow(600, 600, "button");
    rlib.SetTargetFPS(30);
    var gp = Self{ .radios = @constCast(&[_]Radio{
        .{
            
        },
        .{

        },
        .{

        },
        .{

        },
    })};
    gp.arrange();
    while (!rlib.WindowShouldClose()) {
        rlib.BeginDrawing();
        rlib.ClearBackground(rlib.WHITE);
        gp.draw();

        for(gp.radios) |*r| {
            r.onclick(cb);
        }
        rlib.EndDrawing();
    }

    rlib.CloseWindow();
}