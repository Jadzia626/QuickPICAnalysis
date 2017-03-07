
%
%  Class Object :: SuperClass for QPICAnalysis Data Types
% ********************************************************
%

classdef QPICType

    %
    % Properties
    %
    
    properties(GetAccess='public', SetAccess='public')
        
        Time        = 0;                         % Current time (dumb number)
        X1Lim       = [];                        % Axes limits x1
        X2Lim       = [];                        % Axes limits x2
        X3Lim       = [];                        % Axes limits x3
        SliceAxis   = 3;                         % Slice axis (3D)
        Slice       = 0;                         % Slice coordinate (3D)
        Error       = false;                     % True if object failed to initialise

    end % properties

    properties(GetAccess='public', SetAccess='private')
        
        Data        = {};                        % QPICData dataset
        Config      = {};                        % Holds relevant QPICConfig data
        Units       = 'N';                       % Units of axes
        AxisUnits   = {'N' 'N' 'N'};             % Units of axes
        AxisScale   = {'Auto' 'Auto' 'Auto'};    % Scale of axes
        AxisRange   = [0.0 0.0 0.0 0.0 0.0 0.0]; % Max and min of axes
        AxisFac     = [1.0 1.0 1.0];             % Axes scale factors
        ParticleFac = 1.0;                       % Q-to-particles factor
        ChargeFac   = 1.0;                       % Q-to-charge factor
        BoxOffset   = 0.0;                       % Start of the box in simulation

    end % properties
    
    properties(GetAccess='protected', SetAccess='protected')
        
        Translate   = {};                        % Lookup class for variables
        
    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = QPICType(oData, varargin)
            
            % Set Data
            obj.Data = oData;

            % Read config
            dLFactor = obj.Data.Config.Convert.SI.LengthFac;
            aXMin    = obj.Data.Config.Simulation.XMin/dLFactor;
            aXMax    = obj.Data.Config.Simulation.XMax/dLFactor;

            % Set Variables
            %obj.Translate   = Variables(sCoords);
            
            % Read Input Parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Units',   'N');
            addParameter(oOpt, 'Scale',   '');
            addParameter(oOpt, 'X1Scale', 'Auto');
            addParameter(oOpt, 'X2Scale', 'Auto');
            addParameter(oOpt, 'X3Scale', 'Auto');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            % Set Scale
            if isempty(stOpt.Scale)
                obj.AxisScale = {stOpt.X1Scale, stOpt.X2Scale, stOpt.X3Scale};
            else
                obj.AxisScale = {stOpt.Scale, stOpt.Scale, stOpt.Scale};
            end % if

            % Evaluate Units
            switch(lower(stOpt.Units))

                case 'si'
                    obj.Units = 'SI';
                    
                    [dX1Fac, sX1Unit]  = obj.fLengthScale(obj.AxisScale{1}, 'm');
                    [dX2Fac, sX2Unit]  = obj.fLengthScale(obj.AxisScale{2}, 'm');
                    [dX3Fac, sX3Unit]  = obj.fLengthScale(obj.AxisScale{3}, 'm');
                    obj.AxisFac        = [dX1Fac dX2Fac dX3Fac]*dLFactor;
                    obj.AxisUnits      = {sX1Unit, sX2Unit, sX3Unit};
                    obj.AxisRange(1:2) = [aXMin(1) aXMax(1)]*obj.AxisFac(1);
                    obj.AxisRange(3:4) = [aXMin(2) aXMax(2)]*obj.AxisFac(2);
                    obj.AxisRange(5:6) = [aXMin(3) aXMax(3)]*obj.AxisFac(3);
                    
                    obj.ParticleFac    = obj.Data.Config.Convert.SI.ParticleFac;
                    obj.ChargeFac      = obj.Data.Config.Convert.SI.ChargeFac;

                case 'cgs'
                    obj.Units = 'CGS';
                    
                    [dX1Fac, sX1Unit]  = obj.fLengthScale(obj.AxisScale{1}, 'cm');
                    [dX2Fac, sX2Unit]  = obj.fLengthScale(obj.AxisScale{2}, 'cm');
                    [dX3Fac, sX3Unit]  = obj.fLengthScale(obj.AxisScale{3}, 'cm');
                    obj.AxisFac        = [dX1Fac dX2Fac dX3Fac]*dLFactor;
                    obj.AxisUnits      = {sX1Unit, sX2Unit, sX3Unit};
                    obj.AxisRange(1:2) = [aXMin(1) aXMax(1)]*obj.AxisFac(1);
                    obj.AxisRange(3:4) = [aXMin(2) aXMax(2)]*obj.AxisFac(2);
                    obj.AxisRange(5:6) = [aXMin(3) aXMax(3)]*obj.AxisFac(3);
                    
                    obj.ParticleFac    = obj.Data.Config.Convert.CGS.ParticleFac;
                    obj.ChargeFac      = obj.Data.Config.Convert.CGS.ChargeFac;

                otherwise
                    obj.Units = 'N';

                    obj.AxisFac = [1.0, 1.0, 1.0];
                    if obj.Cylindrical
                        obj.AxisUnits = {'c/\omega_p', 'c_/\omega_p', 'rad'};
                    else
                        obj.AxisUnits = {'c/\omega_p', 'c_/\omega_p', 'c/\omega_p'};
                    end % if
                    obj.AxisRange   = [aXMin(1) aXMax(1) aXMin(2) aXMax(2) aXMin(3) aXMax(3)];

                    obj.ParticleFac = obj.Data.Config.Convert.Norm.ParticleFac;
                    obj.ChargeFac   = obj.Data.Config.Convert.Norm.ChargeFac;

            end % switch

            % Set defult axis limits
            obj.X1Lim = [aXMin(1) aXMax(1)]*obj.AxisFac(1);
            obj.X2Lim = [ aXMin(2) aXMax(2)]*obj.AxisFac(2);
            obj.X3Lim = [aXMin(3) aXMax(3)]*obj.AxisFac(3);
            
            % Set default slice for 3D
            obj.SliceAxis = 3;
            obj.Slice     = 0.0;

        end % function

    end % methods

    %
    % Setters and Getters
    %

    methods
        
        function obj = set.Time(obj, iTime)
            
            obj.Time = iTime;
            
        end % function
        
        function obj = set.X1Lim(obj, aX1Lim)

            dX1Min = obj.Data.Config.Simulation.XMin(1);
            dX1Max = obj.Data.Config.Simulation.XMax(1);

            if length(aX1Lim) ~= 2
                fprintf(2, 'Error: x1 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX1Lim(2) < aX1Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if

            if aX1Lim(1)/obj.AxisFac(1) < dX1Min || aX1Lim(1)/obj.AxisFac(1) > dX1Max ...
            || aX1Lim(2)/obj.AxisFac(1) < dX1Min || aX1Lim(2)/obj.AxisFac(1) > dX1Max
                fprintf('Warning: X1Lim input is out of range. Range is %.2f–%.2f %s.\n', dX1Min*obj.AxisFac(1), dX1Max*obj.AxisFac(1), obj.AxisUnits{1});
                aX1Lim(1) = dX1Min*obj.AxisFac(1);
            end % if

            obj.X1Lim = aX1Lim/obj.AxisFac(1);

        end % function
         
        function obj = set.X2Lim(obj, aX2Lim)
 
            dX2Min = obj.Data.Config.Simulation.XMin(2);
            dX2Max = obj.Data.Config.Simulation.XMax(2);

            if length(aX2Lim) ~= 2
                fprintf(2, 'Error: x2 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX2Lim(2) < aX2Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if
            
            if aX2Lim(1)/obj.AxisFac(2) < dX2Min || aX2Lim(1)/obj.AxisFac(2) > dX2Max ...
            || aX2Lim(2)/obj.AxisFac(2) < dX2Min || aX2Lim(2)/obj.AxisFac(2) > dX2Max
                fprintf('Warning: X2Lim input is out of range. Range is %.2f–%.2f %s.\n', ...
                        dX2Min*obj.AxisFac(2), dX2Max*obj.AxisFac(2), obj.AxisUnits{2});
                aX2Lim = [dX2Min*obj.AxisFac(2) dX2Max*obj.AxisFac(2)];
            end % if

            obj.X2Lim = aX2Lim/obj.AxisFac(2);
             
        end % function
 
        function obj = set.X3Lim(obj, aX3Lim)

            dX3Min = obj.Data.Config.Simulation.XMin(3);
            dX3Max = obj.Data.Config.Simulation.XMax(3);

            if length(aX3Lim) ~= 2
                fprintf(2, 'Error: x3 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX3Lim(2) < aX3Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if

            if aX3Lim(1)/obj.AxisFac(3) < dX3Min || aX3Lim(1)/obj.AxisFac(3) > dX3Max ...
            || aX3Lim(2)/obj.AxisFac(3) < dX3Min || aX3Lim(2)/obj.AxisFac(3) > dX3Max
                fprintf('Warning: X3Lim input is out of range. Range is %.2f–%.2f %s.\n', ...
                        dX3Min*obj.AxisFac(3), dX3Max*obj.AxisFac(3), obj.AxisUnits{3});
                aX3Lim = [dX3Min*obj.AxisFac(3) dX3Max*obj.AxisFac(3)];
            end % if

            obj.X3Lim = aX3Lim/obj.AxisFac(3);

        end % function
        
        function obj = set.SliceAxis(obj, iAxis)
            
            if isempty(iAxis)
                return;
            end % if
            
            iAxis = floor(iAxis);
            
            if iAxis > 0 && iAxis <= 3
                obj.SliceAxis = iAxis;
            else
                fprintf(2, 'Error: Not a proper axis.\n');
            end % if
            
            obj.Slice = 0.0;
            
        end % function

        function obj = set.Slice(obj, dSlice)
            
            if isempty(dSlice)
                return;
            end % if

            aAxis     = obj.fGetBoxAxis(sprintf('x%d',obj.SliceAxis));
            obj.Slice = fGetIndex(aAxis,dSlice);
            
        end % function

    end % methods

    %
    % Public Methods
    %
    
    methods(Access='public')

        function sReturn = PlasmaPosition(obj)

            sReturn = 'Unknown Position';

            dTFac    = obj.Data.Config.Convert.SI.TimeFac;
            dLFac    = obj.Data.Config.Convert.SI.LengthFac;
            
            dSimPos  = obj.Time*dTFac;
            dDeltaT  = dTFac*dLFac;
            dTMag    = round(log10(dDeltaT));
            
            dScale = 1.0;
            sUnit  = 'm';
            if dTMag < -1
                dScale = 1.0e2;
                sUnit  = 'cm';
            end % if
            if dTMag < -2
                dScale = 1.0e3;
                sUnit  = 'mm';
            end % if

            sReturn = sprintf('at %0.2f %s in Plasma',dSimPos*dLFac*dScale,sUnit);

        end % function

    end % methods

    %
    % Private Methods
    %
    
    methods(Access='private')
        
        function [dScale, sUnit] = fLengthScale(~, sToUnit, sFromUnit)

            dScale = 1.0;
            sUnit  = 'm';

            if nargin < 2
                sFromUnit = 'm';
            end % if

            switch(lower(sFromUnit))
                case 'pm'
                    dScale = dScale * 1.0e-12;
                case 'å'
                    dScale = dScale * 1.0e-10;
                case 'nm'
                    dScale = dScale * 1.0e-9;
                case 'um'
                    dScale = dScale * 1.0e-6;
                case 'µm'
                    dScale = dScale * 1.0e-6;
                case 'mm'
                    dScale = dScale * 1.0e-3;
                case 'cm'
                    dScale = dScale * 1.0e-2;
                case 'm'
                    dScale = dScale * 1.0;
                case 'km'
                    dScale = dScale * 1.0e3;
            end % switch

            switch(lower(sToUnit))
                case 'pm'
                    dScale = dScale * 1.0e12;
                    sUnit  = 'pm';
                case 'å'
                    dScale = dScale * 1.0e10;
                    sUnit  = 'Å';
                case 'nm'
                    dScale = dScale * 1.0e9;
                    sUnit  = 'nm';
                case 'um'
                    dScale = dScale * 1.0e6;
                    sUnit  = 'µm';
                case 'µm'
                    dScale = dScale * 1.0e6;
                    sUnit  = 'µm';
                case 'mm'
                    dScale = dScale * 1.0e3;
                    sUnit  = 'mm';
                case 'cm'
                    dScale = dScale * 1.0e2;
                    sUnit  = 'cm';
                case 'm'
                    dScale = dScale * 1.0;
                    sUnit  = 'm';
                case 'km'
                    dScale = dScale * 1.0e-3;
                    sUnit  = 'km';
            end % switch

        end % function

    end % methods

    %
    % Protected Methods
    %
    
    methods(Access='protected')
        
        function stReturn = fParseGridData1D(obj, aData, iStart, iAverage)

            % Input/Output
            stReturn = {};
            
            iDim       = ndims(aData);
            iSliceAxis = obj.SliceAxis;
            
            switch iSliceAxis
                case 1
                    sHAxis = 'x2';
                    sVAxis = 'x3';
                    aHAxis = obj.fGetBoxAxis('x2');
                    aVAxis = obj.fGetBoxAxis('x3');
                    aHLim  = [obj.X2Lim(1)*obj.AxisFac(2), obj.X2Lim(2)*obj.AxisFac(2)];
                    aVLim  = [obj.X3Lim(1)*obj.AxisFac(3), obj.X3Lim(2)*obj.AxisFac(3)];
                case 2
                    sHAxis = 'x1';
                    sVAxis = 'x3';
                    aHAxis = obj.fGetBoxAxis('x1');
                    aVAxis = obj.fGetBoxAxis('x3');
                    aHLim  = [obj.X1Lim(1)*obj.AxisFac(1), obj.X1Lim(2)*obj.AxisFac(1)];
                    aVLim  = [obj.X3Lim(1)*obj.AxisFac(3), obj.X3Lim(2)*obj.AxisFac(3)];
                case 3
                    sHAxis = 'x1';
                    sVAxis = 'x2';
                    aHAxis = obj.fGetBoxAxis('x1');
                    aVAxis = obj.fGetBoxAxis('x2');
                    aHLim  = [obj.X1Lim(1)*obj.AxisFac(1), obj.X1Lim(2)*obj.AxisFac(1)];
                    aVLim  = [obj.X2Lim(1)*obj.AxisFac(2), obj.X2Lim(2)*obj.AxisFac(2)];
            end % switch

            if iDim == 3
                switch iSliceAxis
                    case 1
                        aData  = squeeze(aData(obj.Slice,:,:));
                    case 2
                        aData  = squeeze(aData(:,obj.Slice,:));
                    case 3
                        aData  = squeeze(aData(:,:,obj.Slice));
                end % switch
            end % if
            
            % Get H-Limits
            iHMin  = fGetIndex(aHAxis, aHLim(1));
            iHMax  = fGetIndex(aHAxis, aHLim(2));
            
            % Get V-Limits
            iVN    = numel(aVAxis);

            % Crop Dataset
            iEnd   = iStart+iAverage-1;
            aData  = squeeze(mean(aData(iHMin:iHMax,iStart:iEnd),2));
            aHAxis = aHAxis(iHMin:iHMax);
            
            % Return Data
            stReturn.Data  = aData;
            stReturn.HAxis = aHAxis;
            stReturn.HLim  = [iHMin iHMax];
            stReturn.VLim  = [aVAxis(iStart) aVAxis(iEnd+1)];
            stReturn.Axes  = {sHAxis,sVAxis};

        end % function
        
        function stReturn = fParseGridData2D(obj, aData)
            
            % Input/Output
            stReturn = {};
            
            iDim       = ndims(aData);
            iSliceAxis = obj.SliceAxis;

            if iDim == 2
                return;
            end % if

            switch iSliceAxis
                case 1
                    sHAxis = 'x2';
                    sVAxis = 'x3';
                    aHAxis = obj.fGetBoxAxis('x2');
                    aVAxis = obj.fGetBoxAxis('x3');
                    aHLim  = [obj.X2Lim(1)*obj.AxisFac(2), obj.X2Lim(2)*obj.AxisFac(2)];
                    aVLim  = [obj.X3Lim(1)*obj.AxisFac(3), obj.X3Lim(2)*obj.AxisFac(3)];
                case 2
                    sHAxis = 'x1';
                    sVAxis = 'x3';
                    aHAxis = obj.fGetBoxAxis('x1');
                    aVAxis = obj.fGetBoxAxis('x3');
                    aHLim  = [obj.X1Lim(1)*obj.AxisFac(1), obj.X1Lim(2)*obj.AxisFac(1)];
                    aVLim  = [obj.X3Lim(1)*obj.AxisFac(3), obj.X3Lim(2)*obj.AxisFac(3)];
                case 3
                    sHAxis = 'x1';
                    sVAxis = 'x2';
                    aHAxis = obj.fGetBoxAxis('x1');
                    aVAxis = obj.fGetBoxAxis('x2');
                    aHLim  = [obj.X1Lim(1)*obj.AxisFac(1), obj.X1Lim(2)*obj.AxisFac(1)];
                    aVLim  = [obj.X2Lim(1)*obj.AxisFac(2), obj.X2Lim(2)*obj.AxisFac(2)];
            end % switch

            if iDim == 3
                switch iSliceAxis
                    case 1
                        aData  = squeeze(aData(obj.Slice,:,:));
                    case 2
                        aData  = squeeze(aData(:,obj.Slice,:));
                    case 3
                        aData  = squeeze(aData(:,:,obj.Slice));
                end % switch
            end % if

            % Check if cylindrical
            aData = transpose(aData);
            
            % Get Limits
            iHMin = fGetIndex(aHAxis, aHLim(1));
            iHMax = fGetIndex(aHAxis, aHLim(2));
            iVMin = fGetIndex(aVAxis, aVLim(1));
            iVMax = fGetIndex(aVAxis, aVLim(2));

            % Crop Dataset
            aData  = aData(iVMin:iVMax,iHMin:iHMax);
            aHAxis = aHAxis(iHMin:iHMax);
            aVAxis = aVAxis(iVMin:iVMax);
            
            % Return Data
            stReturn.Data  = aData;
            stReturn.HAxis = aHAxis;
            stReturn.VAxis = aVAxis;
            stReturn.HLim  = [iHMin iHMax];
            stReturn.VLim  = [iVMin iVMax];
            stReturn.Axes  = {sHAxis,sVAxis};

        end % function
        
        function aReturn = fGetTimeAxis(obj)
            
            iDumps  = obj.Data.SimData.MaxFiles;
            
            dTFac   = obj.Data.Config.Convert.SI.TimeFac;
            dLFac   = obj.Data.Config.Convert.SI.LengthFac;
            
            aReturn = linspace(0.0, dTFac*iDumps, iDumps)*dLFac;
            
        end % function

        function aReturn = fGetBoxAxis(obj, sAxis)
            
            switch sAxis
                case 'x1'
                    dXMin = obj.Data.Config.Simulation.XMin(1);
                    dXMax = obj.Data.Config.Simulation.XMax(1);
                    iNX   = obj.Data.Config.Simulation.Grid(1);
                    dLFac = obj.AxisFac(1);
                case 'x2'
                    dXMin = obj.Data.Config.Simulation.XMin(2);
                    dXMax = obj.Data.Config.Simulation.XMax(2);
                    iNX   = obj.Data.Config.Simulation.Grid(2);
                    dLFac = obj.AxisFac(2);
                case 'x3'
                    dXMin = obj.Data.Config.Simulation.XMin(3);
                    dXMax = obj.Data.Config.Simulation.XMax(3);
                    iNX   = obj.Data.Config.Simulation.Grid(3);
                    dLFac = obj.AxisFac(3);
                otherwise
                    dXMin = 0.0;
                    dXMax = 0.0;
                    iNX   = 0;
                    dLFac = 0;
            end % switch

            aReturn = linspace(dXMin, dXMax, iNX)*dLFac;
            
        end % function
        
        function dReturn = fGetZPos(obj)
            
            dLFactor = obj.Data.Config.Convert.SI.LengthFac;
            dTFactor = obj.Data.Config.Convert.SI.TimeFac;
            dReturn  = obj.Time*dTFactor*dLFactor;
            
        end % function
        
        function dReturn = fGetXPos(obj,sAxis,iIndex)
            
            aAxis   = obj.fGetBoxAxis(sAxis);
            dReturn = aAxis(iIndex);
            
        end % function
        
        function bReturn = fError(obj)
            
            bReturn = false;
            
            if obj.Error
                
                fprintf(2, 'OsirisType object not initialised properly.\n');
                bReturn = true;
                
            end % if
            
        end % function

        function aReturn = fMomentumToEnergy(obj, aMomentum, dMass)
            
            dEMass  = obj.Data.Config.Constants.EV.ElectronMass;
            aReturn = sqrt(aMomentum.^2 + 1)*dMass*dEMass;
            
        end % function
        
        function aReturn = fPruneRaw(obj, aRaw, iVar, dMin, dMax)
            
            % By default do nothing.
            aReturn = aRaw;
            
            if iVar < 1 || iVar > 8 || isempty(dMin) && isempty(dMax)
                return;
            end % if
            
            if ~isempty(dMin)
                aInd = aReturn(:,iVar) < dMin;
                aReturn(aInd,:) = [];
            end % if

            if ~isempty(dMax)
                aInd = aReturn(:,iVar) > dMax;
                aReturn(aInd,:) = [];
            end % if
            
        end % function
        
        function aRaw = fRawToXi(obj, aRaw)

            dOffset = obj.Data.Config.Simulation.TimeStep*obj.Data.Config.Simulation.NDump*obj.Time;
            aRaw(:,1) = aRaw(:,1) - dOffset;
            
        end % function

    end % methods
    
end % classdef
