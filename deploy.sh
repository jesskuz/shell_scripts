#!/bin/bash
# This is simply sample code with absolutely no guarantee(s) of functionality.  Use at your own risk.

SCRIPTNAME=${0##*/} 
FULL_DIR=${PWD}
CODEBASE_DIR=${PWD##*/}
ROOT_DIR='/var/www'
DRY_RUN=1
MODE='stage'
COMMITS='HEAD^'
REMOTE_PROJECT_DIR=$CODEBASE_DIR

#-------------------------------
STAGE_HOST='staging.neptune'
PROD_HOST='production.neptune'

#-------------------------------
DEPLOY_HOST=$STAGE_HOST
SSH_ACCOUNT='ssh_deploy_acct'

#-------------------------------
SHORTOPTS="w:pr:d"
#LONGOPTS="remote-dir:,prod,revisions:,deploy"

#-------------------------------
while getopts $SHORTOPTS opt; do
     case $opt in
          w)
               REMOTE_PROJECT_DIR=$OPTARG;
               ;;
          p)
               MODE='prod'
               ;;
          r)
               if [[ $OPTARG =~ ^[a-z0-9]+\:[a-z0-9]+$ ]]
               then
                    COMMITS=$OPTARG
                    COMMITS=${COMMITS/:/" "}
               else
                    COMMITS="$OPTARG HEAD"
               fi
               ;;
          d)
               DRY_RUN=0
               ;;
          -) 
               printf "Please specify some parameters.\n\n";
               exit 1;
               break;;

          *)
               break;;
     esac
done

shift $((OPTIND - 1));

#-------------------------------
if [[ "$MODE" = 'prod' ]]
then
     echo 'Deploying MASTER branch to PROD ...'
     $(git checkout master > /dev/null 2>&1)
     DEPLOY_HOST=$PROD_HOST
else
     echo 'Deploying DEV branch to STAGE ...'
     $(git checkout dev > /dev/null 2>&1)
     DEPLOY_HOST=$STAGE_HOST
fi

printf "\n"

#-------------------------------
if [[ "$DRY_RUN" = 0 ]]
then
     echo "Performing full deploy ..."
     SWITCH='vuza'
else
     echo "Performing dry run ..."
     SWITCH='vuzan'
fi


DESTINATION="${SSH_ACCOUNT}@${DEPLOY_HOST}:${ROOT_DIR}/${REMOTE_PROJECT_DIR}/"


# ---- Get DIFF between COMMITS -------
DIFF="git diff --diff-filter=d --name-only ${COMMITS}"

if `$DIFF > /dev/null 2>&1`;
then
     # ---- Sync new files -----
     split_commits=($COMMITS)
     printf "\n"
     
     printf "Deploy the following DIFF:  ${split_commits[0]} TO ${split_commits[1]} ...\n\n"

     printf "`${DIFF}`\n\n"

     printf "Execute ${MODE^^} sync for the following manifest ...\n\n"

     read -p "[ Go ahead with it?  " -n 3 -r
     printf "\n"

     shopt -s nocasematch;
     if [[ $REPLY =~ ^yes$ ]]
     then
          printf "`${DIFF} | rsync -${SWITCH} --files-from=- ${FULL_DIR} ${DESTINATION}`\n\n"
     else
          printf "Quit.\n\n"
          exit 0
     fi


     printf "Complete.\n\n"

else
     echo "Failed due to unreachable commits or your commits are on another 
branch."
     exit 1
fi;



exit 0;
