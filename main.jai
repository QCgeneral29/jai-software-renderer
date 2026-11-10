#import "Basic";
#import,file "TGAImage.jai";

main :: () {
    filename : string = "./test-images/earth.tga";
    print("\nReading tga file: %\n", filename);
    success, image, header := read_tga_file(filename);
    if success {
        print("Read TGA file successfully: %\n\n", success);
        print("Image Struct:\n%\n\n", header);
    }
    
    filename = "./test-images/rle_test.tga";
    print("Reading tga file: %\n", filename);
    success, image, header = read_tga_file(filename);
    if success {
        print("Loaded %\n\n", filename);
        print("Header Struct:\n%\n", header);
        print("Image Struct:\n%\n\n", image);
    }

    /*
    // Loop through the pixels and play with their set color.
    for x: 0..image.width - 1 {
        for y: 0..image.height - 1 {
            set_pixel_color(*image, xx x, xx y, .{.[cast(u8) (x % 255),cast(u8) (y % 255), cast(u8) ((y + x) % 255), 0], image.bytes_per_pixel});
        }
    }
    */

    flip_horizontally(*image);
    flip_vertically(*image);

    write_tga_file("Outputted-Image.tga", *image);
    //write_tga_file("I-wrote_this_rle_image.tga", *image, rle = true);

    print("The pixel at 0, 0 is: (bgra format)\n");
    print("%\n\n", get_pixel_color(*image, 0, 0));

    print("The pixel at 600, 700 is:\n");
    print("%\n\n", get_pixel_color(*image, 600, 700));

}