const limine = @import("limine");
const std = @import("std");
//const flanterm = @cImport({
//    @cDefine("_NO_CRT_STDIO_INLINE", "1");
//    @cInclude("flanterm/flanterm.c");
//    @cInclude("flanterm/flanterm.h");
//});
const vga = @import("vga_print.zig");

pub export var framebuffer_request: limine.FramebufferRequest = .{};

pub export var base_revision: limine.BaseRevision = .{ .revision = 1 };

pub export var terminal_request: limine.TerminalRequest = .{};

inline fn done() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

// The following will be our kernel's entry point.
export fn _start() callconv(.C) noreturn {
    if (!base_revision.is_supported()) {
        done();
    }
    if (framebuffer_request.response) |framebuffer_response| {
        if (framebuffer_response.framebuffer_count < 1) {
            done();
        }
        const framebuffer = framebuffer_response.framebuffers()[0];

        //var fl_ctx: *flanterm.ft_ctx = flanterm.flanterm_fb_simple_init(framebuffer.address, framebuffer.width, framebuffer.height, framebuffer.pitch);
        //flanterm.flanterm_write(fl_ctx, "Hello World", 11);
        vga.init(framebuffer);
        vga.print_string("C'est de la poudre de perlimpimpin");
    }

    done();
}
