package workspace

import (
	"fmt"
	"github.com/krakowski/ilias"
	"github.com/krakowski/ilias-cli/util"
	"github.com/spf13/cobra"
	"log"
	"os"
	"path/filepath"
)

var (
	customMembers []string
)

var workspaceUploadCommand = &cobra.Command{
	Use:           "upload [corrector id]",
	Short:         "Uploads the current workspace (corrections of the given corrector) to the ILIAS platform",
	SilenceErrors: true,
	Args:          cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {

		workspace := util.ReadWorkspace()
		client := util.NewIliasClient()

		var members []string
		if customMembers != nil {
			members = customMembers
		} else {
			members = workspace.Corrections[args[0]]
		}

		corrections, err := util.ReadCorrections(members)
		if err != nil {
			fmt.Fprintln(os.Stderr, util.Red(err.Error()))
			os.Exit(1)
		}

		// Check if all submissions were corrected
		stats := util.GetCorrectionStats(corrections)
		if len(stats.Pending) > 0 {
			fmt.Fprintln(os.Stderr, util.Red("not all submissions are corrected yet"))
			os.Exit(1)
		}

		spin := util.StartSpinner(fmt.Sprintf("Uploading corrections (0/%d)", len(members)))

		// Upload comments
		for index, correction := range corrections {
			err := client.Exercise.UpdateComment(&ilias.CommentParams{
				Reference:  workspace.Exercise.Reference,
				Assignment: workspace.Exercise.Assignment,
			}, correction)

			if err != nil {
				log.Fatal(err)
			}

			err2 := client.Exercise.UpdateFileFeedback(&ilias.FileFeedbackParams{
				Reference:  workspace.Exercise.Reference,
				Assignment: workspace.Exercise.Assignment,
				StudentId:  correction.Student,
				Token:      client.User.Token,
			}, filepath.Join(correction.Student, FileCorrectionFilename))

			if err2 != nil {
				log.Fatal(err)
			}

			spin.UpdateMessage(fmt.Sprintf("Uploading corrections (%d/%d)", index+1, len(members)))
		}

		spin.StopSuccess(util.NoMessage)

		spin = util.StartSpinner("Updating grades")
		err = client.Exercise.UpdateGrades(&ilias.GradesUpdateQuery{
			Reference:  workspace.Exercise.Reference,
			Assignment: workspace.Exercise.Assignment,
			Token:      client.User.Token,
		}, corrections)

		if err != nil {
			spin.StopError(err)
			os.Exit(1)
		}

		spin.StopSuccess(fmt.Sprintf("Updated %d entries", len(corrections)))

		//spin = util.StartSpinner("Uploading table")
		//sheet := util.CreateCorrectionSheet(workspace.Table.Name, corrections)
		//err = client.Tables.Import(&ilias.ImportParams{
		//	Reference: workspace.Table.Reference,
		//	Table:     workspace.Table.Identifier,
		//	Token:     client.User.Token,
		//}, sheet)
		//
		//if err != nil {
		//	spin.StopError(err)
		//	os.Exit(1)
		//}
		//
		//spin.StopSuccess(fmt.Sprintf("Uploaded %d entries", len(corrections)))
	},
}

func init() {
	workspaceUploadCommand.Flags().StringSliceVar(&customMembers, "only", nil, "Uploads only the specified corrections")
}
