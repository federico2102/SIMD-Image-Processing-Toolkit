
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "../tp2.h"

void ondas_asm    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size, int x0, int y0);

void ondas_c    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size, int x0, int y0);

typedef void (ondas_fn_t) (unsigned char*, unsigned char*, int, int, int, int, int, int);

typedef struct ondas_params_t {
	int x0, y0;
} ondas_params_t;

ondas_params_t extra;
void leer_params_ondas(configuracion_t *config, int argc, char *argv[]) {
	config->extra_config = &extra;
	extra.x0 = atoi(argv[argc - 2]);
	extra.y0 = atoi(argv[argc - 1]);
}

void aplicar_ondas(configuracion_t *config)
{
	ondas_params_t *extra = (ondas_params_t*)config->extra_config;

	ondas_fn_t *ondas = SWITCH_C_ASM ( config, ondas_c, ondas_asm ) ;
	buffer_info_t info = config->src;
	ondas(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
	         config->dst.width_with_padding, extra->x0, extra->y0);

}

void ayuda_ondas()
{
	printf ( "       * ondas\n" );
	printf ( "           Parámetros     : \n"
	         "                         x0    centro en el eje x\n"
             "                         y0    centro en el eje y\n");
	printf ( "           Ejemplo de uso : \n"
	         "                         ondas -i c 100 200 facil.bmp\n" );
}

DEFINIR_FILTRO(ondas)

