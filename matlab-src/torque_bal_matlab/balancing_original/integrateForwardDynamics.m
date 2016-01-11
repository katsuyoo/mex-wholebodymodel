%% integrateForwardDynamics
% This is the main program for integrating the forward dynamics of the
% robot iCub in matlab
clear all
close all
clc

%% Setup path
% Set the path properly depending on where are the required folders in your computer
addpath('./../../../mex-wholebodymodel/matlab/utilities');
addpath('./../../../mex-wholebodymodel/matlab/wrappers');
addpath('./../../../../../build/');
addpath('./../../');

%% Initialise the mexWholeBodyModel
wbm_modelInitialise('icubGazeboSim');

%% Setup params for balancing controller
params.demo_left_and_right      =  1;                                      %either 0 or 1; only for two feet on the ground
params.QP_solver                =  0;                                      %either 0 or 1
 
% balancing on two feet or one foot
params.feet_on_ground           =  [1,1];                                      %either 1 or 2

% allows the visualization of torques, forces and other user-defined graphics 
vis_graphics                    =  1;                                      %either 0 or 1
 
%% Setup general params
% this is assuming a 25DoF iCub
params.ndof         = 25;

% initial conditions                  
params.leftArmInit  = [ -19.7   29.7  0.0  44.9   0.0]';          
params.rightArmInit = [ -19.7   29.7  0.0  44.9   0.0]';         
 
if     params.feet_on_ground == 2
     
% initial conditions for balancing on two feet 
 params.torsoInit    = [ -10.0   0.0   0.0]'; 
 params.leftLegInit  = [  25.5   0.1   0.0  -18.5  -5.5  -0.1]';
 params.rightLegInit = [  25.5   0.1   0.0  -18.5  -5.5  -0.1]';

elseif params.feet_on_ground == 1
     
% initial conditions for the robot standing on one foot
 params.torsoInit    = [ -10.0   0.0    0.0]';
 params.leftLegInit  = [  25.5   15.0   0.0  -18.5  -5.5  -0.1]';
 params.rightLegInit = [  25.5   5.0    0.0  -40    -5.5  -0.1]'; 

end
 
params.qjInit  = [params.torsoInit;params.leftArmInit;params.rightArmInit;params.leftLegInit;params.rightLegInit] * (pi/180);
params.dqjInit = zeros(params.ndof,1);
   
params.dx_bInit    = zeros(3,1);
params.omega_bInit = zeros(3,1);
  
%% Fixing the world reference frame to the ground, not to the left foot 
wbm_updateState(params.qjInit,params.dqjInit,[params.dx_bInit;params.omega_bInit]);

% fixing the world reference frame w.r.t. the left foot position
[rot,pos] = wbm_getWorldFrameFromFixedLink('l_sole',params.qjInit);

wbm_setWorldFrame(rot,pos,[0 0 -9.81]')

[~,T_b,~,~] = wbm_getState();
 
params.chiInit = [T_b;params.qjInit;...
                  params.dx_bInit;params.omega_bInit;params.dqjInit];

%% Contact constraints definition         
if     params.feet_on_ground(1) == 1 && params.feet_on_ground(2) == 1
     
 params.constraintLinkNames      = {'l_sole','r_sole'}; 

elseif   params.feet_on_ground(1) == 1 && params.feet_on_ground(2) == 0
     
 params.constraintLinkNames      = {'l_sole'}; 
 
elseif   params.feet_on_ground(1) == 0 && params.feet_on_ground(2) == 1
    
 params.constraintLinkNames      = {'r_sole'};

end

 params.numConstraints           = length(params.constraintLinkNames);
   
%% Others parameters for balancing controller
 load('jointLimits.mat')
 
 limits           = [jl1 jl2];
 params.limits    = limits;
 params.com_ini   = wbm_forwardKinematics('com');
 
 params.lfoot_ini = wbm_forwardKinematics('l_sole');
 params.rfoot_ini = wbm_forwardKinematics('r_sole');
 
%% Setup integration
 params.tStart   = 0;
 params.tEnd     = 10;   
 params.sim_step = 0.01;
 
 params.wait     = waitbar(0,'Integration in process...');

 forwardDynFunc  = @(t,chi)forwardDynamics(t,chi,params);
    
%% Integrate forward dynamics
 disp('starting numerical integration');
 options = odeset('RelTol',1e-5,'AbsTol',1e-5);
   
 [t,chi] = ode15s(forwardDynFunc,params.tStart:params.sim_step:params.tEnd,params.chiInit,options);

 disp('numerical integration complete..rendering.');

%% Visualize forward dynamics
% demo of the dynamics
 visualizer_demo(t,chi,params);

% desired graphics 
if vis_graphics == 1
 
 disp('preparing the graphics...')
 visualizer_graphics(t,chi,params);

end
   