#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "expected BlattNN as only argument"
    exit -1
fi

ilias_tool="../../ilias-linux"

exercise_sheet_foldername="$1"

for zipfile in `ls *zip`; do
    unzip $zipfile -d `basename $zipfile .zip` > /dev/null
done

# runs check.bash for every corrector first
correctors=`grep ":" workspace.yml | grep "^ " | grep -vE "reference|assignment" | sed -E "s/ |://g"`
for corrector in $correctors; do
    echo check corrections for $corrector
    cp check.py $corrector/$exercise_sheet_foldername/
    cd $corrector/$exercise_sheet_foldername

    chmod +x check.py
    ./check.py
    
    cd ../..
done


# check that we have not lost any submissions (count the IDs from the workspace and the number of Korrektur.pdf files)
echo `grep "-" workspace.yml | wc -l` submissions
echo `find . -mindepth 3 -maxdepth 3 -type d | wc -l` corrections

# then  workspace upload <korrektorkennung>  to upload the feedback files and points for each corrector

# these won't be available once the script exited
echo "If everything is okay, we want to upload the feedback files for the students"
read -p "Enter your username: " user
read -p "Enter your password: " -s pass
export ILIAS_USER="$user"
export ILIAS_PASS="$pass"

for corrector in $correctors; do
    echo upload feedback files from $corrector
    cd $corrector/$exercise_sheet_foldername

    $ilias_tool workspace upload $corrector
    
    cd ../..
done

exit 0
