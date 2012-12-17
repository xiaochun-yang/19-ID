#ifndef point_t_h
#define point_t_h

class point_t
{
public:
	double x;
	double y;

	/**
	 * Default constructor
	 */
	point_t()
		: x(0), y(0)
	{
	}

	/**
	 * Constructor
	 */
	point_t(double x_, double y_)
		: x(x_), y(y_)
	{
	}
	
	/**
	 * Copy constructor
	 * For example: 
	 * point_t a; // default constructor is called to create a.
	 * point_t b = a; // copy constructor is called to create b.
	 */
	point_t(const point_t& p)
	{
		x = p.x;
		y = p.y;
	}
	
	/**
	 * Assignment operator
	 * For example:
	 * point_t a(1, 2); // normal constructor is called to create a.
	 * point_t c; // default constructor is called to create c.
	 * c = b; // Assignment operator is called to set c.
	 */
	point_t& operator=(const point_t& other)
	{
		// Do not copy itself
		if (this == &other)
			return *this;
			
		x = other.x;
		y = other.y;
		
		return *this;
	}


	// For example;
	// point_t a(1, 2);
	// point_t b(1, 1);
	// point_t c = a - b;
	// c.x is 0, c.y is 1
	point_t operator-(const point_t& other)
	{
		
		return point_t(x - other.x, y - other.y);
	}
	
	// For example:
	// point_t a(1, 2);
	// point_t b(1, 1);
	// point_t c = a + b;
	// c.x is 2, c.y is 3
	point_t operator+(const point_t& other)
	{
		
		return point_t(x + other.x, y + other.y);
	}
	
	/**
	 * Indexing operator
	 * For example:
	 * point_t a(5, 10);
	 * double n1 = a[0]; 
	 * double n2 = a[1];
	 * n1 is 5 and n2 is 10.
	 */
	double operator[](int index) const
	{
		if (index == 0)
			return x;
		
		return y;
	}
		
};

#endif // point_t_h
