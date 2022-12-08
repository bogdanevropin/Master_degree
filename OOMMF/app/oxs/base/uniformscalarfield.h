/* FILE: uniformscalarfield.h      -*-Mode: c++-*-
 *
 * Uniform scalar field object, derived from Oxs_ScalarField
 * class.
 *
 */

#ifndef _OXS_UNIFORMSCALARFIELD
#define _OXS_UNIFORMSCALARFIELD

#include "oc.h"

#include "scalarfield.h"

/* End includes */

class Oxs_UniformScalarField:public Oxs_ScalarField {
private:
  OC_REAL8m value;
public:
  virtual const char* ClassName() const; // ClassName() is
  /// automatically generated by the OXS_EXT_REGISTER macro.

  Oxs_UniformScalarField
  (const char* name,     // Child instance id
   Oxs_Director* newdtr, // App director
   const char* argstr);  // MIF input block parameters

  virtual ~Oxs_UniformScalarField() {}

  virtual OC_REAL8m Value(const ThreeVector& pt) const;

  virtual void FillMeshValue(const Oxs_Mesh* mesh,
			     Oxs_MeshValue<OC_REAL8m>& array) const;
  virtual void IncrMeshValue(const Oxs_Mesh* mesh,
			     Oxs_MeshValue<OC_REAL8m>& array) const;
  virtual void MultMeshValue(const Oxs_Mesh* mesh,
			     Oxs_MeshValue<OC_REAL8m>& array) const;

  OC_REAL8m SoleValue() const { return value; }
};


#endif // _OXS_UNIFORMSCALARFIELD
