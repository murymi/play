const std = @import("std");
const Build = std.Build;
const Builtin = @import("builtin");
const Progress = std.Progress;
const Process = std.ChildProcess;
var Gpa = std.heap.GeneralPurposeAllocator(.{}){};

//const x86_i686 = {
//    .cpu_arch = .i386,
//    .os_tag = .freestanding,
//    .cpu_model = .{ .explicit = &Target.x86.cpu._i686 },
//};

const x86 = std.Target.Query{
    .os_tag = .freestanding,
    .cpu_arch = .x86,
};

pub fn build(b: *Build) void {

    const target = b.standardTargetOptions(.{
        .default_target = x86,
        .whitelist = null
    });

    const optimize = b.standardOptimizeOption(.{});

    const compile_boot_loader = b.allocator.create(Build.Step) catch {
        @panic("mem error");
    };

    const zobj = b.addObject(.{
        .root_source_file = .{ .path = "src/kernel.zig" },
        .name = "zig-kernel-obj",
        .optimize = optimize,
        .target = target,
    });

    //zobj.setVerboseCC(true);

    //const make_ob = b.addRunArtifact(zobj);
    //const inf = b.addInstallArtifact(zobj, .{});
    //const libo = b.addStaticLibrary(.{
    //    .root_source_file = .{ .path = "src/kernel.zig" },
    //    .name = "zig-kernel-obj",
    //    .optimize = optimize,
    //    .target = target,
    //});
    //b.installArtifact(zobj.s);

    const objz = b.step("objz", "compile kernel.zig");

    objz.dependOn(&zobj.step);

    std.debug.print("{s}", .{b.install_prefix});

    

    compile_boot_loader.* = Build.Step.init(.{
        .id = .custom,
        .makeFn = compileAsm,
        .name = "compile assembly file",
        .owner = b
    });

    const compile_kernel = b.allocator.create(Build.Step) catch {
        @panic("mem error");
    };


    compile_kernel.* = Build.Step.init(.{
        .id = .custom,
        .makeFn = compileKernel,
        .name = "compile the kernel",
        .owner = b
    });

    const compile_all = b.step("compile", "compile all files");

    compile_kernel.dependOn(compile_boot_loader);
    compile_all.dependOn(compile_kernel);
    
    const make_image = b.allocator.create(Build.Step) catch {
        @panic("mem error");
    };

    make_image.* = Build.Step.init(.{
        .id = .custom,
        .makeFn = makeImage,
        .name = "make disk image",
        .owner = b
    });

    make_image.dependOn(compile_all);

    const image_step = b.step("image", "compile the bootloader");
    image_step.dependOn(make_image);

    const run_kernel = b.allocator.create(Build.Step) catch {
        @panic("mem error");
    };

    run_kernel.* = Build.Step.init(.{
        .id = .custom,
        .makeFn = runKernel,
        .name = "boot kernel",
        .owner = b
    });

    run_kernel.dependOn(make_image);

    const boot = b.step("run", "boot kernel");
    boot.dependOn(run_kernel);
}

pub fn compileAsm(step: *Build.Step, prog: *Progress.Node) !void {
    _ = step;
    _ = prog;
    std.debug.print("compiling assembly file\n", .{});
    var child_nasm = Process.init(&.{"nasm", "./src/boot.asm", "-f", "bin", "-o", "./src/boot.bin"}, Gpa.allocator());
    switch (try child_nasm.spawnAndWait()){
        .Exited => |code| if(code != 0) @panic("process exit abnormal"),
        else => @panic("process terminated"),
    }
}

pub fn compileKernel(step: *Build.Step, prog: *Progress.Node) !void {
    _ = step;
    _ = prog;
    std.debug.print("compiling Kernel\n", .{});
    
    var child_gcc = Process.init(&.{"gcc", "-ffreestanding", "-c", "./src/kernel.c", "-o", "./src/kernel.o"}, Gpa.allocator());
    switch (try child_gcc.spawnAndWait()){
        .Exited => |code| if(code != 0) @panic("process exit abnormal"),
        else => @panic("process terminated"),
    }
    
    var child_ld = Process.init(&.{"ld", "-o", "./src/kernel.bin", "-Ttext", "0x1000", "./src/kernel.o", "--oformat", "binary"}, Gpa.allocator());
    switch (try child_ld.spawnAndWait()){
        .Exited => |code| if(code != 0) @panic("process exit abnormal"),
        else => @panic("process terminated"),
    }
}

pub fn makeImage(step: *Build.Step, prog: *Progress.Node) !void {
    std.debug.print("making a disk image\n", .{});
    //_ = step;
    _ = prog;
    var child_process = Process.init(&.{"cat", "./src/boot.bin", "./src/kernel.bin"}, Gpa.allocator());
    child_process.stdin_behavior = .Ignore;
    child_process.stdout_behavior = .Pipe;
    child_process.stderr_behavior = .Pipe;
    try child_process.spawn();
    const child_output = try child_process.stdout.?.readToEndAlloc(Gpa.allocator(), 1024 * 10000);
    errdefer Gpa.allocator().free(child_output);
    switch (try child_process.wait()){
        .Exited => |code| if(code != 0) @panic("process exit abnormal"),
        else => @panic("process terminated"),
    }
    step.owner.build_root.handle.makeDir("image") catch |e| {
        switch (e) {
            error.PathAlreadyExists => {},
            else => @panic(@errorName(e))
        }
    };

    const image = try step.owner.build_root.handle.createFile("image/kernel.bin", .{.truncate = true });
    try image.writeAll(child_output);
}

pub fn runKernel(step: *Build.Step, prog: *Progress.Node) !void {
    std.debug.print("booting kernel\n", .{});
    _ = step;
    _ = prog;
    var child_qemu = Process.init(&.{"qemu-system-i386", "./image/kernel.bin"}, Gpa.allocator());
    switch (try child_qemu.spawnAndWait()){
        .Exited => |code| if(code != 0) @panic("process exit abnormal"),
        else => @panic("process terminated"),
    }
}