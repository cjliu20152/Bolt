/***************************************************************************                                                                                     
*   Copyright 2012 Advanced Micro Devices, Inc.                                     
*                                                                                    
*   Licensed under the Apache License, Version 2.0 (the "License");   
*   you may not use this file except in compliance with the License.                 
*   You may obtain a copy of the License at                                          
*                                                                                    
*       http://www.apache.org/licenses/LICENSE-2.0                      
*                                                                                    
*   Unless required by applicable law or agreed to in writing, software              
*   distributed under the License is distributed on an "AS IS" BASIS,              
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.         
*   See the License for the specific language governing permissions and              
*   limitations under the License.                                                   

***************************************************************************/                                                                                     

#define _REDUCE_STEP(_LENGTH, _IDX, _W) \
    if ((_IDX < _W) && ((_IDX + _W) < _LENGTH)) {\
      T mine = scratch[_IDX];\
      T other = scratch[_IDX + _W];\
      scratch[_IDX] = (*reduceFunctor)(mine, other); \
    }\
    barrier(CLK_LOCAL_MEM_FENCE);

template <typename T,  typename unary_function, typename binary_function>
kernel
void transform_reduceTemplate(
    global T* input, 
    const int length,
    global unary_function *transformFunctor,
	const T init,
    global binary_function *reduceFunctor,
    global T* result,
    local T *scratch
)
{
    int gx = get_global_id( 0 );

    //  Abort threads that are passed the end of the input vector
    if( gx >= length )
        return;
    
    //  Initialize the accumulator private variable with data from the input array
    //  This essentially unrolls the loop below at least once
    T accumulator = input[gx];
    accumulator = (*transformFunctor)( accumulator );
    gx += get_global_size( 0 );

    // Loop sequentially over chunks of input vector, reducing an arbitrary size input
    // length into a length related to the number of workgroups
    while( gx < length )
    {
        T element = input[gx];
        element = (*transformFunctor)( element );

        accumulator = (*reduceFunctor)( accumulator, element );
        gx += get_global_size(0);
    }

    // Perform parallel reduction through shared memory:
    int local_index = get_local_id( 0 );
    scratch[local_index] = accumulator;
    barrier(CLK_LOCAL_MEM_FENCE);   

    //  Tail stops the last workgroup from reading past the end of the input vector
    uint tail = length - (get_group_id(0) * get_local_size(0));
    
    //for(int offset = get_local_size(0) / 2;
    //    offset > 0;
    //    offset = offset / 2) {
    //    bool test = local_index < offset;
    //    if (test) {
    //        int other = scratch[local_index + offset];
    //        int mine  = scratch[local_index];
    //        scratch[local_index] = (*reduceFunctor)(mine, other);; 
    //    }
    //    barrier(CLK_LOCAL_MEM_FENCE);
    //}
    // Parallel reduction within a given workgroup using local data store
    // to share values between workitems
    _REDUCE_STEP( tail, local_index, 32 );
    _REDUCE_STEP( tail, local_index, 16 );
    _REDUCE_STEP( tail, local_index,  8 );
    _REDUCE_STEP( tail, local_index,  4 );
    _REDUCE_STEP( tail, local_index,  2 );
    _REDUCE_STEP( tail, local_index,  1 );

    if( local_index == 0 )
    {
        result[get_group_id( 0 )] = scratch[ 0 ];
    }
};

// #define KernelAnalyzer
#if defined( KernelAnalyzer )
template <typename T> 
struct square { T operator() (const T& x) const { return x * x; } };

template<typename T> 
struct plus { T operator()(const T &lhs, const T &rhs) const {return lhs + rhs;} };

// Host generates this instantiation string with user-specified value type and functor
template __attribute__((mangled_name(transform_reduceInstantiated)))
kernel void transform_reduceTemplate(
global int* A,
const int length,
global square<int>* transformFunctor,
const int init,
global plus<int>* reduceFunctor,
global int* result,
local int* scratch
);
#endif
