#import "Basic";
#import,file "TGAImage.jai";

white   : TGAColor : .{bgra = .[255, 255, 255, 255]};
green   : TGAColor : .{bgra = .[  0, 255,   0, 255]};
red     : TGAColor : .{bgra = .[  0,   0, 255, 255]};
blue    : TGAColor : .{bgra = .[255, 128,  64, 255]};
yellow  : TGAColor : .{bgra = .[  0, 200, 255, 255]};

main :: () {
    WIDTH  :: 64;
    HEIGHT :: 64;
    framebuffer := create_TGAImage(WIDTH, HEIGHT, xx Format.RGB);

    ax, ay : int = 7, 3;
    bx, by : int = 12, 37;
    cx, cy : int = 62, 53;

    set_pixel_color(*framebuffer, ax, ay, white);
    set_pixel_color(*framebuffer, bx, by, green);
    set_pixel_color(*framebuffer, cx, cy, yellow);

    write_tga_file("framebuffer.tga", *framebuffer);
}