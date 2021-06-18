# Close GitHub Milestones Action

This action is dedicated to help managing [GitHub Milestones](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/about-milestones). It will check if there are any open issues or pull requests associated with the milestone, and if there are no open issues or pull requests left on the milestone, it will close the milestone.

## Example GitHub Action Workflow File

```
name: Close Milestone

on:
  pull_request:
    types: [closed]
  issues:
    types: [closed]

jobs:
  close-milestone:
    name: Close Milestone
    runs-on: ubuntu-latest
    steps:
    - name: Run Close Milestone Action
      id: run-close-milestone-action
      uses: synergy-au/Close-Milestone-Action@v1.1
      with:
        secrets-token: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

**secrets-token**\
The Secrets Github Token used for authenticating Github API calls.
- required: true

## Outputs

None
