#include <math.h>

#include "../tp2.h"

#define PI 			3.1415
#define RADIUS 		35
#define WAVELENGTH 	64
#define TRAINWIDTH 	3.4

float sin_taylor (float x) {
	float x_3 = x*x*x;
	float x_5 = x*x*x*x*x;
	float x_7 = x*x*x*x*x*x*x;

	return x-(x_3/6.0)+(x_5/120.0)-(x_7/5040.0);
}

float profundidad (int x, int y, int x0, int y0) {
	float dx = x - x0;
	float dy = y - y0;

	float dxy = sqrt(dx*dx+dy*dy);

	float r = (dxy-RADIUS)/WAVELENGTH ;
	float k = r-floor(r);
	float a = 1.0/(1.0+(r/TRAINWIDTH)*(r/TRAINWIDTH));

	float t = k*2*PI-PI;

	float s_taylor = sin_taylor(t);

	return a * s_taylor;
}

void ondas_c (unsigned char *src, unsigned char *dst, int width, int height, int src_row_size, int dst_row_size, int x0, int y0){
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

	// ~ completar
	int x = 0;
	for(int y=0; y<height; ++y){ //Con y recorro filas
		for(int i=0; i<src_row_size; ++i){ //Con i recorro columnas
			if(i % 4 == 0)x++; //Con x recorro pixeles por columna
			if(i == 0)x=0;
			if(i % 4 == 3){
				dst_matrix[y][i] = src_matrix[y][i];
			} else {
				float pixel = profundidad(x,y,x0,y0)*64 + (float)src_matrix[y][i];
				dst_matrix[y][i] = fmin(fmax(pixel,0),255);
				}	
		}
	}
}


