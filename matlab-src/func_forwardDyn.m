function [ qvDot, F_contact,tau_ctrl, comTraj ] = func_forwardDyn(t, qv, params )
%FORWARDDYNAMICS Forward dynamics of WBI ICub
%   This is the forward dynamics of the WBI Icub meant for integration in a
%   ode pkg function. 

constraintLink1 = 'l_sole';
constraintLink2 = 'r_sole';

n_dof = params.n_dof;
n_constraint = params.n_constraint; %number of constraints
% params.controller.current_time = t;
q = qv(1:7+n_dof,:);
p_base = q(1:3,:); % Linear Position of Floating Base
Q_base = q(4:7,:); % Orientation of Floating Base (quaternions)
qj = q(8:end,:); % Joint angles

v = qv(8+n_dof:63,:);
pDot_base = v(1:3,:); % Linear velocity of Floating Base
omega_base = v(4:6,:); % Rotational velocity of Floating base
qjDot = v(7:end,:);

% UPDATE states for wholeBodyModel
wholeBodyModel('update-state',qj,qjDot,[pDot_base;omega_base]);

M             = wholeBodyModel('mass-matrix');
Minv          = M\eye(n_dof+6,n_dof+6);
h             = wholeBodyModel('generalised-forces');  
g             = wholeBodyModel('generalised-forces',qj,zeros(25,1),zeros(6,1)); 
H             = wholeBodyModel('centroidal-momentum');
pos_rightFoot = wholeBodyModel('forward-kinematics',constraintLink2);
 pos_rightFoot = pos_rightFoot(1:3);

switch n_constraint
    case 1 % on left foot
        Jc    = reshape(wholeBodyModel('jacobian',constraintLink1),31,6)';
        JcDqD = wholeBodyModel('djdq',constraintLink1);
    case 2 % on both feet
        Jc    = [reshape(wholeBodyModel('jacobian',constraintLink1),31,6)';reshape(wholeBodyModel('jacobian',constraintLink2),31,6)'];
        JcDqD = [wholeBodyModel('djdq',constraintLink1);wholeBodyModel('djdq',constraintLink2)];
    otherwise
        disp('Choose number of constraints properly (1 or 2)');
        return
end     
                         
JcMinv = Jc*Minv;
JcMinvJct = JcMinv * transpose(Jc);                                   
pos_CoM =  wholeBodyModel('forward-kinematics','com');
pos_CoM = pos_CoM(1:3);
J_CoM = reshape(wholeBodyModel('jacobian','com'),31,6)';
J_CoMDqD = wholeBodyModel('djdq','com');
qjInit = params.qjInit;
IntErrorCoM = qv(64:end,:);

% params.controller.MassMatrix = wholeBodyModel('mass-matrix');
% params.controller.invMassMatrix = params.controller.MassMatrix\eye(n_dof+3*n_constraint,n_dof+3*n_constraint);
% params.controller.Coriolis = wholeBodyModel('generalised-forces');  
% params.controller.Gravitation = wholeBodyModel('generalised-forces',qj,zeros(25,1),zeros(6,1)); 
% params.controller.CentroidalMom = wholeBodyModel('centroidal-momentum');
% params.controller.fkin.rightfoot = wholeBodyModel('forward-kinematics',qj,constraintLink2);
% params.controller.jacobian.feet = [reshape(wholeBodyModel('jacobian',constraintLink1),31,6)';
%                                 reshape(wholeBodyModel('jacobian',constraintLink2),31,6)'];                            
% params.controller.JMinvconst = params.controller.jacobian.feet/params.controller.MassMatrix;
% params.controller.JMinvJt = params.controller.JMinvconst * transpose(params.controller.jacobian.feet);                            
% params.controller.jdqd.feet = [wholeBodyModel('djdq',constraintLink1);
%                             wholeBodyModel('djdq',constraintLink2)];
% params.controller.fkin.com = wholeBodyModel('forward-kinematics',qj,'com');
% params.controller.jacobian.com = reshape(wholeBodyModel('jacobian','com'),31,6)';
% params.controller.qjInit = params.qjInit;
% 
% IntErrorCoM = qv(64:end,:);

%% CONTROLLER

% [tau_ctrl,CoMError,xDDcomStar] = controller_BalancingTorque(qj,v,IntErrorCoM,params.controller);
% 
[tau_ctrl,CoMError,xDDcomStar] = controller_BalancingTorque(qj,...
                                                            v,...
                                                            M(1,1),...
                                                            h,...
                                                            g,...
                                                            H,...
                                                            Jc,...
                                                            JcMinv,...
                                                            JcMinvJct,...
                                                            JcDqD,...
                                                            J_CoM,...
                                                            pos_rightFoot,...
                                                            pos_CoM,...
                                                            IntErrorCoM,...
                                                            qjInit,...
                                                            params.Gains,...
                                                            params.Impedances,...
                                                            n_dof,...
                                                            n_constraint,...
                                                            t,...
                                                            params.controller);
                                                        
                                                    
                                                        
% %                                                         
% [tau_ctrl,CoMError,xDDcomStar] = controller_test_BalancingTorqueWithQP(qj,...
%                                                             v,...
%                                                             M(1,1),...
%                                                             h,...
%                                                             g,...
%                                                             H,...
%                                                             Jc,...
%                                                             JcMinv,...
%                                                             JcMinvJct,...
%                                                             JcDqD,...
%                                                             J_CoM,...
%                                                             pos_rightFoot,...
%                                                             pos_CoM,...
%                                                             IntErrorCoM,...
%                                                             qjInit,...
%                                                             params.Gains,...
%                                                             params.Impedances,...
%                                                             n_dof,...
%                                                             n_constraint,...
%                                                             t,...
%                                                             params.controller);                                                        
                                                        
%tau_ctrl = zeros(size(tau_ctrl));    
t_damp = [zeros(6,31);params.coef_damp*[zeros(25,6),eye(25,25)]]*[zeros(6,1);qjDot];
    
% F_contact = (params.controller.JMinvJt)\(params.controller.JMinvconst*(params.controller.Coriolis+t_damp-[zeros(6,1);tau_ctrl])-params.controller.jdqd.feet);
F_contact = (JcMinvJct)\(JcMinv*(h+t_damp-[zeros(6,1);tau_ctrl])-JcDqD);

QDot_base = quaternionDerivative(omega_base, Q_base);%,param.QuaternionDerivativeParam);

qDot = [pDot_base;QDot_base;qjDot];

% vDot = params.controller.invMassMatrix*(transpose(params.controller.jacobian.feet)*F_contact + [zeros(6,1);tau_ctrl]-params.controller.Coriolis - t_damp);
vDot = Minv*(transpose(Jc)*F_contact + [zeros(6,1);tau_ctrl]-h - t_damp);

qvDot = [qDot;vDot;CoMError]; %CoMError added to be integrated

% additional stuff to store
% djdqcom = wholeBodyModel('djdq','com');
% xddcom_sim = params.controller.jacobian.com*vDot(:,:) + djdqcom;
xddcom_sim = J_CoM*vDot(:,:) + J_CoMDqD;

ddCoMError = xddcom_sim(1:3) - xDDcomStar;

% constraint_check = params.controller.jacobian.feet*vDot + params.controller.jdqd.feet;
constraint_check = Jc*vDot + JcDqD;

comTraj = [CoMError;ddCoMError;constraint_check]';

end
