
%
%  Class Object :: Analyse Scalar Data Types
% *******************************************
%  SubClass of QPICType
%
%  Description:
%    A class to analyse and handle QuickPIC data related to charge density and potential.
%
%  Constructor:
%    oData   : QPICData object
%    sScalar : What scalar variable to load
%    Parameter pairs:
%      Units     : 'N', 'SI' or 'CGS'
%      X1Scale   : Unit scale on x1 axis. 'Auto', or specify metric unit
%      X2Scale   : Unit scale on x2 axis. 'Auto', or specify metric unit
%      X3Scale   : Unit scale on x3 axis. 'Auto', or specify metric unit
%      Scale     : Unit scale on all axes. 'Auto', or specify metric unit
%      Symmetric : Makes the X and Y axes symmetric around 0
%
%  Set Methods:
%    Time      : Set time dump for dataset. Default is 0.
%    X1Lim     : 2D array of limits for x1 axis. Default is full box.
%    X2Lim     : 2D array of limits for x2 axis. Default is full box.
%    X3Lim     : 2D array of limits for x3 axis. Default is full box.
%    SliceAxis : 2D slice axis for 3D data
%    Slice     : 2D slice coordinate for 3D data
%
%  Public Methods:
%    Density2D : Returns a dataset with a 2D matrix of the density.
%    Lineout   : Returns a dataset with a 1D lineout of the density.
%

classdef QPICScalar < QPICType

    %
    % Properties
    %

    properties(GetAccess='public', SetAccess='private')
        
        ScalarVar   = '';  % Holds scalar name
        ScalarIndex = 0;   % Holds scalar number (for plasma species)
        ScalarType  = '';  % Holds scalar type
        ScalarFac   = 1.0; % Scalar scale factor
        ScalarUnit  = 'N'; % Scalar base unit
        ScalarName  = '';  % Full name of the scalar type
        ScalarShort = '';  % Short name of the scalar type
        ScalarTex   = '';  % TeX name of the scalar type
        
    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = QPICScalar(oData, sScalar, varargin)
            
            % Call QPICType constructor
            obj@QPICType(oData, varargin{:});
            
            % Set Field
            sScalar = lower(sScalar);
            if numel(sScalar) > 3
                obj.ScalarIndex = str2num(sScalar(3:end));
                sCheck = sScalar(1:2);
            else
                sCheck = sScalar;
            end % if
            
            cValid = {'psi','eb','ep'};
            if sum(ismember(sCheck, cValid)) == 1
                obj.ScalarVar  = sScalar;
                obj.ScalarType = sScalar(1);
            else
                fprintf(2, 'Error: ''%s'' is not a recognised scalar field. Using ''eb'' instead.\n', sScalar);
                obj.ScalarVar  = 'eb';
                obj.ScalarType = 'e';
            end % if
            
            if strcmpi(obj.Units,'SI')
                switch obj.ScalarType
                    case 'e'
                        switch(obj.SIOptions.QDensity)
                            case 0
                                obj.ScalarFac  = 1.0;
                                obj.ScalarUnit = 'N_0';
                            case 1
                                obj.ScalarFac  = obj.Data.Config.Convert.SI.ChargeFac;
                                obj.ScalarUnit = 'C/m^3';
                            case 2
                                obj.ScalarFac  = obj.Data.Config.Convert.SI.ChargeFac*1e9;
                                obj.ScalarUnit = 'C/mm^3';
                            case 3
                                obj.ScalarFac  = obj.Data.Config.Convert.SI.ChargeFac*1e18;
                                obj.ScalarUnit = 'C/µm^3';
                        end % switch
                        if sScalar(2) == 'b'
                            obj.Diagnostics = obj.Data.Config.Diag.Beam;
                        else
                            obj.Diagnostics = obj.Data.Config.Diag.Plasma;
                        end % if
                    case 'p'
                        obj.ScalarFac   = obj.Data.Config.Convert.SI.PotFac;
                        obj.ScalarUnit  = 'V';
                        obj.Diagnostics = obj.Data.Config.Diag.Potential;
                end % switch
            end % if
            
            % Names
            switch obj.ScalarType
                case 'e'
                    if sScalar(2) == 'b'
                        obj.ScalarName  = 'Beam Charge Density';
                        obj.ScalarShort = 'QB';
                        obj.ScalarTex   = 'Q_{b}';
                    else
                        obj.ScalarName  = 'Plasma Charge Density';
                        obj.ScalarShort = sprintf('QP%d',obj.ScalarIndex);
                        obj.ScalarTex   = sprintf('Q_{p%d}',obj.ScalarIndex);
                    end % if
                case 'p'
                    obj.ScalarName  = 'Potential';
                    obj.ScalarShort = 'PSI';
                    obj.ScalarTex   = '\Psi';
            end % switch

        end % function
        
    end % methods

    %
    % Public Methods
    %
    
    methods(Access = 'public')
        
        function stReturn = Density2D(obj, sSlice)

            % Input/Output
            stReturn = {};
            
            if nargin < 2
                sSlice = '';
            end % if

            % Get Data and Parse it
            switch obj.ScalarType
                case 'e'
                    aData = obj.Data.Data(obj.Time,'Q','',obj.ScalarVar,sSlice);
                case 'p'
                    aData = obj.Data.Data(obj.Time,'PSI','','',sSlice);
            end % switch
            if isempty(aData)
                fprintf(2,'QPICScalar.Density2D: No data\n');
                return;
            end % if
            
            % Slice and crop
            stData = obj.fParseGridData2D(aData);
            aData  = stData.Data;
            aHAxis = stData.HAxis;
            aVAxis = stData.VAxis;
            cAxes  = stData.Axes;
            
            % Return Data
            stReturn.Data  = aData*obj.ScalarFac;
            stReturn.HAxis = aHAxis;
            stReturn.VAxis = aVAxis;
            stReturn.Axes  = {QPICTools.fLabelAxis(cAxes{1}) QPICTools.fLabelAxis(cAxes{2})};
            stReturn.ZPos  = obj.fGetZPos();        
        
        end % function

        function stReturn = Lineout(obj, sSlice, sAxis, aStart, aAverage)

            % Input/Output
            stReturn = {};
            
            if nargin < 5
                aAverage = 1;
            end % if
            
            if nargin < 4
                aStart = 1;
            end % if

            if nargin < 3
                sAxis = 'Z';
            end % if

            if nargin < 2
                sSlice = '';
            end % if
            
            [sAxis,iAxis] = QPICTools.fTranslateAxis(sAxis);
            
            % Get Data and Parse it
            switch obj.ScalarType
                case 'e'
                    aData = obj.Data.Data(obj.Time,'Q','',obj.ScalarVar,sSlice);
                case 'p'
                    aData = obj.Data.Data(obj.Time,'PSI','','',sSlice);
            end % switch
            if isempty(aData)
                fprintf(2,'QPICScalar.Lineout: No data\n');
                return;
            end % if

            stData = obj.fParseGridData1D(aData,sSlice,iAxis,aStart,aAverage);
            if isempty(stData)
                return;
            end % if

            % Return Data
            stReturn.Data   = stData.Data*obj.ScalarFac;
            stReturn.HAxis  = stData.HAxis;
            stReturn.HRange = stData.HLim;
            stReturn.Axis   = sAxis;
            stReturn.ZPos   = obj.fGetZPos();        
        
        end % function
        
        function stReturn = Wakefield2D(obj, sSlice)
            
            % Input/Output
            stReturn = {};
                        
        end % function

        function stReturn = WFLineout(obj, sSlice, iStart, iAverage)

            % Input/Output
            stReturn = {};
          
        end % function
        
        
    end % methods

end % classdef
