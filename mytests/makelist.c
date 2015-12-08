#include <stdio.c>
#define MAXBYTES 65536

char buffer[MAXBYTES];

int main(int argc, char** argv){
  FILE* input, output;

  int i = 0;
  char hexadecimal1 = 0, hexadecimal2 = 0;
  char tmp1,tmp2;

  if (argc !=3){
	printf("usage: makelist hex_file list_file\n");
	exit(1);
  }

  if(input = fopen(argv[1], "r")==NULL){
	printf("couldn't open file %s\n",argv[1]);
	exit(1);
  }
  if(output = fopen(argv[2], "w")==NULL){
	printf("couldn't open file %s\n",argv[1]);
	exit(1);
  }
  for (i = 0;i++;i<10000){
	buffer[i] = fgetc(input);
	if (buffer[i] == EOF) break;
  }
  /*convert the bytes to hex values and print out*/
  for (i = 0;i<MAXBYTES;i++){
	tmp1 = buffer[i]|0x0f;
	tmp2 = (buffer[i]|0xf0)>>4;

	switch(tmp1){
	0x00: hexadecimal1 = '0';break;
	0x01: hexadecimal1 = '1';break;
	0x02: hexadecimal1 = '2';break;
	0x03: hexadecimal1 = '3';break;
	0x04: hexadecimal1 = '4';break;
	0x05: hexadecimal1 = '5';break;
	0x06: hexadecimal1 = '6';break;
	0x07: hexadecimal1 = '7';break;
	0x08: hexadecimal1 = '8';break;
	0x09: hexadecimal1 = '9';break;
	0x0a: hexadecimal1 = 'A';break;
	0x0b: hexadecimal1 = 'B';break;
	0x0c: hexadecimal1 = 'C';break;
	0x0d: hexadecimal1 = 'D';break;
	0x0e: hexadecimal1 = 'E';break;
	0x0f: hexadecimal1 = 'F';break;
	default: ;
	}

	switch(tmp2){
	0x00: hexadecimal2 = '0';break;
	0x01: hexadecimal2 = '1';break;
	0x02: hexadecimal2 = '2';break;
	0x03: hexadecimal2 = '3';break;
	0x04: hexadecimal2 = '4';break;
	0x05: hexadecimal2 = '5';break;
	0x06: hexadecimal2 = '6';break;
	0x07: hexadecimal2 = '7';break;
	0x08: hexadecimal2 = '8';break;
	0x09: hexadecimal2 = '9';break;
	0x0a: hexadecimal2 = 'A';break;
	0x0b: hexadecimal2 = 'B';break;
	0x0c: hexadecimal2 = 'C';break;
	0x0d: hexadecimal2 = 'D';break;
	0x0e: hexadecimal2 = 'E';break;
	0x0f: hexadecimal2 = 'F';break;
	default: ;
	}
	fprintf(output,"%c%c\n",hexadecimal1,hexadecimal2);

  }
  close(input);
  close(output);
  
  return 0;
}





  
