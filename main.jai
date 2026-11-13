#import "Basic";
#import "Math";

#import,file "TGAImage.jai";
#import,file "Model.jai";

WHITE   : TGAColor : .{bgra = .[255, 255, 255, 255]};
GREEN   : TGAColor : .{bgra = .[  0, 255,   0, 255]};
RED     : TGAColor : .{bgra = .[  0,   0, 255, 255]};
BLUE    : TGAColor : .{bgra = .[255, 128,  64, 255]};
YELLOW  : TGAColor : .{bgra = .[  0, 200, 255, 255]};

WIDTH  :: 128;
HEIGHT :: 128;

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

Vertex :: struct {
    x, y: int;
}

triangle :: (ax: int, ay: int, bx: int, by: int, cx: int, cy: int, image: *TGAImage, color: TGAColor) {
    if (ay > by) {
        swap(*ax,*bx);
        swap(*ay,*by);
    } 
    if (ay > cy) {
        swap(*ax,*cx);
        swap(*ay,*cy);
    } 
    if (by > cy) {
        swap(*bx,*cx);
        swap(*by,*cy);
    } 
    total_height : int = cy-ay;
    
    if ay != by {
        segment_height := by - ay;
        for y: ay..by {
            x1 := ax + ((cx - ax) * (y - ay)) / total_height;
            x2 := ax + ((bx - ax) * (y - ay)) / segment_height;
            for x: min(x1, x2)..max(x1, x2) {
                set_pixel_color(image, x, y, color);
            }
        }
    }
    if by != cy {
        segment_height := cy - by;
        for y: by..cy {
            x1 := ax + ((cx - ax) * (y - ay)) / total_height;
            x2 := bx + ((cx - bx) * (y - by)) / segment_height;
            for x: min(x1, x2)..max(x1, x2) {
                set_pixel_color(image, x, y, color);
            }
        }
    }
}

main :: () {
    image := create_TGAImage(WIDTH, HEIGHT, Format.RGB);
    triangle(  7, 45, 35, 100, 45,  60, *image, RED);
    triangle(120, 35, 90,   5, 45, 110, *image, WHITE);
    triangle(115, 83, 80,  90, 85, 120, *image, GREEN);
    write_tga_file("./triangles.tga", *image, vflipped = true);
}