/* FILE: GPU_fixedzeeman.h            -*-Mode: c++-*-
 *
 * Fixed (in time) Zeeman energy/field, derived from Oxs_Energy class.
 *
 */

#ifndef _UCSD_GPU_EXCHUNIFORM
#define _UCSD_GPU_EXCHUNIFORM

#define UCSD_GPU_CPU_TRANS

// Size of threevector.  This macro is defined for code legibility
// and maintenance; it should always be "3".
#include "oc.h"
#include "director.h"
#include "threevector.h"
#include "GPU_energy.h"
#include "simstate.h"
#include "mesh.h"
#include "meshvalue.h"
#include "vectorfield.h"

#include "GPU_helper.h"
#ifndef NDEBUG
#define NDEBUG
#endif
/* End includes */

class UCSD_GPU_UniformExchange
  : public UCSD_GPU_Energy, public Oxs_EnergyPreconditionerSupport  {
private:

  enum ExchangeCoefType {
    A_UNKNOWN, A_TYPE, LEX_TYPE
  }  excoeftype;
  OC_REAL8m A;
  OC_REAL8m lex;
  
  enum ExchangeKernel { 
      NGBR_UNKNOWN, NGBR_6_FREE,
      NGBR_6_MIRROR, NGBR_6_MIRROR_STD,
      NGBR_6_BIGANG_MIRROR, NGBR_6_ZD2,
			NGBR_12_FREE, NGBR_12_ZD1, NGBR_12_ZD1B,
			NGBR_12_MIRROR,	NGBR_26 
  } kernel;
  
  // Periodic boundaries?
  mutable int xperiodic;
  mutable int yperiodic;
  mutable int zperiodic;
  
  // Variables to track and store multiplier value for each simulation
  // state.  This data is computed once per state by the main thread,
  // and shared with all the children.
  mutable OC_UINT4m mult_state_id;
  mutable OC_REAL8m mult;
  mutable OC_REAL8m dmult; // Partial derivative of multiplier wrt t
  
  mutable OC_UINT4m mesh_id;
  
  // Support for threaded maxdot calculations
  mutable vector<OC_REAL8m> maxdot;
    
#if REPORT_TIME
  mutable Nb_StopWatch Anistime;
#endif
  mutable int maxGridSize;
  mutable FD_TYPE maxTotalThreads;
  
#ifdef GPU_DEBUG
  mutable std::ofstream location;
#endif

  mutable int _dev_num;
  mutable uint3 myBlk3DSize;
  mutable dim3 Knl_Blk_size;
  mutable dim3 Knl_Grid_size;
  mutable int3 host_Periodic;
  mutable FD_TYPE *dev_MValue;
  mutable FD_TYPE *dev_Msii;
  mutable FD_TYPE *dev_Energy;
  mutable FD_TYPE *dev_Field;
  mutable FD_TYPE *dev_Torque;
  mutable FD_TYPE *dev_energy_loc;
  mutable FD_TYPE *dev_field_loc;
  mutable FD_TYPE* dev_dot;
  mutable FD_TYPE* dev_dot_max;
  mutable FD_TYPE* dev_final_dot_max;
  mutable FD_TYPE *dev_tmp;
  mutable FD_TYPE* dev_volume;
  mutable FD_TYPE *tmp_energy;
  mutable FD_TYPE *tmp_field;
  void AllocCPUMemory(const OC_INDEX &size) const;
  void AllocGPUMemory(const OC_INDEX &size, DEVSTRUCT& dev_struct) const {};
  void ReleaseGPUMemory() const {};
  void ReleaseCPUMemory() const;
  
  void InitGPU(const OC_INDEX &size, DEVSTRUCT& dev_struct) const;
  void ReInitGPU(const DEVSTRUCT& dev_struct) const;
  
protected:
  virtual void GetEnergy(const Oxs_SimState& state,
			 Oxs_EnergyData& oed) const{};
  virtual void GPU_GetEnergy(const Oxs_SimState& state,
			 Oxs_EnergyData& oed, DEVSTRUCT& dev_struct,
			 unsigned int flag_outputH, unsigned int flag_outputE,
			 unsigned int flag_outputSumE, const OC_BOOL &flag_accum) const;
public:
  virtual const char* ClassName() const; // ClassName() is
  /// automatically generated by the OXS_EXT_REGISTER macro.
  UCSD_GPU_UniformExchange(const char* name,  // Child instance id
		  Oxs_Director* newdtr, // App director
		  const char* argstr);  // MIF input block parameters

  virtual ~UCSD_GPU_UniformExchange();// {ReleaseGPUMemory();}
  virtual OC_BOOL Init();

  // Optional interface for conjugate-gradient evolver.
  // For details on this code, see NOTES VI, 21-July-2011, pp 10-11.
  virtual OC_INT4m IncrementPreconditioner(
      PreconditionerData& pcd) {
    throw Oxs_ExtError(this, "preconditioner is not supported by GPU libraries yet");
  }
	
	void get_cubic_kernel_size(const uint3 &Dim, const uint3 &setBlkDim, 
      dim3* blocksize, dim3* gridsize ) const {
    (*blocksize).x = setBlkDim.x; (*blocksize).y = setBlkDim.y; (*blocksize).z = setBlkDim.z;
    (*gridsize).x = (Dim.x-1)/(*blocksize).x+1;
    (*gridsize).y = (Dim.y-1)/(*blocksize).y+1;
    (*gridsize).z = (Dim.z-1)/(*blocksize).z+1;
    if( (*gridsize).x > 65535 || (*gridsize).y > 65535 || (*gridsize).z > 65535) {
      String msg = String("GPU_Exch gridsize exceeds the limit, please try smaller problem.");
      throw Oxs_ExtError(msg.c_str());
    }
  }
};


#endif // _UCSD_GPU_EXCHUNIFORM
