const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    for(builtin.test_functions) |f| {
        std.debug.print("{s}", .{f.name});
    }
}