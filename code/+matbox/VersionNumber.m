classdef VersionNumber < handle & matlab.mixin.CustomDisplay & matlab.mixin.CustomCompactDisplayProvider

    properties (Hidden)
        Major (1,1) uint8 = 0
        Minor (1,1) uint8 = 0
        Patch (1,1) uint8 = 0
        Build (1,1) uint8 = 0
    end

    properties (Hidden, AbortSet)
        Format (1,:) char = '%d.%d.%d' % Default format is Major.Minor.Patch
    end

    properties (SetAccess = private, Hidden)
        IsLatest (1,1) logical = false
    end

    methods
        % Constructor
        function obj = VersionNumber(versionSpecification, options)
            
            arguments (Repeating)
                versionSpecification
            end

            arguments
                options.Format
                options.IsLatest
            end

            if isempty(versionSpecification)
                return
            end
            if isscalar(versionSpecification) && iscell(versionSpecification{1})
                versionSpecification = versionSpecification{1};
            end
            
            if numel(versionSpecification) > 1
                obj(numel(versionSpecification)) = 1;
            end

            for i = numel(versionSpecification)
                iVersion = versionSpecification{i};

                if isstring(iVersion) || ischar(iVersion)
                    if strcmp(iVersion, "latest")
                        obj(i).IsLatest = true; %#ok<AGROW>
                        obj(i).setVersion(255);
                    else
                        obj(i).fromString(iVersion);
                    end

                elseif isnumeric(iVersion)
                    obj(i).setVersion(iVersion);
                end
            end

            if isfield(options, 'Format')
                [obj(:).Format] = options.Format;
            end

            if isfield(options, 'IsLatest')
                assert(isscalar(obj), 'Can not set latest for non-scalar VersionNumber instances')
                [obj.IsLatest] = options.IsLatest;
            end
        end
        
        % Set version
        function setVersion(obj, versionAsArray)

            for i = 1:numel(versionAsArray)
                if i == 1
                    obj.Major = versionAsArray(i);
                elseif i == 2
                    obj.Minor = versionAsArray(i);
                elseif i == 3
                    obj.Patch = versionAsArray(i);
                elseif i == 4
                    obj.Build = versionAsArray(i);
                end
            end
        end

                % Parse version from string
        function fromString(obj, versionStr)
            arguments
                obj (1,1) matbox.VersionNumber
                versionStr (1,1) string
            end

            if startsWith(versionStr, 'v')
                versionStr = string( versionStr{1}(2:end) );
            end

            parts = sscanf(versionStr, '%d.%d.%d.%d');

            assert( isequal(versionStr, strjoin(string(num2str(parts)), '.')), ...
                'Not a valid version specification %s', versionStr)
            
            if length(parts) >= 1
                obj.Major = parts(1);
            end

            if length(parts) >= 2
                obj.Minor = parts(2);
            end

            if length(parts) >= 3
                obj.Patch = parts(3);
            end
            if length(parts) == 4
                obj.Build = parts(4);
            end
        end
        
        % toString method for custom string format
        function str = string(obj)
            str = repmat("", size(obj));
            for i = 1:numel(obj)
                verNums = obj(i).getNumbersForFormat();
                str(i) = string( sprintf(obj(i).Format, verNums{:}) );
            end
        end

        function verNum = double(obj)
            verNum = [obj.Major, obj.Minor, obj.Patch, obj.Build];
        end

        % Comparison method to compare versions
        function result = isEqualTo(obj, other)
            result = (obj.Major == other.Major) && (obj.Minor == other.Minor) && (obj.Patch == other.Patch) && (obj.Build == other.Build);
        end
        
        % Bumping version methods
        function bumpMajor(obj)
            obj.Major = obj.Major + 1;
            obj.Minor = 0;
            obj.Patch = 0;
            obj.Build = 0;
        end
        
        function bumpMinor(obj)
            obj.Minor = obj.Minor + 1;
            obj.Patch = 0;
            obj.Build = 0;
        end
        
        function bumpPatch(obj)
            obj.Patch = obj.Patch + 1;
            obj.Build = 0;
        end
        
        function bumpBuild(obj)
            obj.Build = obj.Build + 1;
        end
    end

    methods
        
        % Greater than or equal (>=)
        function result = ge(obj, other)
            arguments
                obj (1,1) matbox.VersionNumber
                other (1,1) matbox.VersionNumber
            end

            result = (obj.Major > other.Major) || ...
                     (obj.Major == other.Major && obj.Minor > other.Minor) || ...
                     (obj.Major == other.Major && obj.Minor == other.Minor && obj.Patch > other.Patch) || ...
                     (obj.Major == other.Major && obj.Minor == other.Minor && obj.Patch == other.Patch && obj.Build >= other.Build);
        end
    
        % Greater than (>)
        function result = gt(obj, other)
            arguments
                obj (1,1) matbox.VersionNumber
                other (1,1) matbox.VersionNumber
            end
            result = (obj.Major > other.Major) || ...
                     (obj.Major == other.Major && obj.Minor > other.Minor) || ...
                     (obj.Major == other.Major && obj.Minor == other.Minor && obj.Patch > other.Patch) || ...
                     (obj.Major == other.Major && obj.Minor == other.Minor && obj.Patch == other.Patch && obj.Build > other.Build);
        end
    
        % Less than or equal (<=)
        function result = le(obj, other)
            arguments
                obj (1,1) matbox.VersionNumber
                other (1,1) matbox.VersionNumber
            end
            result = (obj.Major < other.Major) || ...
                     (obj.Major == other.Major && obj.Minor < other.Minor) || ...
                     (obj.Major == other.Major && obj.Minor == other.Minor && obj.Patch < other.Patch) || ...
                     (obj.Major == other.Major && obj.Minor == other.Minor && obj.Patch == other.Patch && obj.Build <= other.Build);
        end
    
        % Less than (<)
        function result = lt(obj, other)
            arguments
                obj (1,1) matbox.VersionNumber
                other (1,1) matbox.VersionNumber
            end

            result = (obj.Major < other.Major) || ...
                     (obj.Major == other.Major && obj.Minor < other.Minor) || ...
                     (obj.Major == other.Major && obj.Minor == other.Minor && obj.Patch < other.Patch) || ...
                     (obj.Major == other.Major && obj.Minor == other.Minor && obj.Patch == other.Patch && obj.Build < other.Build);
        end
    
        % Equal (==)
        function result = eq(obj, other)
            arguments
                obj (1,1) matbox.VersionNumber
                other (1,1) matbox.VersionNumber
            end

            if obj.IsLatest && other.IsLatest
                result = true; return
            end
            
            result = (obj.Major == other.Major) && ...
                     (obj.Minor == other.Minor) && ...
                     (obj.Patch == other.Patch) && ...
                     (obj.Build == other.Build);
        end
    
        % Not equal (~=)
        function result = ne(obj, other)
            arguments
                obj (1,1) matbox.VersionNumber
                other (1,1) matbox.VersionNumber
            end
            result = ~(obj == other);
        end
    end

    methods
        function set.Format(obj, newValue)
            obj.Format = newValue;
            obj.onFormatSet()
        end
    end

    methods (Access = protected)
        % Override CustomDisplay to control display behavior

        % function displayNonScalarObject(obj)
            % verAsStr = arrayfun(@(o) string(o), obj, 'UniformOutput', true);
            % disp(verAsStr);
        % end

        function displayScalarObject(obj)
            verNums = obj.getNumbersForFormat();
            fprintf(['   ', obj.Format, '\n'], verNums{:});
        end

        function displayEmptyObject(obj) %#ok<MANU>
            fprintf(['  0x0 empty Version array', '\n']);
        end

        function onFormatSet(obj) %#ok<MANU>
        end
    end

    methods (Access = private)
        function verNums = getNumbersForFormat(obj)
            assert(isscalar(obj), 'Function only accepts scalar object')
            switch obj.Format
                case '%d'
                    verNums = {obj.Major};
                case '%d.%d'
                    verNums = {obj.Major, obj.Minor};
                case '%d.%d.%d'
                    verNums = {obj.Major, obj.Minor, obj.Patch};
                case '%d.%d.%d.%d'
                    verNums = {obj.Major, obj.Minor, obj.Patch, obj.Build};
            end
        end
    end

    methods
        function rep = compactRepresentationForSingleLine(obj,displayConfiguration,~)
            % Fit as many array elements in the available space as possible
            rep = fullDataRepresentation(obj, displayConfiguration, 'StringArray', string(obj));
        end
        function rep = compactRepresentationForColumn(obj,displayConfiguration,~)
            % Fit as many array elements in the available space as possible
            rep = fullDataRepresentation(obj, displayConfiguration, 'StringArray', string(obj));
        end
    end

    methods (Static)
        function validateVersion(versionRef, validVersions)
            arguments
                versionRef (1,1) matbox.VersionNumber
            end

            arguments (Repeating)
                validVersions (1,1) matbox.VersionNumber
            end

            validVersions = [validVersions{:}];
        
            isValid = arrayfun(@(v) versionRef == v, validVersions);
            if ~any(isValid)
                [validVersions(:).Format] = deal( versionRef.Format );
                validVersionsAsString = compose('    %s', arrayfun(@(v) string(v), validVersions));
                validVersionsAsString = strjoin(validVersionsAsString, newline);
                errorMsg = sprintf("Version must be one of:\n%s", validVersionsAsString);
                error("MatBox:InvalidVersionNumber", errorMsg) %#ok<SPERR>
            end
        end
    end
end
