#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "expected BlattNN as only argument"
    exit -1
fi

ilias_tool="../../ilias-linux"
no_pdf_feedback_file="../../no-pdf-feedback.pdf"

exercise_sheet_foldername="$1"

# these won't be available once the script exited
read -p "Enter your username: " user
read -p "Enter your password: " -s pass
export ILIAS_USER="$user"
export ILIAS_PASS="$pass"

# copies workspace.yml to korrektorkennung/BlattNN/
correctors=`grep ":" workspace.yml | grep "^ " | grep -vE "reference|assignment" | sed -E "s/ |://g"`
for corrector in $correctors; do
    echo fetching submission_ids for $corrector
    mkdir -p $corrector/$exercise_sheet_foldername
    cp check.py $corrector/$exercise_sheet_foldername/
    cp workspace.yml $corrector/$exercise_sheet_foldername/
    cp CORRECTION.tmpl $corrector/$exercise_sheet_foldername/
    cd $corrector/$exercise_sheet_foldername
    # and runs  workspace init <korrektorkennung>  for each corrector
    $ilias_tool workspace init $corrector
    rm CORRECTION.tmpl
    # we will need workspace.yml for the upload later on
    
    # for submission_ids which are no single pdf file, sets default feedback and correction status
    for submission_id in `find . -mindepth 1 -maxdepth 1 -type d`; do
        if [ ! -f "$submission_id/Abgabe.pdf" ]; then
            echo [i] $submission_id has no pdf
            sed -i "s/corrected: false/corrected: true/" $submission_id/Korrektur.yml
            echo "  Kein PDF abgegeben. Ihr Korrektor kann an dieser Korrektur nichts ändern." >> $submission_id/Korrektur.yml
            cp "$no_pdf_feedback_file" $submission_id/Korrektur.pdf
        fi
    done
    
    cd ../..
done

exit 0
