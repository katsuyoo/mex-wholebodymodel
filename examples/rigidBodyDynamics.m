%% In this example we will show how use the mex-wholeBodyModel to compute
%% the dynamics quantitites of a rigid body

%% cleanup the session 
clear
close all;

%% initialise mexWholeBodyModel using the rigidBody.urdf file.
%% Check the rigidBody.urdf for comments on how the inertial 
%% parameters are encoded in the URDF file 
wbm_modelInitialiseFromURDF('rigidBody.urdf');

%% the number of (internal) dofs is 0 for a rigid body 
%% we set the state to some random values, just to show how to 
%% get the dynamics quantities
w_R_b = eye(3,3); % rotation matrix that transforms a vector in the base frame to the world frame
x_b = [1;2;3]; % position of the link frame origin wrt to the world frame
qj = zeros(0,1);  % joint positions
dqj = zeros(0,1); % joint velocities 
grav = [0;0;-9.8]; % gravity in world frame
dx_b = [0.4;0.5;0.6]; % derivative in the position of the link frame origin wrt to the world frame
omega_W = [0.4;0.5;0.2]; % angular velocity of base frame 

%% Set the state
wbm_setWorldFrame(w_R_b,x_b,grav);
wbm_updateState(qj,dqj,[dx_b;omega_W]);

% We compute the mass matrix:
M = wbm_massMatrix();

% and the generalized bias forces (coriolis + gravity forces)
h = wbm_generalisedBiasForces();

% We can check them by printing them:
M
h