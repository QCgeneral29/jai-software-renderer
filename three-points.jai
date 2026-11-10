#import "Basic";
#import "Math";
#import,file "TGAImage.jai";

WHITE   : TGAColor : .{bgra = .[255, 255, 255, 255]};
GREEN   : TGAColor : .{bgra = .[  0, 255,   0, 255]};
RED     : TGAColor : .{bgra = .[  0,   0, 255, 255]};
BLUE    : TGAColor : .{bgra = .[255, 128,  64, 255]};
YELLOW  : TGAColor : .{bgra = .[  0, 200, 255, 255]};

draw_line :: (ax: int, ay: int, bx: int, by: int, image: *TGAImage, color: TGAColor) {
    steep : bool = abs(ax - bx) < abs(ay-by);
    if steep {
        swap(*ax, *ay);
        swap(*bx, *by);
    }
    if ax > bx {
        swap(*ax, *bx);
        swap(*ay, *by);
    }
    for x: ax..bx {
        t : float32 = (x - ax) / cast(float32) (bx - ax);
        y : int = xx (ay + t * (by - ay));
        if steep {
            set_pixel_color(image, y, x, color);
        } else {
            set_pixel_color(image, x, y, color);
        }
    }
}

main :: () {
    WIDTH  :: 64;
    HEIGHT :: 64;
    framebuffer := create_TGAImage(WIDTH, HEIGHT, xx Format.RGB);

    ax, ay : int = 7, 3;
    bx, by : int = 12, 37;
    cx, cy : int = 62, 53;

    draw_line(ax, ay, bx, by, *framebuffer, RED);
    draw_line(bx, by, cx, cy, *framebuffer, GREEN);
    draw_line(cx, cy, ax, ay, *framebuffer, BLUE);

    set_pixel_color(*framebuffer, ax, ay, WHITE);
    set_pixel_color(*framebuffer, bx, by, WHITE);
    set_pixel_color(*framebuffer, cx, cy, WHITE);

    write_tga_file("framebuffer.tga", *framebuffer);
}