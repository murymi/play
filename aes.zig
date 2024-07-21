const std = @import("std");
const x = std.crypto.dh.X25519;

const y = std.crypto.ecc.Curve25519;

pub fn main() !void {
    //var seed = [1]u8{0} ** 32;
    //const peer1_pair = try x.KeyPair.create(null);
    //const peer2_pair = try x.KeyPair.create(null);
    //_ = peer2_pair;

    const bytes0 = [1]u8{0} ** 32;
    const bytes1 = [1]u8{1} ** 32;


    const c1 = y.fromBytes(bytes0);
    const c2 = y.fromBytes(bytes1);

    c1.
    //_= j;

}