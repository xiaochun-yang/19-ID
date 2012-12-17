#include <streambuf>
#include <iterator>
#include <markup.h>
#include <LabelitMarkup.h>

// Create dummyMarkup so that LabelitMarkup constructor
// will be called and magick_mutex will be created
// prior to any call to lock() or unlock().
static LabelitMarkup dummyMarkup;

xos_mutex_t LabelitMarkup::magick_mutex;

struct from_string_adaptor_v3 {
  const char* str_ptr;
  std::string held_s;
  explicit from_string_adaptor_v3(const std::string& s):
  held_s(s),
  str_ptr(&(*(s.begin())))
  {
    str_end = str_ptr + s.size();
  }
  const char* str_end;
  bool can_read(int const& length){ return str_end - str_ptr >= length; }
  std::string get_string(int const& length) {
    std::string rvalue(str_ptr,str_ptr+length);
    str_ptr += length;
    return rvalue;
  }
  from_string_adaptor_v3& operator>>(unsigned short& val)
    {
      val = std::atoi(std::string(str_ptr,str_ptr+8).c_str());
      str_ptr+=9;
      return *this;
    }
  from_string_adaptor_v3& operator>>(unsigned int& val)
    {
      val = std::atoi(std::string(str_ptr,str_ptr+8).c_str());
      str_ptr+=9;
      return *this;
    }
  from_string_adaptor_v3& operator>>(int& val)
    {
      val = std::atoi(std::string(str_ptr,str_ptr+8).c_str());
      str_ptr+=9;
      return *this;
    }
  from_string_adaptor_v3& operator>>(float& val)
    {
      val = std::atof(std::string(str_ptr,str_ptr+11).c_str());
      str_ptr+=12;
      return *this;
    }
};

/**
* Constructor, reading and parsing a markup file
*/
LabelitMarkup::LabelitMarkup(const char* filename)
	: Markup(filename),dataseek(0)
{

	init();

	source_image = input_name;
	char c;
	std::ifstream fin(filename, std::ios_base::in);


	//determine the presence or absence of markup
	try {
		char buf[256];

		// Read the first 20 bytes which must be a fixed string
		// "LABELIT IMAGE MARKUP".
		fin.read(buf,20);

		if (std::string(buf,20) != "LABELIT IMAGE MARKUP") {
			fin.close();
			//printf("Original image--no markup\n");
			return;
		}

		// Read end of line
		fin.read(buf,2); // end of first line

		// The next 9 bytes are a  fixed string
		fin.read(buf,9);

		if (std::string(buf,9) != "filename ") {
			fin.close();
//			printf("Could not find 'filename' keyword in markup file\n");
			return;
		}

		// The next 8 bytes tell us how the original
		// image filepath is.
		fin.read(buf,8);

		// Put 8 bytes data to a string
		std::string filelen_s(buf,8);
		// Use stringstream to convert
		// string into integer.
		std::istringstream ist(filelen_s);

		// Extract original filepath length
		std::size_t filelen;
		ist>>filelen;

		// Read the end of second line
		fin.read(buf,2); // end of second line

		// Read filepath of the original image
		fin.read(buf,filelen);

		// Save original image path
		source_image = std::string(buf,filelen);

		// Save markup path
		markup_file = input_name;

		// Set stream pointer to the next byte
		dataseek = 20 + 2 + 9 + 8 + 2 + filelen;

		// Make sure we have data
//		if (dataseek <= 0)


	} catch(std::exception e) {
		std::cout<<(&e)->what()<<std::endl;
	} catch(...) {
	}

	fin.close();
}

/**
 * Destructor: delete pointers
 */
LabelitMarkup::~LabelitMarkup()
{
	// Deleting pointers held in blocks vector
	std::vector<DrawBlock*>::iterator it;
	while (blocks.size() > 0) {
		it = blocks.begin();
		DrawBlock* b = *it;
		blocks.erase(it);
		delete b;
	}
}

void LabelitMarkup::parse_markup(){
    if (!image_has_markup()) {return;}
    std::ifstream fin(input_name.c_str(), std::ios_base::in);
    try {fin.seekg(dataseek+2);} catch(...) {return;}
    char buf[256];
    //while (fin.get(c)) std::cout.put(c);

    std::string strbuf;
    char c;
    while (fin.peek()!=EOF) {
      fin.get(c);
      strbuf.push_back(c);
    }
    if (strbuf[7]=='3'){
      //developmental version 3:  ascii encoding only -- no binary
    from_string_adaptor_v3 inp(strbuf);
    inp >> m_version;
    comment_t tag;
    int nitems;
    float RGB[3];
    float value;
    std::string markup_icon;
    while (inp.can_read(8)) {
      std::string markup_icon = inp.get_string(8);
      if (markup_icon=="CIRCLE__"){
        inp >> tag >> nitems;
        for (size_t r=0; r<3; ++r){ inp >> RGB[r]; }
        CircleBlock* D = new CircleBlock(RGB[0],RGB[1],RGB[2],tag);
        blocks.push_back(D);
        for (size_t nc=0; nc<nitems; ++nc) { //read x center, y center, radius
          std::vector<double> v;
          float value;
          for (size_t r=0; r<3; ++r){ inp >> value; v.push_back(value);}
          D->add(v);
        }
      } else if (markup_icon=="ELLIPSE_"){
        inp >> tag >> nitems;
        for (size_t r=0; r<3; ++r){ inp >> RGB[r]; }
        EllipseBlock* D = new EllipseBlock(RGB[0],RGB[1],RGB[2],tag);
        blocks.push_back(D);
        for (size_t nc=0; nc<nitems; ++nc) {
          //read x center, y center, semi-major axis, semi-minor axis, angle
          std::vector<double> v;
          float value;
          for (size_t r=0; r<5; ++r){inp >> value; v.push_back(value);}
          D->add(v);
        }
      } else if (markup_icon=="DOT_____"){
        inp >> tag >> nitems;
        for (size_t r=0; r<3; ++r){ inp >> RGB[r]; }
        DotBlock* D = new DotBlock(RGB[0],RGB[1],RGB[2],tag);
        blocks.push_back(D);
        for (size_t nc=0; nc<nitems; ++nc) {
          //read x center, y center
          std::vector<double> v;
          unsigned short value;
          for (size_t r=0; r<2; ++r){inp >> value; v.push_back(value);}
          D->add(v);
        }
      } else if (markup_icon=="DOTFLOAT"){
        inp >> tag >> nitems;
        for (size_t r=0; r<3; ++r){ inp >> RGB[r]; }
        DotBlock* D = new DotBlock(RGB[0],RGB[1],RGB[2],tag);
        blocks.push_back(D);
        for (size_t nc=0; nc<nitems; ++nc) {
          //read x center, y center
          std::vector<double> v;
          float value;
          for (size_t r=0; r<2; ++r){inp >> value; v.push_back(value);}
          D->add(v);
        }
      } else if (markup_icon=="CROSS___"){
        inp >> tag >> nitems;
        for (size_t r=0; r<3; ++r){ inp >> RGB[r]; }
        DotBlock* D = new DotBlock(RGB[0],RGB[1],RGB[2],tag);
        blocks.push_back(D);
        for (size_t nc=0; nc<nitems; ++nc) { //read x center, y center, radius
          std::vector<double> v;
          float value;
          for (size_t r=0; r<3; ++r){inp >> value; v.push_back(value);}
          D->add(v);
        }
      } else {
        break;
      }
    }
    }

}

void LabelitMarkup::lock()  {
	// Lock the cache entry mutex
	if (xos_mutex_lock(&LabelitMarkup::magick_mutex) != XOS_SUCCESS) {
//		printf("MagickMarkup failed to lock mutex"); fflush(stdout);
		throw XosException("MagickMarkup failed to lock mutex");
	}
}

void LabelitMarkup::unlock()  {
	if (xos_mutex_unlock(&LabelitMarkup::magick_mutex) != XOS_SUCCESS) {
//		printf("MagickMarkup failed to unlock mutex"); fflush(stdout);
		throw XosException("MagickMarkup failed to unlock mutex");
	}
}

void LabelitMarkup::init() {
	if (!LabelitMarkup::magick_mutex.isValid) {
//		printf("MagickMarkup creating magick_mutex"); fflush(stdout);
		if (xos_mutex_create(&LabelitMarkup::magick_mutex) != XOS_SUCCESS) {
//			printf("MagikMarkup failed to create mutex"); fflush(stdout);
			throw XosException("MagikMarkup to create mutex");
		}
	}

}

