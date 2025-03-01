using System;
using System.Management.Automation;

using LibGit2Sharp;

namespace snowUtils.Cmdlets;

[Cmdlet(VerbsCommon.Clear, "Branches", SupportsShouldProcess = true, ConfirmImpact = ConfirmImpact.High)]
public class ClearBranches : Cmdlet
{
    [Parameter(Mandatory = true)]
    public string RepositoryPath { get; set; }

    [Parameter(Mandatory = false)]
    public string DevelopBranch { get; set; } = "develop";

    [Parameter(Mandatory = false)]
    public string Remote { get; set; } = "origin";

    protected override void ProcessRecord()
    {
        // Ensure the repository path exists and is valid
        if (!Repository.IsValid(RepositoryPath))
        {
            WriteError(new ErrorRecord(
                new ArgumentException("Invalid repository path."),
                "InvalidRepositoryPath",
                ErrorCategory.InvalidArgument,
                RepositoryPath));
            return;
        }

        using Repository repo = new(RepositoryPath);
        // Fetch latest updates
        Commands.Fetch(repo, Remote, Array.Empty<string>(), null, null);

        // Iterate over all branches
        foreach (Branch branch in repo.Branches)
        {
            // Skip if it's a remote branch or the current branch
            if (branch.IsRemote || branch.IsCurrentRepositoryHead)
            {
                continue;
            }

            // Check if the branch has no upstream
            if (branch.TrackedBranch != null)
            {
                continue;
            }

            WriteVerbose($"Branch '{branch.FriendlyName}' has no upstream.");

            // Search for merge commit in the develop branch log
            bool mergeCommitFound = false;
            Branch developBranch = repo.Branches[DevelopBranch];
            if (developBranch == null)
            {
                WriteWarning($"Develop branch '{DevelopBranch}' does not exist.");
                continue;
            }

            foreach (Commit commit in developBranch.Commits)
            {
                if (!commit.Message.Contains($"Merge branch '{branch.FriendlyName}' into '{DevelopBranch}'"))
                {
                    continue;
                }

                mergeCommitFound = true;
                WriteObject(
                    $"Merge commit found for branch '{branch.FriendlyName}' in '{DevelopBranch}': {commit.Sha}");
                break;
            }

            if (!mergeCommitFound)
            {
                WriteObject($"No merge commit found for branch '{branch.FriendlyName}' in '{DevelopBranch}'.");
            }

            // Use ShouldProcess for confirmation
            if (ShouldProcess(branch.FriendlyName, $"Delete branch '{branch.FriendlyName}'"))
            {
                try
                {
                    repo.Branches.Remove(branch.FriendlyName);
                    WriteObject($"Branch '{branch.FriendlyName}' deleted successfully.");
                }
                catch (Exception ex)
                {
                    WriteError(new ErrorRecord(
                        ex,
                        "BranchDeletionFailed",
                        ErrorCategory.OperationStopped,
                        branch.FriendlyName));
                }
            }
            else
            {
                WriteObject($"Skipping branch: {branch.FriendlyName}");
            }
        }
    }
}