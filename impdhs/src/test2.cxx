#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

int main(){
	printf("Starting test program.\nGenerating random sequences of writes to temp.doc\n");
	while(true){
		printf("before file open\n");
		FILE* temp = fopen("/home/webserverroot/servlets/webice/data/strategy/BL-sim/temp.doc","w");
		if(temp != NULL){
			printf("after file open\n");
			switch((int)(6.0*rand()/(RAND_MAX+1.0))){
				case 0:	fputs("error",temp);printf("error\n");break;
				case 1:	fputs("done",temp);printf("done\n");break;
				case 2:	fputs("running",temp);printf("running\n");break;
				case 3: fputs("",temp);printf("\n");break;
				case 4:fputs("pending",temp);printf("pending\n");break;
				default:fputs("unknowndata",temp);printf("unknown\n");break;
			}
			printf("before file close\n");
			fclose(temp);
			printf("after file close\n");
		}
		else{
			printf("error opening file errno = %d\n",errno);
		}
		int y = 0;
		for(int x =0;x<3500000000;x++){
			y +=x;

		}
	}
}
