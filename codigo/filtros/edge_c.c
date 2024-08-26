#define max(a, b) ((a)>(b))?(a):(b)
#define min(a, b) ((a)<(b))?(a):(b)
#include <stdio.h>
#include "../tp2.h"

void edge_c (unsigned char *src, unsigned char *dst, int width, int height, int src_row_size, int dst_row_size)
{

	// ~ completar

	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

	for (int i_d = 0, i_s = 0; i_d < 1; i_d++, i_s++) {
		for (int j_d = 0, j_s = 0; j_d < width; j_d++, j_s++) {
			dst_matrix[i_d][j_d] = src_matrix[i_d][j_d];
		}
	}	
	for (int i_d = height-1, i_s = height-1; i_d < height; i_d++, i_s++) {
		for (int j_d = 0, j_s = 0; j_d < width; j_d++, j_s++) {
			dst_matrix[i_d][j_d] = src_matrix[i_d][j_d];
		}
	}	

	for (int i_d = 0, i_s = 0; i_d < height; i_d++, i_s++) {
		for (int j_d = 0, j_s = 0; j_d < 1; j_d++, j_s++) {
			dst_matrix[i_d][j_d] = src_matrix[i_d][j_d];
		}
		for (int j_d = width-1, j_s = width-1; j_d < width; j_d++, j_s++) {
			dst_matrix[i_d][j_d] = src_matrix[i_d][j_d];
		}
	}

	for (int i_d = 1, i_s = 1; i_d < height-1; i_d++, i_s++) {
		for (int j_d = 1, j_s = 1; j_d < width-1; j_d++, j_s++) {
			float a = 0; 
			a += src_matrix[i_s-1][j_s-1] * 0.5; 
			a += src_matrix[i_s-1][j_s]; 
			a += src_matrix[i_s-1][j_s+1] * 0.5; 

			a += src_matrix[i_s][j_s-1]; 
			a += src_matrix[i_s][j_s] * -6; 
			a += src_matrix[i_s][j_s+1]; 

			a += src_matrix[i_s+1][j_s-1] * 0.5; 
			a += src_matrix[i_s+1][j_s]; 
			a += src_matrix[i_s+1][j_s+1] * 0.5; 
			dst_matrix[i_d][j_d] = min(max(a, 0), 255);
		}
	}

}






