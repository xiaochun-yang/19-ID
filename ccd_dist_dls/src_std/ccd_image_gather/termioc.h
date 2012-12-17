double readdef (char* prompt, double def);
double readlimits (char* prompt, double min, double def, double max);
int readlogical (char* prompt, int def);
void readword (char* prompt, char* string );
void rdline (char* prompt, char* line);
void readupword (char* prompt, char* string);
void rdupline (char* prompt, char* line);

void readnums (char* prompt, float* fnum, int* inum, int* num);
void readwords (char* prompt, char** str, int* num);

int readcommand (char* prompt, char* commands);
int readnewcommand (char* prompt, char* commands);

void str_upcase (char* s1, char* s2);

void nolog (void);
void comlog ( char* commnt);
void onlog ( char* filnam);

void settok (int iset);
void clrtok (void);

void pquiet (int value);

void spawn( char* string);
void errout (char* string, int istat, int ireprt);

void stprmt (char *string);
void gtstrg (char** string, int* num );
void getcom (char* string, char* comnds, int* icom, int* ltok );
void getnum (float *fnum, int *inum, int *num);
int  getlin (char* string);

void wrtcmd (char *comnds);
void gettok (void);
void comstg (char *string, char *comnds, int *icom );
void rdstrg (void);
void ppout (char* filename);
void ppin (char* filename );

void hlpini (char* filnam);
void hlpstr (char *string, int iflag);
void hlphlp (char* string);

int msslen (char *line);
int ntklft (void);
void settok (int iset);

int redcmt (void);
int rederr (void);
void noprmt (void);

int ctrlc(int num);

FILE* luninq ( int iflag);

#define IPLUN 1     /* input parser lun */
#define OPLUN 2     /* output for parser prompts */
#define OUTLUN 3    /* general output */
#define ERRLUN 4    /* error lun used by routine ERROUT */
#define LOGLUN 5    /* log file lun */
