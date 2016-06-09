classdef wbmBaseRobotModel
    properties
       ndof@uint16         scalar = 0;
       urdf_robot@char
       urdf_link_name@char
       wf_R_rootLnk@double matrix = eye(3,3);
       wf_p_rootLnk@double vector = zeros(3,1);
       g_wf@double         vector = zeros(3,1);
       joint_ll@double     vector
       joint_ul@double     vector
       vfrict_coeff@double vector
       cfrict_coeff@double vector
    end
end
