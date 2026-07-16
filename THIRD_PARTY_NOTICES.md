# Third-Party Notices

MatBox is licensed under the MIT License (see [LICENSE](LICENSE)), with the
exception of the portions listed below, which are adapted from third-party
code and remain subject to the original license terms reproduced here.

## mathworks/climatedatastore

The following files are adapted from build utilities and workflows in
[mathworks/climatedatastore](https://github.com/mathworks/climatedatastore),
Copyright (c) 2021-2022, The MathWorks, Inc.:

| MatBox file | Adapted from |
|---|---|
| `code/+matbox/+tasks/testToolbox.m` | `buildUtilities/testToolbox.m` |
| `code/+matbox/+tasks/codecheckToolbox.m` | `buildUtilities/codecheckToolbox.m` |
| `code/+matbox/+tasks/packageToolbox.m` | `buildUtilities/packageToolbox.m` |
| `code/+matbox/+tasks/createTestedWithBadgeforToolbox.m` | `buildUtilities/badgesforToolbox.m` |
| `code/+matbox/+utility/updateVersionNumber.m` | `buildUtilities/packageToolbox.m` |
| `code/+matbox/+utility/writeBadgeJSONFile.m` | `buildUtilities/writeBadgeJSONFile.m` |
| `.github/workflows/create_release.yml` | `.github/workflows/release.yml` |

These portions are distributed under the following license. Note that, per
condition 3, modifications and derivatives of this code are licensed solely
for use in conjunction with MathWorks products and service offerings; MatBox
is a MATLAB toolbox and is used exclusively with MATLAB.

```text
Copyright (c) 2021-2022, The MathWorks, Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. In all cases, the software is, and all modifications and derivatives of
   the software shall be, licensed to you solely for use in conjunction with
   MathWorks products and service offerings.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```
