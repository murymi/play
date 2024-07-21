const std = @import("std");
const vec = std.ArrayList;
const rlib = @cImport({
    @cInclude("raylib.h");
});


vecs: vec(rlib.Vector2),

