#GIT_BRANCH = `git status | sed -n 1p`.split(" ").last
#GIT_BRANCH = `git branch`.split(" ").last

GIT_BRANCH = `type .git\HEAD`.split("\\").last
