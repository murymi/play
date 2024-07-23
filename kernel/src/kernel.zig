const Cell = packed struct {
    char: u8,
    args: u8 = 0x0f
};


export fn main() void {
    // Create a pointer to a char , and point it to the first text cell of
    // video memory ( i . e . the top - left of the screen )
    var video_memory = @as(*[80]Cell,  @ptrFromInt(0xb8000));
    // At the address pointed to by video_memory , store the character ’X ’
    // ( i . e . display ’X ’ in the top - left of the screen ).
    video_memory[0] = .{
        .char = 'Z'
    };
}