# Development

1. Clone `ilias` and `ilias-cli` to `~/go/src/github.com/krakowski/`
2. cd to `ilias-cli`
3. `GOOS=linux go get`
4. `GOOS=linux GOARCH=amd64 go build -o ilias-linux`

# Workflow

## Admin: Distribute Submissions

You should start with an empty directory for each exercise sheet because workspace.yml is overriden when fetching submissions for an exercise sheet.

1. Create a file `.tutors.yml`:
```
- id: hehei001
  hours: 10
- id: hehei002
  hours: 9
```
2. Create `CORRECTION.tmpl`:
```
student: {{.Student}}
points: [0,0,0,0]
corrected: false
correction: |

  <b>Rückfragen bitte unter Angabe der Korrekturnummer '{{.Student}}' und der Blattnummer an <a href="mailto:{{.Tutor}}@hhu.de?subject=RA-Abgabe {{.Student}} Blatt n">{{.Tutor}}@hhu.de</a></b>

  Maximal erreichbare Punkte: 10+5+5+5
```
3. In Ilias, deactivate displaying the profile picture in “Abgaben und Noten”, activate “Abgegeben am” (such that the first three columns are “Name”, “Benutzername”, “Abgegeben am”; otherwise you'll get `runtime error: index out of range [1] with length 1`).
4. Distribute submissions using the ref_id (not Object ID) of the Übungsobjekt and ass_id of the Übungseinheit:
```
./ilias-linux exercises distribute 1005951 22122
```
5. Run the download script:
```
# copies workspace.yml to korrektorkennung/BlattNN/ and runs  workspace init <korrektorkennung>  for each corrector; for submissions which are no single pdf file, sets default feedback and correction status
./download_submissions.bash BlattNN
```
6. Upload the generated folders to sciebo using webdav + merge with existing folders.

## Corrector Workflow

1. Download the folder for the current exercise sheet, including the file `workspace.yml`
2. For each student, create a `Korrektur.pdf` using Xournal++ and put it next to `Korrektur.yml`.
3. In `Korrektur.yml`, change the `points` array to reflect the points per exercise on the sheet, and set `corrected` to `true` when finished with all exercises.
4. When finished, run the sanity check script and fix any errors detected:
```
# checks existance of Korrekur.pdf, corrected=true, and maximum number per exercise
./check.py
```
5. zip the folder containing the `Korrektur.yml` and all subdirectories to a file called `korrektorkennung.zip`. In the end, you should have one zip file containing the folder `BlattNN`, which contains the subfolders for each student, `check.bash`, and `workspace.yml`.
6. Upload that zip file to the write-only sciebo shared folder for `BlattNN`.
7. In case you have to update the zip file because of an error, just re-upload it again.

## Admin: Upload Feedback for Students

1. Download all zip files from write-only share to a folder containing the workspace.yml from above.
2. Manually remove re-uploaded files (they have a numeric suffix).
3. Run upload script:
```
# extracts zip files, runs check.bash for every corrector first, then checks that we have not lost any submissions, then  workspace upload <korrektorkennung>  to upload the feedback files and points for each corrector
./upload_feedbacks.bash BlattNN
```
4. Get the total points per student and exercise sheet (and subexercise) so far:
```
./ilias-linux grades export 1005951
```
