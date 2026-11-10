#import "Basic";
#import "Math";
#import "Random";
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
    y := ay;
    error : int;
    for x: ax..bx {
        if steep {
            set_pixel_color(image, xx y, x, color);
        } else {
            set_pixel_color(image, x, xx y, color);
        }
        error = error + (2 * abs(by - ay));
        if error > bx - ax {
            y = y + ifx by > ay then 1 else -1;
            error = error - (2 * (bx - ax));
        }
    }
}

main :: () {
    WIDTH  :: 64;
    HEIGHT :: 64;
    framebuffer := create_TGAImage(WIDTH, HEIGHT, xx Format.RGB);

    // Around 16 million lines.
    for 0..1<<24 {
        ax : u64 = random_get() % WIDTH;
        ay : u64 = random_get() % HEIGHT;
        bx : u64 = random_get() % WIDTH;
        by : u64 = random_get() % HEIGHT;
        color : TGAColor = .{bgra = .[
            cast(u8) (random_get() % 255),
            cast(u8) (random_get() % 255),
            cast(u8) (random_get() % 255),
            cast(u8) (random_get() % 255)
            ]};
        draw_line(xx ax, xx ay, xx bx, xx by, *framebuffer, color);
    }

    write_tga_file("framebuffer.tga", *framebuffer);
}