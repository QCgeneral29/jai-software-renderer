#import "Basic";
#import "Math";
#import "Random";

#import,file "TGAImage.jai";
#import,file "Model.jai";

WHITE   : TGAColor : .{bgra = .[255, 255, 255, 255]};
GREEN   : TGAColor : .{bgra = .[  0, 255,   0, 255]};
RED     : TGAColor : .{bgra = .[  0,   0, 255, 255]};
BLUE    : TGAColor : .{bgra = .[255, 128,  64, 255]};
YELLOW  : TGAColor : .{bgra = .[  0, 200, 255, 255]};

WIDTH  :: 1080;
HEIGHT :: 1080;

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

signed_triangle_area :: inline (ax: int, ay: int, bx: int, by: int, cx: int, cy: int) -> float64 {
    return 0.5 * ((by-ay)*(bx+ax) + (cy-by) * (cx+bx) + (ay-cy) * (ax+cx));
}

draw_triangle :: (ax: int, ay: int, bx: int, by: int, cx: int, cy: int, image: *TGAImage, color: TGAColor) {
    // bb = bounding box
    bbmin_x := min(min(ax, bx), cx);
    bbmin_y := min(min(ay, by), cy);
    bbmax_x := max(max(ax, bx), cx);
    bbmax_y := max(max(ay, by), cy);
    total_area := signed_triangle_area(ax, ay, bx, by, cx, cy);
    // HACK: backface culling + discarding triangles that cover less than a pixel.
    if total_area < 1 then return;

    for x: bbmin_x..bbmax_x {
        for y: bbmin_y..bbmax_y {
            alpha := signed_triangle_area(x, y, bx, by, cx, cy) / total_area;
            beta  := signed_triangle_area(x, y, cx, cy, ax, ay) / total_area;
            gamma := signed_triangle_area(x, y, ax, ay, bx, by) / total_area;
            if (alpha < 0 || beta < 0 || gamma < 0) continue;
            set_pixel_color(image, x, y, color);
        }
    }
}

project :: inline (vector : Vector3) -> Vector2 {
    r : Vector2 = ---;
    r.x = (vector.x + 1.0) * (WIDTH / 2);
    r.y = (vector.y + 1.0) * (HEIGHT/ 2);
    return r;
}

main :: () {
    image := create_TGAImage(WIDTH, HEIGHT, Format.RGB);

    //success, model := load_model("./models/african_head/african_head.obj");
    success, model := load_model("./models/diablo3_pose.obj");

    for 0..((model.vertex_faces.count - 1) / 3) {
        i1 := model.vertex_faces[(it * 3)];
        i2 := model.vertex_faces[(it * 3) + 1];
        i3 := model.vertex_faces[(it * 3) + 2];
        v1 := project(model.verticies[i1]);
        v2 := project(model.verticies[i2]);
        v3 := project(model.verticies[i3]);
        color : TGAColor = .{bgra = .[
            cast(u8) (random_get() % 255),
            cast(u8) (random_get() % 255),
            cast(u8) (random_get() % 255),
            cast(u8) (random_get() % 255)
        ]};
        draw_triangle(xx v1.x, xx v1.y, xx v2.x, xx v2.y, xx v3.x, xx v3.y, *image, color);
    }

    write_tga_file("./three_Dee_model.tga", *image, vflipped = true);
}