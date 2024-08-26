
#include <stdio.h>
#include <string.h>

#include "../tp2.h"

void edge_asm    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

void edge_c    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

typedef void (edge_fn_t) (unsigned char*, unsigned char*, int, int, int, int);


void leer_params_edge(configuracion_t *config, int argc, char *argv[]) {
	config->bits_src = 8;
	config->bits_dst = 8;
}

void aplicar_edge(configuracion_t *config)
{
	edge_fn_t *edge = SWITCH_C_ASM ( config, edge_c, edge_asm ) ;
	buffer_info_t info = config->src;
	edge(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
	         config->dst.width_with_padding);

}

void ayuda_edge()
{
	printf ( "       * edge\n" );
	printf ( "           Parámetros     : \n"
	         "                         no tiene\n");
	printf ( "           Ejemplo de uso : \n"
	         "                         edge -i c facil.bmp\n" );
}

DEFINIR_FILTRO(edge)

