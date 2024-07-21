const std = @import("std");
const vec = std.ArrayList;
const Allocator = std.mem.Allocator;
const mem = std.mem;
const testing = std.testing;
const map = std.StringHashMap;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const TokenKind = enum { open_angle, close_angle, slash, ident, literal, text, equals };

const Token = struct {
    kind: TokenKind,
    slice: []const u8,
};

const TokenError = error{ InvalidCharacter, UnclosedComment, UnclosedLiteral, UnclosedTag };

const Tokenizer = struct {
    current: usize = 0,
    allocator: Allocator,

    const Self = @This();
    fn tokenize(self: *Self, source: []const u8) !vec(Token) {
        var tokens = vec(Token).init(self.allocator);
        var out = true;

        while (self.current < source.len) {
            self.current += switch (source[self.current]) {
                ' ', '\t', '\r', '\n' => 1,
                '<' => block: {
                    const upperbound = @min(source.len - self.current, 4);
                    const comment_start = mem.indexOfPos(u8, source[self.current .. self.current + upperbound], 0, "<!--");
                    if (comment_start) |cs| {
                        const comment_end = mem.indexOfPos(u8, source[self.current + cs + 4 ..], 0, "-->");
                        if (comment_end) |ce| {
                            break :block ce + 4 + 3 + 0;
                        } else return error.UnclosedComment;
                    } else if (upperbound > 0 and source[self.current + 1] == '!') {
                        const tag_end = mem.indexOfPos(u8, source[self.current + 1 + 1 ..], 0, ">");
                        if (tag_end) |te| {
                            break :block te + 1 + 1 + 0;
                        } else return error.UnclosedTag;
                    } else {
                        try tokens.append(Token{ .slice = source[self.current .. self.current + 1], .kind = .open_angle });
                        out = false;
                        break :block 1;
                    }
                },
                '>' => block: {
                    try tokens.append(Token{ .slice = source[self.current .. self.current + 1], .kind = .close_angle });
                    out = true;
                    break :block 1;
                },
                '/' => block: {
                    try tokens.append(Token{ .slice = source[self.current .. self.current + 1], .kind = .slash });
                    break :block 1;
                },
                '=' => block: {
                    try tokens.append(Token{ .slice = source[self.current .. self.current + 1], .kind = .equals });
                    break :block 1;
                },
                '\'', '"' => block: {
                    const end = mem.indexOfPos(u8, source[self.current + 1 ..], 0, source[self.current .. self.current + 1]);
                    const token =
                        if (end) |e|
                        Token{ .kind = .literal, .slice = source[self.current + 1 .. self.current + e + 1] }
                    else
                        return error.UnclosedLiteral;
                    try tokens.append(token);
                    break :block end.? + 2;
                },
                else => |c| block: {
                    if (isAlpha(c)) {
                        var end = self.current + 1;
                        if (!out) {
                            while (end < source.len and isAlnum(source[end])) : (end += 1) {}
                            try tokens.append(Token{ .kind = .ident, .slice = source[self.current..end] });
                            break :block end - self.current;
                        } else {
                            const tag_start = mem.indexOfPos(u8, source[end..], 0, "<");
                            if (tag_start) |ts| {
                                const tok = Token{ .kind = .text, .slice = source[self.current .. self.current + ts + 1] };
                                try tokens.append(tok);
                                break :block ts + 1;
                            } else {
                                return error.UnclosedTag;
                            }
                        }
                    }
                    return error.InvalidCharacter;
                },
            };
        }
        return tokens;
    }

    fn isAlpha(c: u8) bool {
        return c >= 'a' and c <= 'z' or c >= 'A' and c <= 'Z';
    }

    fn isNum(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAlnum(c: u8) bool {
        return isNum(c) or isAlpha(c);
    }
};

test "tokenize" {
    var tokenizer = Tokenizer{ .allocator = gpa.allocator() };
    _ = try tokenizer.tokenize("<t a='b'><!-- -->hello world<!---->shame</>");
    _ = tokenizer.tokenize("<") catch |e| {
        try testing.expectEqual(error.UnclosedTag, e);
    };
    _ = tokenizer.tokenize("<><!--") catch |e| {
        try testing.expectEqual(error.UnclosedComment, e);
    };
    _ = tokenizer.tokenize("'") catch |e| {
        try testing.expectEqual(error.UnclosedLiteral, e);
    };
    _ = tokenizer.tokenize("-") catch |e| {
        try testing.expectEqual(error.InvalidCharacter, e);
    };
    const a = try tokenizer.tokenize("a a a<!----> a a<!> a a a");
    for (a.items) |tok| {
        try testing.expectEqualStrings("a", tok.slice);
    }
}

const ParseError = error{ UnexpectedToken, EarlyEndOfStream, OutOfMemory };

const Parser = struct {
    current: usize = 0,
    tokens: []Token,
    allocator: Allocator,

    const Self = @This();
    fn match(self: *Self, kinds: []const TokenKind) bool {
        if (!self.more()) return false;
        for (kinds) |kind| {
            if (self.tokens[self.current].kind == kind) {
                self.current += 1;
                return true;
            }
        }
        return false;
    }

    fn peek(self: *Self) Token {
        return self.tokens[self.current];
    }

    fn peek2nd(self: *Self) ?Token {
        if (self.current + 1 < self.tokens.len) {
            return self.tokens[self.current + 1];
        }
        return null;
    }

    fn peek3rd(self: *Self) ?Token {
        if (self.current + 2 < self.tokens.len) {
            return self.tokens[self.current + 1];
        }
        return null;
    }

    fn consume(self: *Self) ?Token {
        if (!self.more()) return null;
        self.current += 1;
        return self.tokens[self.current - 1];
    }

    fn more(self: *Self) bool {
        return self.current < self.tokens.len;
    }

    fn previous(self: *Self) Token {
        return self.tokens[self.current - 1];
    }

    fn attributes(self: *Self, store: *map([]const u8)) !void {
        while (self.more()) {
            const pk = self.peek();
            if (pk.kind == .close_angle or pk.kind == .slash) break;
            const key = try self.demand(.ident);
            if (self.match(&[_]TokenKind{.equals})) {
                if (self.match(&[_]TokenKind{ .literal, .ident })) {
                    try store.put(key.slice, self.previous().slice);
                } else try self.expect(.literal);
            } else {
                try store.put(key.slice, "");
            }
        }
    }

    fn children(self: *Self, parent: *Node) !void {
        while (self.more()) {
            if (self.peek().kind == .open_angle) {
                if (self.peek2nd()) |tok| {
                    if (tok.kind == .slash) {
                        return;
                    }
                }
            }
            if (self.match(&[_]TokenKind{.text})) {
                var txt = vec(u8).init(self.allocator);
                try txt.appendSlice(self.previous().slice);
                try parent.text.append(txt);
            } else {
                try parent.children.append(try self.tag(parent));
            }
        }
    }

    fn demand(self: *Self, kind: TokenKind) !Token {
        if (self.consume()) |tok| {
            if (tok.kind != kind) {
                return error.UnexpectedToken;
            }
            return tok;
        } else return error.EarlyEndOfStream;
    }

    fn expect(self: *Self, kind: TokenKind) !void {
        if (self.consume()) |tok| {
            if (tok.kind != kind) {
                return error.UnexpectedToken;
            }
        } else return error.EarlyEndOfStream;
    }

    fn tag(self: *Self, parent: *Node) ParseError!Node {
        try self.expect(.open_angle);
        const tag_name = try self.demand(.ident);
        var node = try Node.init(self.allocator, tag_name.slice);
        node.parent = parent;
        try self.attributes(&node.attributes);
        if (self.match(&[_]TokenKind{.slash})) {
            try self.expect(.close_angle);
            return node;
        }
        try self.expect(.close_angle);
        try self.children(&node);
        try self.expect(.open_angle);
        try self.expect(.slash);
        if (self.consume()) |tok| {
            if (!mem.eql(u8, tag_name.slice, tok.slice)) {
                std.debug.panic("invalid close tag name {s}: {s}", .{ tag_name.slice, tok.slice });
            }
        }
        try self.expect(.close_angle);
        return node;
    }

    fn parse(self: *Self) !Dom {
        var dom = Dom{ .root = try Node.init(self.allocator, "root") };
        try self.children(&dom.root);
        return dom;
    }
};

const Node = struct {
    parent: ?*Node = null,
    tagname: []const u8,
    attributes: map([]const u8),
    children: vec(Node),
    text: vec(vec(u8)),
    allocator: Allocator,

    const Self = @This();
    fn init(allocator: Allocator, tagname: []const u8) !Self {
        return .{ .attributes = map([]const u8).init(allocator), .children = vec(Node).init(allocator), .tagname = try allocator.dupe(u8, tagname), .text = vec(vec(u8)).init(allocator), .allocator = allocator };
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.tagname);
        self.attributes.deinit();
        for (self.text.items) |txt| {
            txt.deinit();
        }
        self.text.deinit();
        for (self.children.items) |*child| {
            child.deinit();
        }
        self.children.deinit();
    }

    fn getElementByTagName(self: *Self, tagname: []const u8) ?Node {
        for (self.children.items) |child| {
            if (mem.eql(u8, child.tagname, tagname)) {
                return child;
            }
        }
        return null;
    }

    fn getElementsByTagName(self: *Self, tagname: []const u8) !vec(Node) {
        var list = vec(Node).init(self.allocator);
        for (self.children.items) |child| {
            if (mem.eql(u8, child.tagname, tagname)) {
                try list.append(child);
            }
        }
    }

    fn getElementsByAttribute(self: *Self, attribute: []const u8, value: []const u8) !vec(Node) {
        var list = vec(Node).init(self.allocator);
        for (self.children.items) |child| {
            if (child.attributes.get(attribute)) |v| {
                if (mem.eql(u8, v, value)) {
                    try list.append(child);
                }
            }
        }
    }

    fn getElementByAttribute(self: *Self, attribute: []const u8, value: []const u8) ?Node {
        for (self.children.items) |child| {
            if (child.attributes.get(attribute)) |v| {
                if (mem.eql(u8, v, value)) {
                    return child;
                }
            }
        }
        return null;
    }

    fn getAttribute(self: *Self, attr: []const u8) ?[]const u8 {
        return self.attributes.get(attr);
    }
};

const Dom = struct {
    root: Node,
    const Self = @This();

    fn deinit(self: *Self) void {
        self.root.deinit();
    }
};


test "parse" {
    const allocator = testing.allocator;
    var tokenizer = Tokenizer{ .allocator = allocator };

    const tokens = try tokenizer.tokenize(
        \\<!-- genesis -->
        \\<haha one="1" two='2' hello=world true>
        \\<!-- wanda huhu -->
        \\  <child1 name="childone"/>
        \\<!-- zag zig -->
        \\  <child2 name= "childtwo"/>
        \\<!-- foo bar -->
        \\<!-----------------><!--------->
        \\<!------------------>
        \\
        \\  <child3 name = "childthree">
        \\      <one hoolla="balloo"/>
        \\          <!-- kisii -->
        \\      <two/>
        \\      <!---->
        \\      <three>i am third child<!------></three>
        \\      <!-- hawk tuah -->
        \\  </child3>
        \\<!---------------------------------------->
        \\</haha>
        \\<!--------------------->
    );
    defer tokens.deinit();

    var parser = Parser{ .allocator = allocator, .tokens = tokens.items };

    var dom = try parser.parse();
    defer dom.deinit();

    try testing.expectEqualStrings("haha", dom.root.children.items[0].tagname);
    var first_child = dom.root.children.items[0];
    try testing.expectEqualStrings("1", first_child.getAttribute("one").?);
    try testing.expectEqualStrings("2", first_child.getAttribute("two").?);
    try testing.expectEqualStrings("world", first_child.getAttribute("hello").?);
    try testing.expectEqualStrings("", first_child.getAttribute("true").?);
    try testing.expect(first_child.children.items.len == 3);

    var a = first_child.children.items[0];
    try testing.expectEqualStrings("child1", a.tagname);
    try testing.expectEqualStrings("childone", a.getAttribute("name").?);

    var b = first_child.children.items[2];
    try testing.expectEqualStrings("one", b.children.items[0].tagname);
    try testing.expectEqualStrings("two", b.children.items[1].tagname);
    try testing.expectEqualStrings("three", b.children.items[2].tagname);

    const c = b.getElementByTagName("three").?;
    try testing.expectEqualStrings("three", c.tagname);
    try testing.expectEqualStrings("i am third child", c.text.items[0].items);

    const d = b.getElementByAttribute("hoolla", "balloo").?;
    try testing.expectEqualStrings("one", d.tagname);
}
