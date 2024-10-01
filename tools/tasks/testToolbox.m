function testToolbox()
    installMatBox()
    projectRootDir = matboxtools.projectdir();
    matbox.tasks.testToolbox(projectRootDir)
end
