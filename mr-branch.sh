#!/bin/bash

#figure out current branch name
branchName=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
#try to figure out  ticket name
ticketName=$(echo $branchName | cut -d '/' -f 2)
#find the commit where we created the branch
baseCommit=$(git merge-base origin/main head)

#only allow running this from feature branches
case $branchName in
feature*) ;;

*)
    # If it doesn't, print an error message
    echo "This script can only be run when you're on a feature branch"
    exit 1
    ;;
esac

# Check if it matches one of the strings
case $1 in
qa | uat | release)
    # If it does, print a message
    # echo "Valid argument: $1"
    ;;
*)
    # If it doesn't, print an error message
    echo "Invalid argument: $1"
    echo "Valid arguments are qa, uat, release"
    exit 1
    ;;
esac

#figure out the name of the branch to make
if [ "$1" = "qa" ] || [ "$1" = "uat" ]; then
    branchToMake="$1merge/$ticketName"
    resetFrom="origin/$1"
elif [ "$1" = "release" ]; then
    branchToMake="release/$ticketName"
    resetFrom="origin/main"
else
    echo "Invalid argument: $1"
    exit 1
fi

# Check if the branch exists
if git show-ref --verify --quiet "refs/heads/$branchToMake"; then
    echo "Branch exists. Right now this can only run where you're making a new branch"
    exit 1
else
    echo going to make $branchToMake
fi

#make the new branch
git checkout -b $branchToMake

#reset to remote
git reset --hard $resetFrom

#only add commits to non-release branch
if [ "$1" = "release" ]; then
    echo nothing to do
else    
    #add commits
    git cherry-pick $baseCommit..$branchName
fi

# Print the prompt message
read -n 1 -r -p "Do you want to push to remote? [y/n] " response

# Check the response and perform the corresponding action
case $response in
y)
    #push to remote
    git push --set-upstream origin $branchToMake

    ;;
n)
    #do nothing
    ;;
*)
    # If the response is not "y" or "n", print an error message and exit the script
    echo
    echo "Invalid response: $response"
    exit 1
    ;;
esac

#checkout where we started
git checkout $branchName
