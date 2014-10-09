#include "decimalnum.h"
#include <iostream>
#include <assert.h>
#include <math.h>
#include <string>
#include <cstdio>

using namespace std;

/*
 * Integer Name: Power
 * -------------------
 * 
 * Unique Specifications: Be smart, don't cause an overflow. Also, this is only
 * needed for positive powers. It is also only available inside this file.
 *
 * Usage: I did not want to include cmath just for the pow function, so I 
 * wrote one exclusively for positive integer powers.
 */

int Power(int nmbr, int pwr){
  int tmp = 1;
  for(int i = 0; i < pwr; i++)
    tmp *= nmbr;
  return tmp;
}

string DoubleToString(double value){
  char buff [60];
  string result;
  sprintf(buff,"%.16f", value);
  result = (string) buff;
  return result;
}

DecimalNum::DecimalNum(){
  for(int i = 0; i < SizeOfDecimalNum; i ++)
    arr[i] = 0;
}

DecimalNum::DecimalNum(int value) {
  for(int i = 0; i < SizeOfDecimalNum; i ++)
    arr[i] = 0;
  arr[SizeOfDecimalNum / 2] = value % Power(10, 9);
  arr[(SizeOfDecimalNum / 2) + 1] = value / Power(10, 9);
}

DecimalNum::DecimalNum(double value){
  for(int i = 0; i < SizeOfDecimalNum; i ++)
    arr[i] = 0;
  *this = StringToNum(DoubleToString(value));
}

int DecimalNum::Size(){
  return SizeOfDecimalNum;
}

string DecimalNum::ToString(){
  string str = "";
  string buf = "";
  char buffer[9];
  if(*this < DecimalNum())
    str += "-";
  for(short s = SizeOfDecimalNum - 1; s >= SizeOfDecimalNum/2; s --){
    sprintf(buffer, "%i", abs(arr[s]));
    buf = string(buffer);
    while(buf.length() < 9)
      buf.insert(0, "0");
    str += buf;
  }
  while((str.length() > 1) && (str[0] == '0'))
    str = str.substr(1);
  while((str.length() > 2) && (str[0] == '-') && (str[1] == '0'))
    str = "-" + str.substr(2);
  short min = 0;
  while((min != SizeOfDecimalNum/2) && (arr[min] == 0))
    min ++;
  if(min != SizeOfDecimalNum/2){
    str += ".";
    for(short s = SizeOfDecimalNum/2 - 1; s >= min; s--){
      sprintf(buffer, "%i", abs(arr[s]));
      buf = string(buffer);
      while(buf.length() < 9)
	buf.insert(0, "0");
      str+=buf;
    }
    while(str[str.length()-1] == '0')
      str = str.substr(0, str.length() - 1);
  }
  return str;
}

DecimalNum StringToNum(string str){
  string strpow = "";
  if(str.find("e") != str.npos){
    strpow = str.substr(str.find("e") +1);
    str = str.substr(0, str.find("e"));
  }
  if(str.find("E") != str.npos){
    strpow = str.substr(str.find("E") +1);
    str = str.substr(0, str.find("E"));
  }
  if(strpow != ""){
    short pow = atoi(strpow.c_str());
    if(str.find(".") == str.npos)
      str += ".";
    while(pow > 0){
      if(str[str.length() - 1] == '.')
	str += "0";
      int index = str.find(".");
      str[index] = str[index + 1];
      str[index + 1] = '.';
      pow --;
    }
    while(pow < 0){
      if(str[0] == '.')
	str.insert(0, "0");
      int index = str.find(".");
      str[index] = str[index - 1];
      str[index - 1] = '.';
      pow ++;
    }
  }
  DecimalNum tmp;
  bool positive = true;
  if(str[0] == '-'){
    positive = false;
    str = str.substr(1);
  }
  while(str[0] == '0')
    str = str.substr(1);
  if(str == "") return tmp;
  string dec;
  if(str.find(".") != str.npos){
    dec = str.substr(str.find(".") + 1);
    str = str.substr(0, str.find("."));
  }
  if(dec.length() != 0){
    for(short s = tmp.Size()/2 - 1; s >=0; s--){
      if(dec.length() > 9){
	tmp.arr[s] = atoi(dec.substr(0, 9).c_str());
	dec = dec.substr(9);
      } else {
	tmp.arr[s] = atoi(dec.c_str());
	tmp.arr[s] *= Power(10, 9-dec.length());
	dec = "";
	break;
      }
    }
    if((dec.length()!=0) && (atoi(dec.substr(0,1).c_str()) >= 5))
      tmp.arr[0] ++;
  }
  unsigned int size = (tmp.Size() / 2) * 9;
  assert(str.length() <= size);
  if(str.length()!=0){
    for(short s = tmp.Size()/2; s < tmp.Size(); s ++){
      if(str.length() > 9){
	tmp.arr[s] = atoi(str.substr(str.length()-9).c_str());
	str = str.substr(0, str.length() - 9);
      } else {
	tmp.arr[s] = atoi(str.c_str());
	break;
      }
    }
  }
  if(!positive)
    tmp *= -1;
  for(short s = 0; s < tmp.Size(); s ++){
    if((tmp.arr[s] / Power(10, 9)) != 0){
      assert(s != (tmp.Size() - 1));
      tmp.arr[s + 1] += (tmp.arr[s] / Power(10, 9));
      tmp.arr[s] = tmp.arr[s] % Power(10, 9);
    }
  }
  return tmp;
}

void DecimalNum::FixNum(){
  if(*this >= DecimalNum()){
    for(short s = 0; s < SizeOfDecimalNum; s ++){
      while(arr[s] < 0){
	arr[s+1] --;
	arr[s] += Power(10,9);
      }
      while(arr[s] >= Power(10, 9)){
	assert(s != SizeOfDecimalNum - 1);
	arr[s+1] ++;
	arr[s] -= Power(10, 9);
      }
    }
  } else {
    for(short s = 0; s < SizeOfDecimalNum; s ++){
      while(arr[s] > 0){
	arr[s+1] ++;
	arr[s] -= Power(10,9);
      }
      while(arr[s] <= -Power(10, 9)){
	assert(s != SizeOfDecimalNum - 1);
	arr[s+1] --;
	arr[s] += Power(10, 9);
      }
    }
  }
}

double NumToDouble(DecimalNum & nmbr){
  string str = nmbr.ToString();
  return atof(str.c_str());
}

void ShiftNumDownOnePlace(DecimalNum &nmbr){
  nmbr.arr[0] = nmbr.arr[1] + nmbr.arr[0] / (5 * Power(10, 8));
  for(short s = 1; s < nmbr.Size() - 1; s ++)
    nmbr.arr[s] = nmbr.arr[s + 1];
  nmbr.arr[nmbr.Size() - 1] = 0;
}

void ShiftNumUpOnePlace(DecimalNum &nmbr){
  assert(nmbr.arr[nmbr.Size() - 1] == 0);
  for(short s = nmbr.Size() - 1; s > 0; s --)
    nmbr.arr[s] = nmbr.arr[s-1];
  nmbr.arr[0] = 0;
}

short power(DecimalNum &nmbr){
  short pwr;
  short digit;
  for(digit = nmbr.Size() -1; digit >= 0; digit --)
    if(nmbr.arr[digit] != 0)
      break;
  for(pwr = 8; pwr >=0; pwr --)
    if((nmbr.arr[digit] / Power(10, pwr)) != 0) 
      break;
  digit -= (nmbr.Size() / 2);
  return (pwr + 9 * digit);
}

ostream & operator<<(ostream &output, DecimalNum & nmbr){
  output << nmbr.ToString();
  return output;
}

//istream & operator>>(istream &input, DecimalNum & nmbr){
//  input >> nmbr.ToString();
//  return input;
//}

//-------------------------Overloaded Boolean Operators------------------------

bool DecimalNum::operator >= (const DecimalNum &number){
  for(short s = SizeOfDecimalNum - 1; s >= 0; s --){
    if(arr[s] > number.arr[s]) return true;
    if(arr[s] < number.arr[s]) return false;
  }
  return true;
}

bool DecimalNum::operator <= (const DecimalNum &number){
  for(short s = SizeOfDecimalNum - 1; s >= 0; s --){
    if(arr[s] < number.arr[s]) return true;
    if(arr[s] > number.arr[s]) return false;
  }
  return true;
}

bool DecimalNum::operator > (const DecimalNum &number){
  for(short s = SizeOfDecimalNum - 1; s >= 0; s --){
    if(arr[s] > number.arr[s]) return true;
    if(arr[s] < number.arr[s]) return false;
  }
  return false;
}

bool DecimalNum::operator < (const DecimalNum &number){
  for(short s = SizeOfDecimalNum - 1; s >= 0; s --){
    if(arr[s] < number.arr[s]) return true;
    if(arr[s] > number.arr[s]) return false;
  }
  return false;
}

bool DecimalNum::operator == (const DecimalNum &number){
  for(short s = SizeOfDecimalNum - 1; s >= 0; s --)
    if(arr[s] != number.arr[s]) return false;
  return true;
}

bool DecimalNum::operator !=(const DecimalNum & number){
  return !(*this == number);
}

//-------------Overloaded Math Operators for DecimalNum ? Integer--------------

DecimalNum DecimalNum::operator =(double val){
  DecimalNum temp(val);
  *this = temp;
  return *this;
}

DecimalNum DecimalNum::operator *(int value){
  DecimalNum returned;
  long long intgr = value;
  for(short s = 0; s < SizeOfDecimalNum; s ++){
    long long bucket = arr[s];
    long long temp = intgr * bucket;
    assert((s != (SizeOfDecimalNum - 1)) || (temp == 0));
    returned.arr[s] += temp % Power(10, 9);
    returned.arr[s+1] += temp / Power(10, 9);
  }
  returned.FixNum();
  return returned;
}

DecimalNum DecimalNum::operator *=(int value){
  DecimalNum returned;
  long long intgr = value;
  for(short s = 0; s < SizeOfDecimalNum; s ++){
    long long bucket = arr[s];
    long long temp = intgr * bucket;
    assert((s != (SizeOfDecimalNum - 1)) || (temp == 0));
    returned.arr[s] += temp % Power(10, 9);
    returned.arr[s+1] += temp / Power(10, 9);
  }
  returned.FixNum();
  *this = returned;
  return *this;
}

DecimalNum DecimalNum::operator /(int value){
  DecimalNum returned;
  long long temp = 0;
  for(short s = SizeOfDecimalNum -1; s > 0; s --){
    temp *= Power(10, 9);
    temp += arr[s];
    returned.arr[s] = temp / value;
    temp = temp % value;
  }
  returned.FixNum();
  return returned;
}

DecimalNum DecimalNum::operator /=(int value){
  DecimalNum returned;
  long long temp = 0;
  for(short s = SizeOfDecimalNum -1; s > 0; s --){
    temp *= Power(10, 9);
    temp += arr[s];
    returned.arr[s] = temp / value;
    temp = temp % value;
  }
  returned.FixNum();
  *this = returned;
  return *this;
}

//------------Overloaded Math Operators for DecimalNum ? DecimalNum------------

DecimalNum DecimalNum::operator +(const DecimalNum & nmbr){
  DecimalNum temp;
  for(short s = 0; s < SizeOfDecimalNum; s ++)
    temp.arr[s] = arr[s] + nmbr.arr[s];
  temp.FixNum();	
  return temp;
}

DecimalNum DecimalNum::operator +=(const DecimalNum & nmbr){
  for(short s = 0; s < SizeOfDecimalNum; s ++)
    arr[s] += nmbr.arr[s];
  FixNum();	
  return *this;
}

DecimalNum DecimalNum::operator -(const DecimalNum & nmbr){
  DecimalNum temp;
  for(short s = 0; s < SizeOfDecimalNum; s ++)
    temp.arr[s] = arr[s] - nmbr.arr[s];
  temp.FixNum();	
  return temp;
}

DecimalNum DecimalNum::operator -=(const DecimalNum & nmbr){
  for(short s = 0; s < SizeOfDecimalNum; s ++)
    arr[s] -= nmbr.arr[s];
  FixNum();	
  return *this;
}

DecimalNum DecimalNum::operator *(const DecimalNum & nmbr){
  DecimalNum returned;
  DecimalNum tempNum;
  for(short s = 0; s < SizeOfDecimalNum; s ++){
    tempNum = *this * nmbr.arr[s];
    short t = s;
    while(t != (SizeOfDecimalNum / 2)){
      if(t > (SizeOfDecimalNum / 2)){
	t --;
	ShiftNumUpOnePlace(tempNum);
      } else {
	t ++;
	ShiftNumDownOnePlace(tempNum);
      }
    }
    returned += tempNum;
  }
  returned.FixNum();
  return returned;
}

DecimalNum DecimalNum::operator *=(const DecimalNum & nmbr){
  DecimalNum returned;
  DecimalNum tempNum;
  for(short s = 0; s < SizeOfDecimalNum; s ++){
    tempNum = *this * nmbr.arr[s];
    short t = s;
    while(t != (SizeOfDecimalNum / 2)){
      if(t > (SizeOfDecimalNum / 2)){
	t --;
	ShiftNumUpOnePlace(tempNum);
      } else {
	t ++;
	ShiftNumDownOnePlace(tempNum);
      }
    }
    returned += tempNum;
  }
  returned.FixNum();
  *this = returned;
  return *this;
}

DecimalNum DecimalNum::operator /(const DecimalNum & divisor){
  DecimalNum dvsr = divisor;
  assert(dvsr != DecimalNum());
  DecimalNum nmbr = *this;
  bool flipsign = false;
  if(nmbr < DecimalNum()){
    flipsign = !flipsign;
    nmbr = absoluteValue(nmbr);
  }
  if(dvsr < DecimalNum()){
    flipsign = !flipsign;
    dvsr = absoluteValue(dvsr);
  }
  DecimalNum tmp (1);
  DecimalNum returned;
  short pwr = power(nmbr) - power(dvsr);
  while(pwr != 0){
    if(pwr > 0){
      pwr --;
      tmp *= 10;
    } else {
      pwr ++;
      tmp /= 10;
    }
  }
  while(true){
    if((nmbr == DecimalNum()) || ((tmp * dvsr) == DecimalNum())) break;
    while((nmbr - (tmp * dvsr)) >= DecimalNum()){
      nmbr -= tmp * dvsr;
      returned += tmp;
    }
    tmp /= 10;
  }
  if(flipsign)
    returned *= -1;
  returned.FixNum();
  return returned;
}

DecimalNum DecimalNum::operator /=(const DecimalNum & divisor){
  DecimalNum dvsr = divisor;
  assert(dvsr != DecimalNum());
  DecimalNum nmbr = *this;
  bool flipsign = false;
  if(nmbr < DecimalNum()){
    flipsign = !flipsign;
    nmbr = absoluteValue(nmbr);
  }
  if(dvsr < DecimalNum()){
    flipsign = !flipsign;
    dvsr = absoluteValue(dvsr);
  }
  DecimalNum tmp (1);
  DecimalNum returned;
  short pwr = power(nmbr) - power(dvsr);
  while(pwr != 0){
    if(pwr > 0){
      pwr --;
      tmp *= 10;
    } else {
      pwr ++;
      tmp /= 10;
    }
  }
  while(true){
    if((tmp == DecimalNum()) || (nmbr == DecimalNum())) break;
    while((nmbr - (tmp * dvsr)) >= DecimalNum()){
      nmbr -= tmp * dvsr;
      returned += tmp;
    }
    tmp /= 10;
  }
  if(flipsign)
    returned *= -1;
  returned.FixNum();
  *this = returned;
  return *this;
}

DecimalNum pow(DecimalNum & number, int power){
  DecimalNum tmp (1);
  for(int i = 0; i < power; i++)
    tmp *= number;
  return tmp;
}
	
DecimalNum sqrt(DecimalNum & number){
  assert(number >= DecimalNum());
  if(number == DecimalNum()) return DecimalNum();
  DecimalNum tmp (1);
  DecimalNum nmbr;
  short pwr = power(number);
  pwr /= 2;
  while(pwr != 0){
    if(pwr > 0){
      pwr --;
      tmp *= 10;
    } else {
      pwr ++;
      tmp /= 10;
    }
  }
  while(true){
    if((tmp == DecimalNum()) || (number == pow(nmbr, 2))) break;
    while((number - pow(nmbr, 2)) > DecimalNum())
      nmbr += tmp;
    nmbr -= tmp;
    tmp /= 10;
  }
  nmbr += DecimalNum(); // Forced use of FixNum while unable to access private functions.
  return nmbr;	
}

DecimalNum absoluteValue(DecimalNum nmbr){
  DecimalNum returned;
  for(short s = 0; s < nmbr.Size(); s ++)
    returned.arr[s] = abs(nmbr.arr[s]);
  return returned;
}
