#include	<stdio.h>

struct sg_equiv {
		int	sg_eq_sgno;	/*	Space group number */
		int	sg_eq_sym1;	/*	unused symmetry op */
		int	sg_eq_sym2;	/*	unused symmetry op */
		char	*sg_eq_sgn;	/*	Space group name (lower case) */
		char	*sg_eq_pgn;	/*	point group name (lower case) */
		int	sg_eq_sys;	/*	system number */
		};

#define	UNKNOWN		0
#define	TRICLINIC	1
#define	MONOCLINIC	2
#define	ORTHORHOMBIC	3
#define	TETRAGONAL	4
#define	TRIGONAL	5
#define	HEXAGONAL	6
#define CUBIC		7


static struct sg_equiv sg_eq_list[] = 
{
0,1,1,"unknown","0", UNKNOWN,
1,1,1,"p1","1"       ,TRICLINIC,
2,2,2,"p-1","1"     ,TRICLINIC, 
3,2,2,"p2","2"      ,MONOCLINIC,
4,2,2,"p21","2"      ,MONOCLINIC,
5,4,2,"c2"  ,"2"    ,MONOCLINIC,
6,2,2,"pm"  ,"2" ,MONOCLINIC,
7,2,2,"pc"  ,"2" ,MONOCLINIC,
8,4,2,"cm"  ,"2" ,MONOCLINIC,
9,4,2,"cc"  ,"2" ,MONOCLINIC,
10,4,4,"p2/m","2" ,MONOCLINIC,
11,4,4,"p21/m","2" ,MONOCLINIC,
12,8,4,"c2/m","2" ,MONOCLINIC,
13,4,4,"p2/c","2" ,MONOCLINIC,
14,4,4,"p21/c","2" ,MONOCLINIC,
15,8,4,"c2/c","2" ,MONOCLINIC,
16,4,4,"p222" ,"222",ORTHORHOMBIC,
17,4,4,"p2221","222",ORTHORHOMBIC,
18,4,4,"p21212","222",ORTHORHOMBIC,
19,4,4,"p212121","222",ORTHORHOMBIC,
20,8,4,"c2221","222",ORTHORHOMBIC,
21,8,4,"c222" ,"222",ORTHORHOMBIC,
22,16,4,"f222","222",ORTHORHOMBIC,
23,8,4,"i222" ,"222",ORTHORHOMBIC,
24,8,4,"i212121","222" ,ORTHORHOMBIC,
25,4,4,"pmm2" ,"2m2",ORTHORHOMBIC,
26,4,4,"pmc21","222",ORTHORHOMBIC,
27,4,4,"pcc2" ,"222",ORTHORHOMBIC,
28,4,4,"pma2" ,"222",ORTHORHOMBIC,
29,4,4,"pca21","222",ORTHORHOMBIC,
30,4,4,"pnc2" ,"222",ORTHORHOMBIC,
31,4,4,"pmn21","222",ORTHORHOMBIC,
32,4,4,"pba2" ,"222",ORTHORHOMBIC,
33,4,4,"pna21","222",ORTHORHOMBIC,
34,4,4,"pnn2" ,"222",ORTHORHOMBIC,
35,8,4,"cmm2" ,"222",ORTHORHOMBIC,
36,8,4,"cmc21","222",ORTHORHOMBIC,
37,8,4,"ccc2" ,"222",ORTHORHOMBIC,
38,8,4,"amm2" ,"222",ORTHORHOMBIC,
39,8,4,"abm2" ,"222",ORTHORHOMBIC,
40,8,4,"ama2" ,"222",ORTHORHOMBIC,
41,8,4,"aba2" ,"222",ORTHORHOMBIC,
42,16,4,"fmm2","222",ORTHORHOMBIC,
43,16,4,"fdd2","222",ORTHORHOMBIC,
44,8,4,"imm2" ,"222",ORTHORHOMBIC,
45,8,4,"iba2" ,"222",ORTHORHOMBIC,
46,8,4,"ima2" ,"222",ORTHORHOMBIC, 
47,8,8,"pmmm" ,"222",ORTHORHOMBIC,
48,8,8,"pnnn","222",ORTHORHOMBIC,
49,8,8,"pccm","222",ORTHORHOMBIC,
50,8,8,"pban","222",ORTHORHOMBIC,
51,8,8,"pmma" ,"222",ORTHORHOMBIC,
52,8,8,"pnna" ,"222",ORTHORHOMBIC,
53,8,8,"pmna" ,"222",ORTHORHOMBIC,
54,8,8,"pcca" ,"222",ORTHORHOMBIC,
55,8,8,"pbam" ,"222",ORTHORHOMBIC,
56,8,8,"pccn" ,"222",ORTHORHOMBIC,
57,8,8,"pbcm" ,"222",ORTHORHOMBIC,
58,8,8,"pnnm" ,"222",ORTHORHOMBIC,
59,8,8,"pmmn" ,"222",ORTHORHOMBIC,
60,8,8,"pbcn" ,"222",ORTHORHOMBIC,
61,8,8,"pbca" ,"222",ORTHORHOMBIC,
62,8,8,"pnma" ,"222",ORTHORHOMBIC,
63,16,8,"cmcm","222",ORTHORHOMBIC,
64,16,8,"cmca","222",ORTHORHOMBIC,
65,16,8,"cmmm","222",ORTHORHOMBIC,
66,16,8,"cccm","222",ORTHORHOMBIC,
67,16,8,"cmma","222",ORTHORHOMBIC,
68,16,8,"ccca","222",ORTHORHOMBIC,
69,32,8,"fmmm","222",ORTHORHOMBIC,
70,32,8,"fddd","222",ORTHORHOMBIC,
71,16,8,"immm","222",ORTHORHOMBIC,
72,16,8,"ibam","222",ORTHORHOMBIC,
73,16,8,"ibca","222",ORTHORHOMBIC,
74,16,8,"imma","222",ORTHORHOMBIC,
75,4,4,"p4"  ,"4",TETRAGONAL,
76,4,4,"p41" ,"4",TETRAGONAL,
77,4,4,"p42" ,"4",TETRAGONAL,
78,4,4,"p43" ,"4",TETRAGONAL,
79,8,4,"i4"  ,"4",TETRAGONAL,
80,8,4,"i41" ,"4",TETRAGONAL,
81,4,4,"p-4" ,"4",TETRAGONAL,
82,8,4,"i-4" ,"4",TETRAGONAL,
83,8,8,"p4/m","4",TETRAGONAL,      
84,8,8,"p42/m","4",TETRAGONAL,
85,8,8,"p4/n","4",TETRAGONAL,
86,8,8,"p42/n","4",TETRAGONAL,
87,16,8,"i4/m","4",TETRAGONAL,
88,16,8,"i41/a" ,"4",TETRAGONAL,
89,8,8,"p422","422",TETRAGONAL,
90,8,8,"p4212","422",TETRAGONAL,
91,8,8,"p4122","422",TETRAGONAL,
92,8,8,"p41212","422",TETRAGONAL,
93,8,8,"p4222","422",TETRAGONAL,
94,8,8,"p42212","422",TETRAGONAL,
95,8,8,"p4322","422",TETRAGONAL,
96,8,8,"p43212","422",TETRAGONAL,
97,16,8,"i422","422",TETRAGONAL,
98,16,8,"i4122","422",TETRAGONAL,
99,8,8,"p4mm","422",TETRAGONAL,
100,8,8,"p4bm","422",TETRAGONAL,
101,8,8,"p42cm","422",TETRAGONAL,
102,8,8,"p42nm","422",TETRAGONAL,
103,8,8,"p4cc","422",TETRAGONAL,
104,8,8,"p4nc","422",TETRAGONAL,
105,8,8,"p42mc","422",TETRAGONAL,
106,8,8,"p42bc","422",TETRAGONAL,
107,16,8,"i4mm","422",TETRAGONAL,
108,16,8,"i4cm","422",TETRAGONAL,
109,16,8,"i41md","422",TETRAGONAL,
110,16,8,"i41cd","422",TETRAGONAL,
111,8,8,"p-42m","4bar2m",TETRAGONAL,
112,8,8,"p-42c","4bar2m",TETRAGONAL,
113,8,8,"p-421m","4bar2m",TETRAGONAL,
114,8,8,"p-421c","4bar2m",TETRAGONAL,
115,8,8,"p-4m2","4barm2",TETRAGONAL,
116,8,8,"p-4c2","4barm2",TETRAGONAL,
117,8,8,"p-4b2","4barm2",TETRAGONAL,
118,8,8,"p-4n2","4barm2",TETRAGONAL,
119,16,8,"i-4m2","4barm2",TETRAGONAL,
120,16,8,"i-4c2","4barm2",TETRAGONAL,
121,16,8,"i-42m","4bar2m",TETRAGONAL,
122,16,8,"i-42d","4bar2m",TETRAGONAL,
123,16,16,"p4/mmm","422",TETRAGONAL,
124,16,16,"p4/mcc","422",TETRAGONAL,
125,16,16,"p4/nbm","422",TETRAGONAL,
126,16,16,"p4/nnc","422",TETRAGONAL,
127,16,16,"p4/mbm","422",TETRAGONAL,
128,16,16,"p4/mnc","422",TETRAGONAL,
129,16,16,"p4/nmm","422",TETRAGONAL,
130,16,16,"p4/ncc","422",TETRAGONAL,
131,16,16,"p42/mmc","422",TETRAGONAL,
132,16,16,"p42/mcm","422",TETRAGONAL,
133,16,16,"p42/nbc","422",TETRAGONAL,
134,16,16,"p42/nnm","422",TETRAGONAL,
135,16,16,"p42/mbc","422",TETRAGONAL,
136,16,16,"p42/mnm","422",TETRAGONAL,
137,16,16,"p42/nmc","422",TETRAGONAL,
138,16,16,"p42/ncm","422",TETRAGONAL,
139,32,16,"i4/mmm","422",TETRAGONAL,
140,32,16,"i4/mcm","422",TETRAGONAL,
141,32,16,"i41/amd","422",TETRAGONAL,
142,32,16,"i41/acd","422",TETRAGONAL,
143,3,3,"p3"        ,"3",TRIGONAL,
144,3,3,"p31"       ,"3",TRIGONAL,
145,3,3,"p32"       ,"3",TRIGONAL,
146,9,3,"r3"        ,"3",TRIGONAL,
147,6,6,"p-3"       ,"3",TRIGONAL,
148,18,6,"r-3"      ,"3",TRIGONAL,
149,6,6,"p312"     ,"312",TRIGONAL,
150,6,6,"p321"     ,"321",TRIGONAL,
151,6,6,"p3112"    ,"312",TRIGONAL,
152,6,6,"p3121"    ,"321",TRIGONAL,
153,6,6,"p3212"    ,"312",TRIGONAL,
154,6,6,"p3221"    ,"321",TRIGONAL,
155,18,6,"r32"     ,"32",TRIGONAL,
156,6,6,"p3m1"     ,"3m1",TRIGONAL,
157,6,6,"p31m"     ,"31m",TRIGONAL,
158,6,6,"p3c1"     ,"3m1",TRIGONAL,
159,6,6,"p31c"     ,"31m",TRIGONAL,
160,18,6,"r3m"     ,"3m",TRIGONAL,
161,18,6,"r3c"     ,"3m",TRIGONAL,
162,12,12,"p-31m"  ,"312",TRIGONAL,
163,12,12,"p-31c"  ,"312",TRIGONAL,
164,12,12,"p-3m1"   ,"321",TRIGONAL,
165,12,12,"p-3c1"  ,"3m1",TRIGONAL,
166,36,12,"r-3m"   ,"32",TRIGONAL,
167,36,12,"r-3c"   ,"3m",TRIGONAL,
168,6,6,"p6"       ,"6",HEXAGONAL,
169,6,6,"p61"      ,"6",HEXAGONAL,
170,6,6,"p65"      ,"6",HEXAGONAL,
171,6,6,"p62"      ,"6",HEXAGONAL,
172,6,6,"p64"      ,"6",HEXAGONAL, 
173,6,6,"p63"      ,"6",HEXAGONAL,
174,6,6,"p-6"      ,"6",HEXAGONAL,
175,12,12,"p6/m"   ,"6/m",HEXAGONAL,
176,12,12,"p63/m"  ,"6/m",HEXAGONAL,
177,12,12,"p622"   ,"622",HEXAGONAL,
178,12,12,"p6122"  ,"622",HEXAGONAL,
179,12,12,"p6522"  ,"622",HEXAGONAL,
180,12,12,"p6222"  ,"622",HEXAGONAL,
181,12,12,"p6422"  ,"622",HEXAGONAL,
182,12,12,"p6322"  ,"622",HEXAGONAL,
183,12,12,"p6mm"   ,"6mm",HEXAGONAL,
184,12,12,"p6cc"   ,"6mm",HEXAGONAL,
185,12,12,"p63cm"  ,"6mm",HEXAGONAL,
186,12,12,"p63mc"  ,"6mm",HEXAGONAL,
187,12,12,"p-6m2"  ,"6m2",HEXAGONAL,
188,12,12,"p-6c2"  ,"6m2",HEXAGONAL,
189,12,12,"p-62m"  ,"62m",HEXAGONAL,
190,12,12,"p-62c"  ,"62m",HEXAGONAL,
191,24,24,"p6/mmm" ,"622",HEXAGONAL,
192,24,24,"p6/mcc"  ,"622",HEXAGONAL,
193,24,24,"p63/mcm" ,"622",HEXAGONAL,
194,24,24,"p63/mmc"  ,"622",HEXAGONAL,
195,12,12,"p23"     ,"23",CUBIC,
196,48,12,"f23"     ,"23",CUBIC,
197,24,12,"i23"     ,"23",CUBIC,
198,12,12,"p213"    ,"23",CUBIC,
199,24,12,"i213"    ,"23",CUBIC,
200,24,24,"pm3"      ,"23",CUBIC,
201,24,24,"pn3"     ,"23",CUBIC,
202,96,24,"fm3"     ,"23",CUBIC,
203,96,24,"fd3"    ,"23",CUBIC,
204,48,24,"im3"    ,"23",CUBIC,
205,24,24,"pa3"    ,"23",CUBIC,
206,48,24,"ia3"    ,"23",CUBIC,
207,24,24,"p432"    ,"432",CUBIC,
208,24,24,"p4232"  ,"432",CUBIC,
209,96,24,"f432"   ,"432",CUBIC,
210,96,24,"f4132"   ,"432",CUBIC,
211,48,24,"i432"    ,"432",CUBIC,
212,24,24,"p4332"   ,"432",CUBIC,
213,24,24,"p4132"  ,"432",CUBIC,
214,48,24,"i4132"    ,"432",CUBIC,
215,24,24,"p-43m"    ,"4bar3m",CUBIC,
216,96,24,"f-43m"   ,"4bar3m",CUBIC,
217,48,24,"i43m"    ,"4bar3m",CUBIC,
218,24,24,"p-43n"   ,"4bar3m",CUBIC,
219,96,24,"f-43c"   ,"4bar3m",CUBIC,
220,48,24,"i-43d"    ,"4bar3m",CUBIC,
221,48,48,"pm3m"   ,"432",CUBIC,
222,48,48,"pn3n"   ,"23m",CUBIC,
223,48,48,"pm3n"    ,"23m",CUBIC,
224,48,48,"pn3m"    ,"23m",CUBIC,
225,192,48,"fm3m"   ,"432",CUBIC,
226,192,48,"fm3c"   ,"23m",CUBIC,
227,48,48,"fd3m"   ,"23m",CUBIC,
228,192,48,"fd3c"   ,"23m",CUBIC,
229,96,48,"im3m"    ,"432",CUBIC,
230,96,48,"ia3d"    ,"23m",CUBIC,
-1,-1,-1,NULL,NULL,-1
};

static char *sg_lat_names[] =  { "P","C","I","F","R","A","B",NULL};

/*
 *	Return the space group number of the
 *	name space_group_name.  If not found,
 *	return 0 (unknown).  Convert input to
 *	lower case (leave original string alone),
 *	so that the input can be UC or mixed case.
 */

int	get_space_group_number(space_group_name)
char	*space_group_name;
  {
	char	lc_sg_name[30];
	int	i;

	for(i = 0; space_group_name[i] != '\0'; i++)
	  if(space_group_name[i] >= 'A' && space_group_name[i] <= 'Z')
		lc_sg_name[i] = space_group_name[i] + ('a' - 'A');
	    else
		lc_sg_name[i] = space_group_name[i];
	lc_sg_name[i] = '\0';

	for(i = 0; sg_eq_list[i].sg_eq_sgn != NULL; i++)
	  if(0 == strcmp(sg_eq_list[i].sg_eq_sgn,lc_sg_name))
		return(sg_eq_list[i].sg_eq_sgno);
	
	return(0);
  }

/*
 *	Return a pointer to the space group name string
 *	corresponding to the number given.
 */

char	*get_space_group_name(number)
int	number;
  {
	return(sg_eq_list[number].sg_eq_sgn);
  }

/*
 *	Return the space group system number of the
 *	space group number given.
 */

int	get_sp_system_number(number)
int	number;
  {
	return(sg_eq_list[number].sg_eq_sys);
  }

/*
 *	Return the point group string according to the
 *	space group number given.
 */

char	*get_pg_by_number(number)
int	number;
  {
	return(sg_eq_list[number].sg_eq_pgn);
  }

/*
 *	Return the point group string pointer of the
 *	name space_group_name.  If not found,
 *	return NULL (unknown).  Convert input to
 *	lower case (leave original string alone),
 *	so that the input can be UC or mixed case.
 */

char	*get_point_group_name(space_group_name)
char	*space_group_name;
  {
	char	lc_sg_name[30];
	int	i;

	for(i = 0; space_group_name[i] != '\0'; i++)
	  if(space_group_name[i] >= 'A' && space_group_name[i] <= 'Z')
		lc_sg_name[i] = space_group_name[i] + ('a' - 'A');
	    else
		lc_sg_name[i] = space_group_name[i];
	lc_sg_name[i] = '\0';

	for(i = 0; sg_eq_list[i].sg_eq_sgn != NULL; i++)
	  if(0 == strcmp(sg_eq_list[i].sg_eq_pgn,lc_sg_name))
		return(sg_eq_list[i].sg_eq_pgn);
	
	return(NULL);
  }
/*
 *	Return the lattice type string pointer of the
 *	name space_group_name.  If not found,
 *	return NULL (unknown).  Convert input to
 *	lower case (leave original string alone),
 *	so that the input can be UC or mixed case.
 *
 *	This routine returns a pointer to an uppercase
 *	string, which is the "nice" convention.
 */

static	char	null_return[] = "";

char	*get_lattice_type(space_group_name)
char	*space_group_name;
  {
	char	lc_sg_name[30];
	int	i,j;

	for(i = 0; space_group_name[i] != '\0'; i++)
	  if(space_group_name[i] >= 'A' && space_group_name[i] <= 'Z')
		lc_sg_name[i] = space_group_name[i] + ('a' - 'A');
	    else
		lc_sg_name[i] = space_group_name[i];
	lc_sg_name[i] = '\0';

	for(i = 0; sg_eq_list[i].sg_eq_sgn != NULL; i++)
	  if(0 == strcmp(sg_eq_list[i].sg_eq_sgn,lc_sg_name))
	    {
		for(j = 0; sg_lat_names[j] != NULL; j++)
		  if(sg_lat_names[j][0] == (sg_eq_list[i].sg_eq_sgn[0] - ('a' -'A')))
		return(sg_lat_names[j]);
	    }
	
	return(null_return);
  }
