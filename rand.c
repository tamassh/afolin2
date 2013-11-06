/*
	Random data generation by Tamas Bogdan <tamas.bogdan@hp.com>
	version 1.0
*/
#include <stdio.h>
#include <stdlib.h>

// s => string to populate
// len => length of the generated string
void gen_random(char *s, const int len) {
    static const char alphanum[] =
        "0123456789"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz"
	"~!@#$%^&*()+-=`]}[{'|/>,<";

    for (int i = 0; i < len; ++i) {
        s[i] = alphanum[rand() % (sizeof(alphanum) - 1)];
    }
	
	// last "member" of s is 0
    s[len] = 0;
}

int main(int argc, char *argv[]){

if (argc == 1){
printf("You must define the parameter of the number of 1M blocks to generate\n");
exit(1);
}

char st[1048577];
int i,loops;

loops=atoi(argv[1]);

for (i=0; i < loops; i++){
gen_random(st,1048576);	// ~1M align
printf("%s\n", st);  
}

return 0;
}
