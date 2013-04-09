/***************************************************************************                                                                                     
*   Copyright 2012 - 2013 Advanced Micro Devices, Inc.                                     
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

#include "matrix_utils.h"

extern cl::Kernel compileOpenCLFile(const std::string &kernelCodeString, const std::string kernelName);

extern bool update_trz_oclcpp(cl::Kernel k, H3& dH, const cl::Buffer& I1, int ipitch, const cl::Buffer& wI2, int wpitch, float sigma, float gradThresh, const  utils::Rect& roi );

extern void printLOC_OclCpp();