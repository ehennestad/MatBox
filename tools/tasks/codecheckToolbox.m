function codecheckToolbox(varargin)
    installMatBox()
    projectRootDir = matboxtools.projectdir();
    matbox.tasks.codecheckToolbox(projectRootDir, varargin{:})
end
