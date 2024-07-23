const std = @import("std");
const StackTrace = std.builtin.StackTrace;
const builtin = @import("builtin");

pub fn panic(msg: []const u8, error_return_trace: ?*StackTrace, ret_addr: ?usize) noreturn {
        const first_trace_addr = ret_addr orelse @returnAddress();
        std.debug.panicImpl(error_return_trace, first_trace_addr, msg);
}

const E  = enum {};

test{

}

test {

}

pub fn main() void {
    std.debug.print("{any}", .{builtin.});
}