#import "Basic";
#import "File";
#import "String";
#import "Math";

Model :: struct {
    verticies    : [..] Vector3;
    vertex_faces : [..] int;
}

load_model :: (filename: string) -> (success: bool, model: Model) {
    file, success:= read_entire_file(filename);
    defer free(file);
    assert(success, "Failed to read file to load model.");

    model : Model;
    lines := split(file, #char "\n");
    for line, it: lines {
        elements := split(line, " ");
        if elements[0] == {
            case "v";
                x := string_to_float(elements[1]);
                y := string_to_float(elements[2]);
                z := string_to_float(elements[3]);
                array_add(*model.verticies, make_vector3(.[x, y, z]));
            case "f";
                // The Geometric verticies only for right now. Subtract one because .obj arrays start at 1.
                v1 := string_to_int(split(elements[1], "/")[0]) - 1;
                v2 := string_to_int(split(elements[2], "/")[0]) - 1;
                v3 := string_to_int(split(elements[3], "/")[0]) - 1;
                array_add(*model.vertex_faces, v1);
                array_add(*model.vertex_faces, v2);
                array_add(*model.vertex_faces, v3);

        } 
    }
    
    return true, model;
}