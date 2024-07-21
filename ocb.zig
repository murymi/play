const std = @import("std");
const aead = std.crypto.aead;
const gcm = aead.aes_ocb;
const g = gcm.Aes128Ocb;

pub fn main() !void {
    const key = [1]u8{0} ** 16;
    const nonce = [1]u8{0} ** 12;

    const plain_text = "hello kaluluuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuiu";
    const ad = "";

    var cipher_text = [1]u8{0} ** plain_text.len;
    var tag = [1]u8{0}**16;

    var deciphered = [1]u8{0} ** plain_text.len;
    g.encrypt(&cipher_text, &tag,plain_text, ad, nonce, key);
    std.debug.print("cipher text: {s}\ntag(MAC): {s}\n", .{cipher_text, tag});

    //cipher_text[0] = 'l';

    try g.decrypt(&deciphered, &cipher_text, tag, "", nonce, key);

    std.debug.assert(std.mem.eql(u8, plain_text, &deciphered));

    std.debug.print("plain text: {s}\n", .{&deciphered});
}