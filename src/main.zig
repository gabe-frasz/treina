const std = @import("std");

const BIG_ENDIAN_MRB_BYTES = [_]u8{ 0xAA, 0x55 };
const LITTLE_ENDIAN_MRB_BYTES = [_]u8{ 0x55, 0xAA };

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 2) {
        std.debug.print("Usage: {s} <file>\n", .{args[0]});
        return;
    }

    var stdout_buf: [1024]u8 = undefined;
    var mrb_check_buf: [2]u8 = undefined;

    var writer_impl = std.Io.File.stdout().writer(io, stdout_buf[0..]);
    const writer = &writer_impl.interface;

    const file = try std.Io.Dir.cwd().openFile(io, args[1], .{});
    defer file.close(io);

    if (try file.length(io) < 512) {
        try writer.print("File too small\n", .{});
        try writer.flush();
        return;
    }

    _ = try file.readPositionalAll(io, &mrb_check_buf, 510);
    const mrb_check_buf_hex = std.fmt.bytesToHex(&mrb_check_buf, .upper);

    if (std.mem.eql(u8, &mrb_check_buf, &BIG_ENDIAN_MRB_BYTES)) {
        try writer.print("MRB is big endian: {s}\n", .{mrb_check_buf_hex});
    } else if (std.mem.eql(u8, &mrb_check_buf, &LITTLE_ENDIAN_MRB_BYTES)) {
        try writer.print("MRB is little endian: {s}\n", .{mrb_check_buf_hex});
    } else {
        try writer.print("Not a MRB: {s}\n", .{mrb_check_buf_hex});
    }

    try writer.flush();
}
