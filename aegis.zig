const std = @import("std");
const aegis = std.crypto.aead.aegis;

pub fn main() !void {
    const key = [1]u8{0} ** 16;
    const nonce = [1]u8{0} ** 16;

    const plain_text = "hello kalulu";
    const ad = "";

    var cipher_text = [1]u8{0} ** plain_text.len;
    var tag = [1]u8{0}**16;

    var deciphered = [1]u8{0} ** plain_text.len;
    aegis.Aegis128L.encrypt(&cipher_text, &tag,plain_text, ad, nonce, key);
    std.debug.print("cipher text: {s}\ntag(MAC): {s}\n", .{cipher_text, tag});

    cipher_text[0] = 'l';

    try aegis.Aegis128L.decrypt(&deciphered, &cipher_text, tag, "", nonce, key);

    std.debug.print("plain text: {s}\n", .{&deciphered});
}