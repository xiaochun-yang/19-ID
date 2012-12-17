#ifndef DIFFIMAGE_MARKUP_H
#define DIFFIMAGE_MARKUP_H

#include <string>

/**
 * Image markup base class.
 */
class Markup
{
public:
	/**
	 * Default constructor
	 */
	Markup(){}

  	/**
	 * Constructor, reading and parsing a markup file
	 */
	Markup(const char* filename) : input_name(std::string(filename)) {}

  	/**
	 * Destructor: cleanup some pointers
	 */
	virtual ~Markup() {}

	const std::string& getInputFilename() { return input_name; }
	const std::string& getImageFilename() { return source_image; }
	const std::string& getMarkupFilename() { return markup_file; }

	/**
	 * Parse markup file
	 */
	virtual void parse_markup() {}

	/**
	 * Returns true if this is an image markup file.
	 */
	virtual bool image_has_markup()
	{
		return false;
	}

	virtual void draw_markup(int sizeX, int sizeY, double offsetX, double offsetY, double ratio, const void* buffer) {}

protected:
	// Input filepath (could be markup or image file)
	std::string input_name;

	// Original image filepath
	std::string source_image;

	// Markup filepath
	std::string markup_file;

};

#endif // DIFFIMAGE_MARKUP_H
