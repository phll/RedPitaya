#ifndef CONTROLLER_H_
#define CONTROLLER_H_

#include "scpi/types.h"

scpi_result_t LC_Init();
scpi_result_t LC_Release();

scpi_result_t LC_ControllerData(scpi_t * context);
scpi_result_t LC_AwaitTrigger(scpi_t * context);
scpi_result_t LC_SoftwareTrigger(scpi_t * context);

int writeChannelSequence(int ch, double *chs_data, size_t ch_len, bool enable, char **out, int* err_ev, double* worst_timing_dev, int* worst_timing_ev, double* total_timing_dev, double* worst_dac_dev, int* worst_dac_ev);


#endif
