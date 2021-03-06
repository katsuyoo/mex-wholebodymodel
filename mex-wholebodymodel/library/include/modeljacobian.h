/*
 * Copyright (C) 2014 Robotics, Brain and Cognitive Sciences - Istituto Italiano di Tecnologia
 * Authors: Naveen Kuppuswamy
 * email: naveen.kuppuswamy@iit.it
 * modified by: Martin Neururer; email: martin.neururer@gmail.com; date: June, 2016 & January, 2017
 *
 * The development of this software was supported by the FP7 EU projects
 * CoDyCo (No. 600716 ICT 2011.2.1 Cognitive Systems and Robotics (b))
 * http://www.codyco.eu
 *
 * Permission is granted to copy, distribute, and/or modify this program
 * under the terms of the GNU General Public License, version 2 or any
 * later version published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details
 */

#ifndef MODELJACOBIAN_H
#define MODELJACOBIAN_H

// global includes

// library includes

// local includes
#include "modelcomponent.h"

namespace mexWBIComponent
{
  class ModelJacobian : public ModelComponent
  {
    public:
      static ModelJacobian *getInstance();

      /**
       * Delete the (static) instance of this component,
       * and set the instance pointer to 0.
       */
      static void deleteInstance();

      virtual bool allocateReturnSpace(int nlhs, mxArray **plhs);
      virtual bool compute(int, const mxArray**);
      virtual bool computeFast(int, const mxArray**);

      virtual ~ModelJacobian();

    private:
      ModelJacobian();
      bool processArguments(int, const mxArray**);

      static ModelJacobian *modelJacobian;

      static size_t nDof;
      static int    nCols;
      static double *J_rmo; // Jacobian in "row major order"

      // inputs:
      static double *qj;
      static char   *refLnk;
      // output:
      static double *wf_J_lnk; // Jacobian (from ref. link to world frame)
  };

}

#endif // MODELJACOBIAN_H
