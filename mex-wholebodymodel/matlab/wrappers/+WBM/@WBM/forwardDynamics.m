function [dstvChi, C_qv] = forwardDynamics(obj, t, stvChi, fhCtrlTrqs)
    ndof   = obj.mwbm_model.ndof;
    nCstrs = obj.mwbm_config.nCstrs;

    % get the state parameters from the current state vector "stvChi" ...
    stp = WBM.utilities.fastGetStateParams(stvChi, obj.mwbm_config.stvLen, ndof);

    omega_w = stp.omega_b;
    v_b = vertcat(stp.dx_b, omega_w);
    %v = [stp.dx_b; omega_w; stp.dq_j];

    % update the state for the optimized mode (precautionary) ...
    obj.setState(stp.q_j, stp.dq_j, v_b);

    % reconstruct the rotation of the 'root link' to the 'world'
    % from the quaternion part of the transformation vector vqT_b:
    vqT_b = obj.stvqT;
    [~,R_b] = WBM.utilities.frame2posRotm(vqT_b);

    M    = obj.massMatrix();
    C_qv = obj.generalizedBiasForces();

    % compute for each contact constraint the Jacobian and the corresponding
    % derivative Jacobian:
    m = 6*nCstrs;
    n = 6 + ndof;
    Jc = zeros(m,n);
    dJcdq = zeros(m,1);
    for i = 1:nCstrs
        Jc(6*i-5:6*i,1:n)  = obj.jacobian(obj.mwbm_config.cstr_link_names{i}); % 6*(i-1)+1 = 6*i-5
        dJcdq(6*i-5:6*i,1) = obj.dJdq(obj.mwbm_config.cstr_link_names{i});
    end

    % get the current control torque vector ...
    tau = fhCtrlTrqs(t);

    % compute the contact force vector:
    Jc_t      =  Jc.';
    JcMinv    =  Jc / M; % x*M = Jc --> x = Jc*M^(-1)
    JcMinvJct =  JcMinv * Jc_t;
    tau_fr    =  obj.frictionForces(stp.dq_j); % damped torques
    tau_gen   =  vertcat(zeros(6,1), tau + tau_fr); % generalized force tau_gen = tau - tau_fr
    % calculate the contact (constraint) forces ...
    f_c = JcMinvJct \ (JcMinv*(C_qv - tau_gen) - dJcdq); % JcMinvJct*x = (...) --> x = JcMinvJct^(-1)*(...)

    % need to apply root-to-world rotation to the spatial angular velocity omega_w to
    % obtain angular velocity in body frame omega_b. This is then used in the
    % quaternion derivative computation:
    omega_b = R_b * omega_w;
    dqt_b   = WBM.utilities.dQuat(stp.qt_b, omega_b);

    dx = vertcat(stp.dx_b, dqt_b, stp.dq_j);
    dv = M \ (Jc_t*f_c + tau_gen - C_qv);
    %dv = M \ (Jc.'*f_c + tau_gen - C_qv); % cause Jc.'*f_c round-off errors?

    dstvChi = vertcat(dx, dv);
    %kinEnergy = 0.5*v.'*M*v;
end
