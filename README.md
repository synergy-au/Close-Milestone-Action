# Close Milestone Action

Github Action to automatically close milestones linked to pull requests.
This should be triggered upon pull request closure and closes the milestone when there are no open issues remaining on it.

## Example Github Action Workflow File

```
name: Close Milestone

on:
  pull_request:
    types: [closed]

jobs:
  close-milestone:
    name: Close Milestone
    runs-on: ubuntu-latest
    steps:
    - name: Run Close Milestone Action
      id: run-close-milestone-action
      uses: synergy-au/Close-Milestone-Action@v1.0
      with:
        secrets-token: ${{ secrets.GITHUB_TOKEN }}
```
