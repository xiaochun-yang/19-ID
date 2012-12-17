#include <diffimage.h>
#include <iostream>
#include <cstdio>
#include <string>

xos_result_t sendJpegToFile(const char* filename, Diffimage* D)
{
	FILE* stream = NULL;
	if ((stream = fopen(filename, "wb")) == NULL) {
		printf("can't open %s\n", filename);
		return XOS_FAILURE;
	}

	JINFO jinfo;
	unsigned char *uncompressedBuffer;
	if (D->create_uncompressed_buffer(&uncompressedBuffer, &jinfo) != XOS_SUCCESS) {
			printf("Failed to create compressed buffer");
			return XOS_FAILURE;
	}

	if (D->send_jpeg_to_stream(stream, uncompressedBuffer, &jinfo) != XOS_SUCCESS) {
		printf("Failed to send jpeg to stream");
		return XOS_FAILURE;
	}
	fclose(stream);
	Diffimage::free_uncompressed_buffer(uncompressedBuffer);

	return XOS_SUCCESS;

}
int main(int argc, char** argv)
{
	if (argc != 4) {
		printf("Usage: test <image filepath> <full jpeg filepath> <thumbnail jpeg filepath>\n");
		exit(0);
	}

	printf("Got %d arguments\n", argc); fflush(stdout);
	printf("Arg0 %s\n", argv[0]); fflush(stdout);
	printf("Arg1 %s\n", argv[1]); fflush(stdout);
	printf("Arg2 %s\n", argv[2]); fflush(stdout);
	printf("Arg3 %s\n", argv[3]); fflush(stdout);
	std::string imageFile = argv[1];
	printf("1\n"); fflush(stdout);

	imagePtr_t image = NULL;
	try {
		image = diffimage::libimage_factory(imageFile);
		image->read_data();
		char buff[10];
		image->get_header(buff, 10);
	} catch (int ret) {
		printf("failed to load image header %s\n", imageFile.c_str());
		fflush(stdout);
		return 0;
	}

	printf("1 Got %d arguments\n", argc); fflush(stdout);
	printf("1 Arg0 %s\n", argv[0]); fflush(stdout);
	printf("1 Arg1 %s\n", argv[1]); fflush(stdout);
	printf("1 Arg2 %s\n", argv[2]); fflush(stdout);
	printf("1 Arg3 %s\n", argv[3]); fflush(stdout);

	printf("2\n"); fflush(stdout);
	Diffimage D(image, 255, 100, 100, 125, 125);
	printf("3\n"); fflush(stdout);

	double zoom = 1.1;
	double gray = 1400;//400;
	int sizex = 1600;
	int sizey = 1600;
	double percentx = 0.4;
	double percenty = 0.45;
	printf("4\n"); fflush(stdout);

	std::string jpegFilename(argv[2]);
	std::string thumbFilename(argv[3]);
	printf("5\n"); fflush(stdout);

	printf("parameters: %f %f %f %f\n", zoom, gray, percentx, percenty); fflush(stdout);

	/* calculate center of image */
	int im_centerx = (int) (percentx * (double) D.get_image_size_x());
	int im_centery = (int) (percenty * (double) D.get_image_size_y());

	/* set parameters for creating the jpeg file */
	D.set_display_size(sizex, sizey);
	D.set_image_center(im_centerx, im_centery);
	D.set_zoom(zoom);
	D.set_contrast_min(0);
	D.set_contrast_max((int) gray);
	D.set_jpeg_quality(90);
	D.set_sampling_quality(3);

	std::cout << "thumbnail view created: " << argv[3] << std::endl;

	/* create the thumbnail image */
	D.set_mode(DIFFIMAGE_MODE_THUMB);

	if (sendJpegToFile(thumbFilename.c_str(), &D) != XOS_SUCCESS) {
		printf("test -- error creating thumbnail jpeg file");
	}

	std::cout << "full size view created: " << argv[2] << std::endl;

	D.set_mode(DIFFIMAGE_MODE_FULL);
	if (sendJpegToFile(thumbFilename.c_str(), &D) != XOS_SUCCESS) {
		printf("test -- error creating full jpeg file");
	}

	return 0;
}
