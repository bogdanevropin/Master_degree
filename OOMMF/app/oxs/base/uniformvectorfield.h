/* FILE: uniformvectorfield.h     -*-Mode: c++-*-
 *
 * Uniform vector field object, derived from Oxs_VectorField class.
 *
 */

#ifndef _OXS_UNIFORMVECTORFIELD
#define _OXS_UNIFORMVECTORFIELD

#include "oc.h"

#include "vectorfield.h"

/* End includes */

class Oxs_UniformVectorField:public Oxs_VectorField {
private:
  ThreeVector vec;
public:
  virtual const char* ClassName() const; // ClassName() is
  /// automatically generated by the OXS_EXT_REGISTER macro.

  Oxs_UniformVectorField
  (const char* name,     // Child instance id
   Oxs_Director* newdtr, // App director
   const char* argstr);  // MIF input block parameters

  virtual ~Oxs_UniformVectorField() {}

  virtual void Value(const ThreeVector& pt,ThreeVector& value) const;

  virtual void FillMeshValue(const Oxs_Mesh* mesh,
			     Oxs_MeshValue<ThreeVector>& array) const;

  void SetMag(OC_REAL8m size=1.0) { vec.SetMag(size); }

  const ThreeVector& SoleValue() const { return vec; }

};


#endif // _OXS_UNIFORMVECTORFIELD
