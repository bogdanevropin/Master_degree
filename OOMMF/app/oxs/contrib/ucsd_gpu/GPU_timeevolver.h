/* FILE: GPU_timeevolver.h                 -*-Mode: c++-*-
 *
 * Abstract time evolver class on GPU
 *
 */

#ifndef _UCSD_GPU_TIMEEVOLVER
#define _UCSD_GPU_TIMEEVOLVER

#include "timeevolver.h"

#include "GPU_devstruct.h"

/* End includes */

class UCSD_GPU_TimeDriver; // Forward references

class UCSD_GPU_TimeEvolver:public Oxs_TimeEvolver {
private:

  OC_UINT4m energy_calc_count; // Number of times GetEnergyDensity
  OC_INDEX energy_state_id;
  /// has been called in current problem run.

  Oxs_MeshValue<OC_REAL8m> temp_energy;     // Scratch space used by
  Oxs_MeshValue<ThreeVector> temp_field; // GetEnergyDensity().

  // Outputs maintained by this interface layer.  These are conceptually
  // public, but are specified private to force clients to use the
  // output_map interface.
  void UpdateEnergyOutputs(const Oxs_SimState&);
  void FillEnergyCalcCountOutput(const Oxs_SimState&);
  Oxs_ScalarOutput<UCSD_GPU_TimeEvolver> total_energy_output;
  Oxs_ScalarFieldOutput<UCSD_GPU_TimeEvolver> total_energy_density_output;
  Oxs_VectorFieldOutput<UCSD_GPU_TimeEvolver> total_field_output;
  Oxs_ScalarOutput<UCSD_GPU_TimeEvolver> energy_calc_count_output;

  // Disable copy constructor and assignment operator by declaring
  // them without defining them.
  UCSD_GPU_TimeEvolver(const Oxs_TimeEvolver&);
  UCSD_GPU_TimeEvolver& operator=(const Oxs_TimeEvolver&);

  mutable int maxGridSize;
  mutable FD_TYPE maxTotalThreads;
  
  mutable bool initialized;
  DEVSTRUCT &host_struct;
  OC_BOOL InitGPU(const Oxs_SimState& state);
protected:

#if REPORT_TIME
  mutable Nb_StopWatch steponlytime;
  mutable Nb_StopWatch myEnergyTime;
#endif

  UCSD_GPU_TimeEvolver(const char* name,
                 Oxs_Director* newdtr,
                 const char* argstr, 
                 DEVSTRUCT &host_struct_in);      // MIF block argument string
				 
  virtual OC_BOOL Init();
  void GPU_GetEnergyDensity(const Oxs_SimState& state,
			Oxs_MeshValue<OC_REAL8m>& energy,
			Oxs_MeshValue<ThreeVector>* mxH_req,
			Oxs_MeshValue<ThreeVector>* H_req,
			OC_REAL8m& pE_pt);

public:
  virtual ~UCSD_GPU_TimeEvolver();

  virtual OC_BOOL
  InitNewStage(const UCSD_GPU_TimeDriver* /* driver */,
               Oxs_ConstKey<Oxs_SimState> /* state */,
               Oxs_ConstKey<Oxs_SimState> /* prevstate */) { return 1; }
  /// Default implementation is a NOP.  Children may override.
  /// NOTE: prevstate may be "INVALID".  Children should check
  ///       before use.

  virtual OC_BOOL
  Step(const UCSD_GPU_TimeDriver* driver,
       Oxs_ConstKey<Oxs_SimState> current_state,
       const Oxs_DriverStepInfo& step_info,
       Oxs_Key<Oxs_SimState>& next_state,
       DEVSTRUCT &host_struct_copy) = 0;
  // Returns true if step was successful, false if
  // unable to step as requested.  The evolver object
  // is responsible for calling driver->FillState()
  // and driver->FillStateSupplemental() to fill
  // next_state as needed.
};

#endif // _UCSD_GPU_TIMEEVOLVER
