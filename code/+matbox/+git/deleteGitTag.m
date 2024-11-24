function deleteGitTag(tagName, projectDirectory)

    arguments
        tagName (1,1) string 
        projectDirectory (1,1) string {mustBeFolder} = pwd
    end

    if ~strcmp(pwd, projectDirectory)
        currentWorkingDir = pwd;
        cleanupObj = onCleanup(@(fn) cd(currentWorkingDir));
        cd(projectDirectory)
    end

    %[s,m] = system( '$(git rev-parse --abbrev-ref HEAD) == "main"' )

    [s1, m1] = system(sprintf("git tag --delete %s", tagName));
    assert(s1==0, 'MATBOX:GitUtility:DeleteTagFailed', ...
        'Failed to delete local tag. Reason: %s', m1);

    [s2, m2] = system(sprintf("git push --delete origin %s", tagName));
    assert(s2==0, 'MATBOX:GitUtility:DeleteTagFailed', ...
        'Failed to delete remote tag. Reason: %s', m2);
end
