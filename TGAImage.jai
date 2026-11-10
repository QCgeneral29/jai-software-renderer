// Source code from:
// https://github.com/ssloy/tinyrenderer
// For the tinyrenderer tutorial:
// https://haqr.eu/tinyrenderer/
// More about TGA spec:
// http://www.paulbourke.net/dataformats/tga/

#import "Basic";
#import "File";

// Use #align 1 to remove padding. This struct uses 18 bytes.
TGAHeader :: struct {
    id_length:              u8 #align 1;
    color_map_type:         u8 #align 1;
    data_type_code:         u8 #align 1;
    color_map_origin:      u16 #align 1;
    color_map_length:      u16 #align 1;
    color_map_depth:        u8 #align 1;
    x_origin:              u16 #align 1;
    y_origin:              u16 #align 1;
    width:                 u16 #align 1;
    height:                u16 #align 1;
    bits_per_pixel:         u8 #align 1;
    image_descriptor:       u8 #align 1;
}

TGAColor :: struct {
    bgra:               [4] u8;
    bytes_per_pixel:        u8 = 4;
}

operator [] :: (color: TGAColor, i: u32) -> u8 {
    return color.bgra[i];
}

TGAImage :: struct {
    width:  u32;
    height: u32;
    bytes_per_pixel: u8;
    data: [..] u8;
}

Format :: enum u8 {
    GRAYSCALE :: 1;
    RGB :: 3;
    RGBA :: 4;
}

read_tga_file :: (filename: string) -> (success: bool, image: TGAImage, header: TGAHeader) {
    file, success := read_entire_file(filename);
    defer free(file);
    if success {
        image : TGAImage;
        header : TGAHeader;
        memcpy(*header, file.data, size_of(TGAHeader));

        {
            using image;

            width = header.width;
            height = header.height;
            bytes_per_pixel = header.bits_per_pixel >> 3;

            if width  <= 0  || 
               height <= 0  ||
               (
                bytes_per_pixel != xx Format.GRAYSCALE &&
                bytes_per_pixel != xx Format.RGB &&
                bytes_per_pixel != xx Format.RGBA
               ) 
               {
                log_error("Invalid height/width or bad bytes per pixel\n");
                log_error("Header:\n%\n", header);
                return false, .{}, .{};
               }

            n_bytes: s64 = bytes_per_pixel * width * height;
            array_reserve(*data, n_bytes);

            if header.data_type_code == 3 || header.data_type_code == 2 {
                for size_of(TGAHeader)..file.count - 1 {
                    array_add(*data, file[it]);
                }
            } else if header.data_type_code == 10 || header.data_type_code == 11 {
                assert(expand_rle_data(file.data, *image), "Failed to expand rle data.");
            } else {
                log_error("File format is unknown. Given: %\n", header.data_type_code);
                return false, .{}, .{};
            }

            if !(header.image_descriptor & 0x20){
                assert(false, "TODO: flip vertically.");
            }
            if header.image_descriptor & 0x10 {
                assert(false, "TODO: flip horizontally.");
            }
        }
        return true, image, header;
    }
    return false, .{}, .{};
}

// For future Landen:
// I might have fixed it. Also, might be a good idea to rename data in the image to something like pixel_data. Because double data for jai arrays.
expand_rle_data :: (data: * u8, image: *TGAImage) -> (success: bool) {
    total_pixels : u64 = image.width * image.height;
    current_pixel : u64;
    color_buffer : TGAColor;

    data = data + size_of(TGAHeader); // Add an offset to skip the header.
    data_index : u64;
    while current_pixel < total_pixels {
        chunk_header : u8 = data[data_index];
        data_index = data_index + 1;
        if chunk_header < 128 {
            chunk_header = chunk_header + 1;
            for 0..chunk_header - 1 {
                memcpy(color_buffer.bgra.data, data + data_index, image.bytes_per_pixel);  
                data_index = data_index + image.bytes_per_pixel;
                for 0..image.bytes_per_pixel - 1 {
                    array_add(*image.data, color_buffer.bgra[it]);
                }
                current_pixel = current_pixel + 1;
            }
        } else {
            chunk_header = chunk_header - 127;
            memcpy(color_buffer.bgra.data, data + data_index, image.bytes_per_pixel);  
            data_index = data_index + image.bytes_per_pixel;
            for 0..chunk_header - 1 {
                for 0..image.bytes_per_pixel - 1 {
                    array_add(*image.data, color_buffer.bgra[it]);
                }
                current_pixel = current_pixel + 1;
            }
        }
    }

    return true; 
}

compress_data_to_rle :: (file: * File, image: * TGAImage) -> success: bool {
    using image;
    max_chunk_length : u8 : 128;
    total_pixels : u64 = width * height;
    current_pixel : u64;
    
    while current_pixel < total_pixels {
        chunk_start  := current_pixel * bytes_per_pixel;
        current_byte := current_pixel * bytes_per_pixel; 
        run_length : u64 = 1;
        raw := true;
        while current_pixel + run_length < total_pixels && run_length < max_chunk_length {
            successive_equality := true;
            i : u64;
            while successive_equality && i < bytes_per_pixel {
                successive_equality = data[current_byte + i] == data[current_byte + i + bytes_per_pixel];
                i = i + 1;
            }
            current_byte = current_byte + bytes_per_pixel;
            if run_length == 1 {
                raw = !successive_equality;
            }
            if raw && successive_equality {
                run_length = run_length - 1;
                break;
            }
            if !raw && !successive_equality {
                break;
            }
            run_length = run_length + 1;
        }
        current_pixel = current_pixel + run_length;
        packet_header : u8 = xx ifx raw then run_length - 1 else run_length + 127;

        success := file_write(file, *packet_header, size_of(type_of(packet_header)));
        if !success {
            log_error("Failed to write packet header.");
            return false;
        }
        amount_to_write : s64 = xx ifx raw then run_length * bytes_per_pixel else bytes_per_pixel;
        success = file_write(file, data.data + chunk_start, amount_to_write);
        if !success {
            log_error("Failed to write data chunck.");
            return false;
        }
    }
    return true;
}

write_tga_file :: (filename: string, image: * TGAImage, vflipped := false, rle := false) -> success: bool {
    developer_area_ref : [4] u8 = .[0, 0, 0, 0];
    extension_area_ref : [4] u8 = .[0, 0, 0, 0];
    footer :: "TRUEVISION-XFILE.";

    file, success := file_open(filename, for_writing=true);
    defer file_close(*file);
    if !success {
        log_error("Unable to open file:\n%\n", filename);
        return false;
    }

    header : TGAHeader;
    header.bits_per_pixel = image.bytes_per_pixel << 3;
    header.width = xx image.width;
    header.height = xx image.height;
    header.data_type_code = xx  ifx image.bytes_per_pixel == xx Format.GRAYSCALE then
                                    ifx rle then 11 else 3
                                else
                                    ifx rle then 10 else 2;

    header.image_descriptor = xx ifx vflipped then 0x00 else 0x20; // top-left or bottom-left origin.

    assert(file_write(*file, *header, size_of(TGAHeader))); // TODO: return false?

    if !rle {
        assert(file_write(*file, image.data.data, image.data.count)); // TODO: return false?
    } else  {
        compress_data_to_rle(*file, image);
    }
    file_write(*file, *developer_area_ref, size_of(type_of(developer_area_ref)));
    file_write(*file, *extension_area_ref, size_of(type_of(extension_area_ref)));
    // By using footer.count instead of count - 1, we are including the \0 that jai provides with string constants.
    file_write(*file, footer.data, footer.count); 

    return true;
}

get_pixel_color :: (image: * TGAImage, x: s64, y: s64) -> TGAColor {
    using image;
    if !data.count || x < 0 || y < 0 || x >= width || y >= height return .{};
    color : TGAColor;
    pointer := data.data + (x + y * width) * bytes_per_pixel;
    for < 0..bytes_per_pixel {
        color.bgra[it] = pointer[it];
    }
    return color;
}

set_pixel_color :: (image: * TGAImage, x: s64, y: s64, color: TGAColor) {
    using image;
    if !data.count || x < 0 || y < 0 || x >= width || y >= height {
        return;
    }
    memcpy(data.data + (x + y * width) * bytes_per_pixel, color.bgra.data, bytes_per_pixel);
}

flip_horizontally :: (image: * TGAImage) {
    using image;
    for w: 0..width/2 - 1 {
        for h: 0..height - 1 {
            for b: 0..bytes_per_pixel - 1 {
                // First : data[(w + h * width) * bytes_per_pixel + b]
                // Second: data[(width - 1 - w + h * width) * bytes_per_pixel + b]
                tmp := data[(width - 1 - w + h * width) * bytes_per_pixel + b];
                data[(width - 1 - w + h * width) * bytes_per_pixel + b] = data[(w + h * width) * bytes_per_pixel + b];
                data[(w + h * width) * bytes_per_pixel + b] = tmp;
            }
        }
    }
}

flip_vertically :: (image: * TGAImage) {
    using image;
    for w: 0..width - 1 {
        for h: 0..height / 2 - 1 {
            for b: 0..bytes_per_pixel - 1 {
                // First : data[(x + h * width) * bytes_per_pixel + b]
                // Second: data[(x + (height - 1 - h) * width) * bytes_per_pixel + b]
                tmp := data[(w + (height - 1 - h) * width) * bytes_per_pixel + b];
                data[(w + (height - 1 - h) * width) * bytes_per_pixel + b] = data[(w + h * width) * bytes_per_pixel + b];
                data[(w + h * width) * bytes_per_pixel + b] = tmp;
            }
        }
    }
}