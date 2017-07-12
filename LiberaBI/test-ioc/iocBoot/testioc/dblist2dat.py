f = open('dblist.txt')
data1 = f.read()  
f.close()
print type(data1) 
 
lines1 = data1.split('\n') 
print type(lines1)
import re

f = open('testdat.dat', 'w') 
for line in lines1:
	dcssvar=re.sub(r"LIBERA01:.*:", "", line)
	dcssvar=dcssvar.lower()
	f.write(dcssvar+"\n")
	f.write("13\n")
	f.write("test_epics_gw "+line+"\n")
	f.write("1 1 1 1 1\n")
	f.write("1 1 1 1 1\n")
	f.write("\n")
f.close()
