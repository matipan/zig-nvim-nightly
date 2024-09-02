const std = @import("std");
const http_client = std.http.Client;

const nightly = "https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz";
const directory = "/home/matipan/bin/";
const nvim_linux = "/home/matipan/bin/nvim-linux64";
const nvim_linux_bak = "/home/matipan/bin/nvim-linux64.bak";
const nvim_tar = "nvim-linux64.tar.gz";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // if there already is a backup dir we delete it for the new backup
    std.fs.deleteTreeAbsolute(nvim_linux_bak) catch |err| {
        if (err != std.os.DeleteDirError.FileNotFound) {
            return err;
        }
    };

    // backup the existing neovim installation
    std.os.rename(nvim_linux, nvim_linux_bak) catch |err| {
        if (err != std.os.RenameError.FileNotFound) {
            return err;
        }
    };

    // create the empty file were we will write the contents of nvim
    var tar = try std.fs.createFileAbsolute(directory ++ nvim_tar, std.fs.File.CreateFlags{ .truncate = true });
    defer tar.close();

    // do you really need a comment to explain what we are doing here?
    var client = http_client{
        .allocator = allocator,
    };
    defer client.deinit();

    // download the tar file into the file we created below using the ResponseStrategy
    var result = try client.fetch(allocator, http_client.FetchOptions{
        .location = .{
            .url = nightly,
        },
        .response_strategy = .{
            .file = tar,
        },
    });
    defer result.deinit();

    // untar it and we are done!
    var tar_cmd = std.ChildProcess.init(&[_][]const u8{ "tar", "xvf", "/home/matipan/bin/nvim-linux64.tar.gz", "-C", "/home/matipan/bin/" }, allocator);
    const run_res = try tar_cmd.spawnAndWait();

    std.debug.print("run_res={any}\n", .{run_res.Exited});

    return;
}
