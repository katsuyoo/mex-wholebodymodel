/*
 * Copyright (C) 2014 Robotics, Brain and Cognitive Sciences - Istituto Italiano di Tecnologia
 * Authors: Naveen Kuppuswamy
 * email: naveen.kuppuswamy@iit.it
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

#include "modeljointlimits.h"

// #include <yarpWholeBodyInterface/yarpWholeBodyModel.h>
// #include <stdio.h>
// #include <mex.h>

using namespace mexWBIComponent;

ModelJointLimits *ModelJointLimits::modelJointLimits = 0;

ModelJointLimits::ModelJointLimits() : ModelComponent(0, 0, 2)
{
#ifdef DEBUG
  mexPrintf("ModelJointLimits constructed\n");
#endif
}

bool ModelJointLimits::allocateReturnSpace(int nlhs, mxArray *plhs[])
{
#ifdef DEBUG
  mexPrintf("Trying to allocateReturnSpace in ModelJointLimits\n");
#endif
  if(nlhs != 2)
    mexErrMsgIdAndTxt("MATLAB:mexatexit:invalidNumInputs", "2 output arguments required for joint limits");

  int numDof = modelState->dof();

  plhs[0] = mxCreateDoubleMatrix(numDof, 1, mxREAL);
  plhs[1] = mxCreateDoubleMatrix(numDof, 1, mxREAL);

  jointLowerLimit = mxGetPr(plhs[0]);
  jointUpperLimit = mxGetPr(plhs[1]);

  return true;
}

ModelJointLimits::~ModelJointLimits()
{
#ifdef DEBUG
  mexPrintf("ModelJointLimits destructed\n");
#endif
}

ModelJointLimits *ModelJointLimits::getInstance()
{
  if(modelJointLimits == NULL)
    modelJointLimits = new ModelJointLimits;

  return modelJointLimits;
}

void ModelJointLimits::deleteInstance()
{
  deleteObject(&modelJointLimits);
}

bool ModelJointLimits::compute(int nrhs, const mxArray *prhs[])
{
#ifdef DEBUG
  mexPrintf("Trying to compute ModelJointLimits\n");
#endif
  robotModel = modelState->robotModel();
  robotModel->getJointLimits(jointLowerLimit, jointUpperLimit);

  return true;
}

bool ModelJointLimits::computeFast(int, const mxArray *[])
{
  robotModel = modelState->robotModel();
  robotModel->getJointLimits(jointLowerLimit, jointUpperLimit);

  return true;
}
