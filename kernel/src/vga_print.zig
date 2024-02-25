//
// Made with <3 by Olaru Paul-Stelian
//

const font = @import("bootfon.zig").uni_font;
const limine = @import("limine");
const std = @import("std");
const Writer = @import("std").io.Writer;

var fb: ?*limine.Framebuffer = null;
var crt_line: u16 = 0;
var crt_col: u16 = 0;
var lines_count: u16 = 0;
var cols_count: u16 = 0;

pub fn init(new_fb: *limine.Framebuffer) void {
    fb = new_fb;
    lines_count = @intCast(@divTrunc(new_fb.height, 16));
    cols_count = @intCast(@divTrunc(new_fb.pitch, 4 * 8));
    crt_line = 0;
    crt_col = 0;
}

fn print_char_noadvance(char: u8) void {
    const fb2 = fb orelse return;
    const char2: u32 = char;
    const font_entry = font[char2];
    var pixel_offset = crt_line * fb2.pitch * 16;
    pixel_offset += crt_col * 4 * 8;
    for (0..16) |i| {
        const line = font_entry[i];
        const fb_buf: [*]u32 = @ptrCast(@alignCast(fb2.address + pixel_offset));
        for (0..8) |j| {
            const shifted = std.math.shl(u8, 1, j);
            const has_bit = (line & shifted) != 0;
            if (has_bit) {
                fb_buf[7 - j] = 0xFFFFFFFF;
            } else {
                fb_buf[7 - j] = 0;
            }
        }
        pixel_offset += fb2.pitch;
    }
}

fn scroll_screen() void {
    // Note: this only scrolls the screen if there's an actual need to
    if (fb) |fb2| {
        while (crt_col >= cols_count) {
            crt_col -= cols_count;
            crt_line += 1;
        }
        while (crt_line >= lines_count) {
            const lines_to_scroll = @min(crt_line - lines_count + 1, lines_count - 1);
            const length = fb2.pitch * 16 * (lines_count - lines_to_scroll);
            const dest = fb2.address[0..length];
            const src_start = fb2.address + (fb2.pitch * 16 * lines_to_scroll);
            const src = src_start[0..length];
            const zero_start = fb2.address + (fb2.pitch * 16 * (lines_count - lines_to_scroll));
            const zero_length = fb2.height * fb2.pitch - (fb2.pitch * 16 * (lines_count - lines_to_scroll));
            const zero_slice = zero_start[0..zero_length];
            std.mem.copyForwards(u8, dest, src);
            @memset(zero_slice, 0);
            crt_line -= lines_to_scroll;
        }
    }
}

pub fn clear_screen() void {
    if (fb) |fb2| {
        const length = fb2.pitch * fb2.height;
        const slice = fb2.address[0..length];
        @memset(slice, 0);
        crt_col = 0;
        crt_line = 0;
    }
}

pub fn print_char(char: u8) void {
    scroll_screen();
    if (char == '\r') {
        // Reset to beginning of line
        crt_col = 0;
        return;
    }
    if (char == '\n') {
        // Reset to next line
        crt_col = 0;
        crt_line += 1;
        scroll_screen();
        return;
    }
    raw_print_char(char);
}

pub fn print_string(str: []const u8) void {
    for (str) |chr| {
        print_char(chr);
    }
}

pub fn raw_print_char(char: u8) void {
    scroll_screen(); // Just in case manual changes to position
    print_char_noadvance(char);
    crt_col += 1;
    scroll_screen();
}

fn writer_func(context: void, bytes: []const u8) error{}!usize {
    print_string(bytes);
    _ = context;
    return bytes.len;
}

pub fn writer() Writer(void, error{}, writer_func) {
    return .{ .context = undefined };
}
