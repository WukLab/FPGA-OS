#ifndef _SEGMENT_CORE_HPP_
#define _SEGMENT_CORE_HPP_

#include "../include/translate.hpp"

/* typedef is alwasy EVIL. But C++ is just.. */
typedef struct mmu_trans_data<32, 8>	trans_meta_t;

typedef hls::stream<trans_meta_t>	trans_meta_axis_t;

#endif /* _SEGMENT_CORE_HPP_ */
