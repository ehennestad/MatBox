# MATLAB Style Guide

## General Principles
- **Readability:** Prioritize clarity over brevity.
- **Consistency:** Maintain consistent coding styles throughout projects.
- **Simplicity:** Write simple and maintainable code.

## Formatting
- Use spaces (not tabs). Set indent to 4 spaces.
- Limit line length to approximately 100 characters.
- Include spaces around operators and after commas.

```matlab
y = sin(x) + cos(x); % Good
y=sin(x)+cos(x);     % Avoid
```

## Naming Conventions
- Functions: `camelCase` starting with a lowercase verb (e.g., `computeResult`).
- Variables: `camelCase` descriptive nouns (e.g., `sessionDuration`).
- Classes and properties: `PascalCase` nouns (e.g., `DataProcessor`).
- Constants: UPPER_CASE with underscores (e.g., `MAX_ITER`).

## File Organization
- Each function in its own file named exactly after the function.
- Organize related functions and classes into namespaces (`+namespace`).

## Function Definitions
Use `arguments` block for input validation:

```matlab
function result = computeStats(data, options)
    arguments
        data double {mustBeNonempty}
        options.method (1,:) char {mustBeMember(options.method, {'mean','median'})} = 'mean'
        options.verbose (1,1) logical = false
    end

    if options.verbose
        disp('Calculating statistics...');
    end

    switch options.method
        case 'mean'
            result = mean(data);
        case 'median'
            result = median(data);
    end
end
```

## Strings
- Use double quotes (`" "`) for string arrays and avoid char arrays where possible:

```matlab
str = "Hello, World!"; % Good
str = 'Hello, World!'; % Avoid (unless explicitly needed)
```

## Comments and Documentation
- Use `%` for inline comments and detailed function help:

```matlab
function output = exampleFunction(input)
%EXAMPLEFUNCTION Summary of the function.
%   Detailed explanation goes here.

output = input + 1; % simple operation
end
```

- Provide function signatures using standard MATLAB doc format.

## Error Handling
- Use `error` and `warning` with clear, actionable messages and custom identifiers.

```matlab
if size(A,1) ~= size(B,1)
    error("MyToolbox:MyFcn:RowsNotSameLength", ...
        "Matrices A and B must have the same number of rows.");
end
```

## Unit Testing
- Write unit tests using MATLAB's built-in testing framework (`matlab.unittest`):

```matlab
classdef testComputeStats < matlab.unittest.TestCase
    methods (Test)
        function testMeanMethod(testCase)
            data = [1,2,3,4];
            result = computeStats(data, struct('method','mean'));
            testCase.verifyEqual(result, 2.5);
        end
    end
end
```

## Performance
- Preallocate arrays to improve performance.
- Prefer vectorization over loops.

```matlab
result = zeros(1,100);
for i = 1:100
    result(i) = i^2;
end

% Better (vectorized):
i = 1:100;
result = i.^2;
```

## Code Analysis Tools
- Use the MATLAB Code Analyzer and fix all errors and warnings.
