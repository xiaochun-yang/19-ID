#ifndef _decimalnum_h
#define _decimalnum_h

#include <string>

using namespace std;

class DecimalNum {
  
 public:

  DecimalNum();	
  explicit DecimalNum(int value);
  explicit DecimalNum(double value);
  int arr [12];
  int Size();	
  string ToString();	
  
//-----------------------Operators and operations--------------------

  DecimalNum operator =  (double);
  DecimalNum operator *  (int);
  DecimalNum operator *= (int);
  DecimalNum operator /  (int); 
  DecimalNum operator /= (int); 
  DecimalNum operator +  (const DecimalNum&);
  DecimalNum operator += (const DecimalNum&);
  DecimalNum operator -  (const DecimalNum&);
  DecimalNum operator -= (const DecimalNum&);
  DecimalNum operator *  (const DecimalNum&);
  DecimalNum operator *= (const DecimalNum&);
  DecimalNum operator /  (const DecimalNum&);
  DecimalNum operator /= (const DecimalNum&);
  
  bool operator >= (const DecimalNum &);
  bool operator >  (const DecimalNum &);
  bool operator <= (const DecimalNum &);
  bool operator <  (const DecimalNum &);
  bool operator == (const DecimalNum &);
  bool operator != (const DecimalNum &);
  
  operator double() { return atof(ToString().c_str()); }

 private:
  
  void FixNum();
  static const int SizeOfDecimalNum = 12;

};

ostream& operator<<(ostream & output, DecimalNum &nmbr);
istream& operator>>(istream & input, DecimalNum &nmbr); 

DecimalNum StringToNum(string str);
DecimalNum absoluteValue(DecimalNum);
DecimalNum pow(DecimalNum &, int);
DecimalNum sqrt(DecimalNum &);

#endif
