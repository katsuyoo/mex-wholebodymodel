classdef wbmBaseRobotConfig
    properties
       ndof@int16
       nCstrs@int16
       cstrLinkNames = {};
       dampCoeff@double
       initStateParams@wbmStateParams
       stvSize@int16
    end
end