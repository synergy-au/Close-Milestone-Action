#!/bin/bash

# Initialize Shell Variables
MILESTONE_DATA=''
PROCESSED_MILESTONE_DATA=''

# Display Github Information
echo Github Repository: "${REPOSITORY}"
echo Pull Request Name: "${PULL_REQUEST_TITLE}"
echo Pull Request Number: "${PULL_REQUEST_NUMBER}"

# Check whether an OPEN milestone is linked to the pull request
# If there is no milestone linked to the pull request then a value of "null" is returned from the API
PULL_REQUEST_MILESTONE_DATA="${PULL_REQUEST_MILESTONE}"
PULL_REQUEST_MILESTONE_STATE=$( echo "${PULL_REQUEST_MILESTONE}" | jq --raw-output .state )
if [[ $PULL_REQUEST_MILESTONE != "null" && $PULL_REQUEST_MILESTONE_STATE == "open" ]];
then
    echo An open milestone was successfully found
    MILESTONE_DATA=$PULL_REQUEST_MILESTONE_DATA
else
    echo There is no open milestone linked to the pull request
fi

if [[ $MILESTONE_DATA != '' ]];
then
    # Retrieve only a specific set of data from the OPEN milestone linked to the pull request
    OPEN_MILESTONE_DATA=$( echo "$MILESTONE_DATA" | jq --raw-output '{ title, number, open_issues, closed_issues, due_on }' )
    OPEN_ISSUES=$( echo "$OPEN_MILESTONE_DATA" | jq --raw-output .open_issues )

    # If there are no open issues then the milestone is elegible for closure
    if [[ $OPEN_ISSUES == 0 ]];
    then
        echo There are no open issues remaining on the milestone
        PROCESSED_MILESTONE_DATA=$OPEN_MILESTONE_DATA
    else
        # Only for the purpose of making the message grammatically correct when read
        if [[ $OPEN_ISSUES == 1 ]];
        then
            OPEN_ISSUES_TEXT=$( echo open issue )
        else
            OPEN_ISSUES_TEXT=$( echo open issues )
        fi
        echo Milestone still has $OPEN_ISSUES $OPEN_ISSUES_TEXT linked to it and therefore cannot be closed yet
    fi
fi

if [[ $PROCESSED_MILESTONE_DATA != '' ]];
then
    # Close the OPEN milestone if there are no open issues remaining
    OPEN_MILESTONE=$( echo "$PROCESSED_MILESTONE_DATA" )
    NUMBER=$( echo "$OPEN_MILESTONE" | jq --raw-output '.number' )
    TITLE=$( echo "$OPEN_MILESTONE" | jq --raw-output '.title' )
    CLOSED_ISSUES=$( echo "$OPEN_MILESTONE" | jq --raw-output '.closed_issues' )
    DUE_ON=$( echo "$OPEN_MILESTONE" | jq --raw-output '.due_on' )

    # Need to authenticate to obtain write access for the REST API PATCH event
    CLOSED_MILESTONE=$( curl --silent -X PATCH -H "Authorization: token ${SECRETS_TOKEN}" "Accept: application/vnd.github.v3+json" https://api.github.com/repos/"${REPOSITORY}"/milestones/"$NUMBER" -d '{ "state":"closed" }' )

    # Display the details of the CLOSED milestone
    echo Milestone with the following details has been successfully closed:
    echo Title: "$TITLE"
    echo Number: "$NUMBER"
    echo Closed Issues: "$CLOSED_ISSUES"
    echo Due On: "$DUE_ON"
fi
