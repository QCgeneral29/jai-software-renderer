#import "Basic";
#import "Math";
#import "Random";
#import "Command_Line";
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

Arguments :: struct {
    lines   : int = 1 << 24; @"?The number of lines to draw."
    width   : u32 = 64; @"?The width of the outputted image."
    height  : u32 = 64; @"?The height of the outputted image."
}

main :: () {
    success, args, is_set := parse_arguments(Arguments);
    if !success {
        // Will also exit the program when -help is called.
        return;
    }

    using args;

    framebuffer := create_TGAImage(width, height, Format.RGB);

    print("Drawing % lines...\n", args.lines);

    for 0..lines {
        ax : u64 = random_get() % width;
        ay : u64 = random_get() % height;
        bx : u64 = random_get() % width;
        by : u64 = random_get() % height;
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