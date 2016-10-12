int cons_rpc_exit(int index);
int cons_rpc_init(char*, int);
int cons_rpc_open(int index, char *lpass);
int cons_rpc_puts(int index, char *line);  
int cons_rpc_gets(int index, char *cmd, char *line);
int cons_rpc_putf(int index, char *sfile, char *dfile);
int cons_rpc_getf(int index, char *sfile, char *dfile);
