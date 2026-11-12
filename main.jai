#import "Basic";
#import "Math";

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

project :: inline (vector : Vector3) -> Vector2 {
    r : Vector2 = ---;
    r.x = (vector.x + 1.0) * (WIDTH / 2);
    r.y = (vector.y + 1.0) * (HEIGHT/ 2);
    return r;
}

main :: () {
    success, model := load_model("./models/diablo3_pose.obj");

    print("Num of faces: %\n", model.vertex_faces.count);
    
    image := create_TGAImage(WIDTH, HEIGHT, Format.RGB);

    for 0..((model.vertex_faces.count - 1) / 3) {
        i1 := model.vertex_faces[(it * 3)];
        i2 := model.vertex_faces[(it * 3) + 1];
        i3 := model.vertex_faces[(it * 3) + 2];
        v1 := project(model.verticies[i1]);
        v2 := project(model.verticies[i2]);
        v3 := project(model.verticies[i3]);
        draw_line(xx v1.x, xx v1.y, xx v2.x, xx v2.y, *image, RED);
        draw_line(xx v2.x, xx v2.y, xx v3.x, xx v3.y, *image, RED);
        draw_line(xx v3.x, xx v3.y, xx v1.x, xx v1.y, *image, RED);
    }

    for model.verticies {
        vertex := project(it);
        set_pixel_color(*image, xx vertex.x, xx vertex.y, WHITE);
    }

    write_tga_file("./Wireframe.tga", *image, vflipped = true);
}