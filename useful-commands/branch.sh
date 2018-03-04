#!/bin/bash
upstreamBranch=upstream
masterBranch=master
if [ "$2" == "delete" ]; then
git checkout $masterBranch
git branch -D $1
git push origin :$1
echo "Done."
elif [ "$2" == "edit" ]; then
git checkout $1
read -p "Finish your work again."
git add $1.json
git commit -m "$(cat .git/COMMIT_EDITMSG)" --amend
git push -u origin $1 -f
git checkout $masterBranch
echo "Done."
else
git reset --hard
git checkout $upstreamBranch
git branch $1
git checkout $1
touch $1.json
read -p "Finish your work now."
git add $1.json
if [ "$2" ]; then
git commit -m "Add $1 & Closes #$2"
else
git commit -m "Add $1"
fi
git push -u origin $1
git checkout $masterBranch
hub pull-request -b RikkaW:master -h $1 -m "Add $1 & Closes #$2"
echo "Done."
fi
