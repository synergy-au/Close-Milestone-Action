#!/bin/bash

# Initialize variables
MILESTONE_DATA=''

# --------------------------------------------------------------------------------

function close_milestone_curl_cmd()
{
    # First argument should be set as the milestone ID number
    NUMBER=${1}

    # Need to authenticate to obtain write access for the REST API PATCH event
    CLOSED_MILESTONE=$( curl --silent -X PATCH -H "Authorization: token ${SECRETS_TOKEN}" "Accept: application/vnd.github.v3+json" https://api.github.com/repos/"${REPOSITORY}"/milestones/"${NUMBER}" -d '{ "state":"closed" }' )
}

function close_standalone_open_milestones()
{
    echo Closing standalone open milestones past their due date...

    CURRENT_DATETIME=$( echo $(date +'%Y-%m-%dT%H:%M:%SZ') )

    # Get all OPEN milestones with a due date older than the current date and time
    MILESTONE_DATA=$( curl --silent -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/"${REPOSITORY}"/milestones?state=open\&sort=due_on\&direction=asc )
    PAST_MILESTONES=$( echo "$MILESTONE_DATA" | jq --raw-output '.[] | select(.due_on <= '\"$CURRENT_DATETIME\"')' )

    if [[ $PAST_MILESTONES != '' ]];
    then
        MILESTONE_NUMBERS=$( echo "$PAST_MILESTONES" | jq --raw-output '.number' )

        for NUMBER in ${MILESTONE_NUMBERS};
        do
            close_milestone_curl_cmd $NUMBER

            echo Closed milestone number "$NUMBER"
        done
    else
        echo No standalone open milestones found
    fi

    # Reset MILESTONE_DATA to avoid referencing issues with the variable after this function is called
    MILESTONE_DATA=''
}

# --------------------------------------------------------------------------------

# Determine what the source is of the triggered event
if [[ ${EVENT_NAME} == "pull_request" ]];
then
    EVENT_TRIGGER_SOURCE='Pull Request'
elif [[ ${EVENT_NAME} == "issues" ]];
then
    EVENT_TRIGGER_SOURCE='Issue'
elif [[ ${EVENT_NAME} == "workflow_dispatch" ]];
then
    EVENT_TRIGGER_SOURCE='Manual'
else
    EVENT_TRIGGER_SOURCE='Unknown'
fi
echo Event Trigger Source: "$EVENT_TRIGGER_SOURCE"

# Display information from Github and initialize variables based on the source of the triggered event
echo Github Repository: "${REPOSITORY}"
if [[ $EVENT_TRIGGER_SOURCE == "Pull Request" ]];
then
    echo Pull Request Name: "${PULL_REQUEST_TITLE}"
    echo Pull Request Number: "${PULL_REQUEST_NUMBER}"

    PULL_REQUEST_MILESTONE_DATA="${PULL_REQUEST_MILESTONE}"
    PULL_REQUEST_MILESTONE_STATE=$( echo "${PULL_REQUEST_MILESTONE}" | jq --raw-output '.state' )

    # Check whether an OPEN milestone is linked to the pull request
    # If there is no milestone linked to the pull request then a value of "null" is returned from the API
    if [[ $PULL_REQUEST_MILESTONE != "null" && $PULL_REQUEST_MILESTONE_STATE == "open" ]];
    then
        echo An open milestone was successfully found
        MILESTONE_DATA=$PULL_REQUEST_MILESTONE_DATA
    else
        echo There is no open milestone linked to the pull request
    fi
elif [[ $EVENT_TRIGGER_SOURCE == "Issue" ]];
then
    echo Issue Name: "${ISSUE_TITLE}"
    echo Issue Number: "${ISSUE_NUMBER}"

    ISSUE_MILESTONE_DATA="${ISSUE_MILESTONE}"
    ISSUE_MILESTONE_STATE=$( echo "${ISSUE_MILESTONE}" | jq --raw-output '.state' )

    # Check whether an OPEN milestone is linked to the issue
    # If there is no milestone linked to the issue then a value of "null" is returned from the API
    if [[ $ISSUE_MILESTONE != "null" && $ISSUE_MILESTONE_STATE == "open" ]];
    then
        echo An open milestone was successfully found
        MILESTONE_DATA=$ISSUE_MILESTONE_DATA
    else
        echo There is no open milestone linked to the issue
    fi
fi

if [[ $MILESTONE_DATA != '' ]];
then
    # Retrieve only a specific set of data from the OPEN milestone linked to the issue
    OPEN_MILESTONE_DATA=$( echo "$MILESTONE_DATA" | jq --raw-output '{ title, number, open_issues, closed_issues, due_on }' )
    OPEN_ISSUES=$( echo "$OPEN_MILESTONE_DATA" | jq --raw-output '.open_issues' )

    # If there are no open issues then the milestone is elegible for closure
    if [[ $OPEN_ISSUES == 0 ]];
    then
        echo There are no open issues remaining on the milestone
        MILESTONE_DATA=$OPEN_MILESTONE_DATA
    else
        # Only for the purpose of making the message grammatically correct when read
        if [[ $OPEN_ISSUES == 1 ]];
        then
            OPEN_ISSUES_TEXT=$( echo open issue )
        else
            OPEN_ISSUES_TEXT=$( echo open issues )
        fi
        echo Milestone still has $OPEN_ISSUES $OPEN_ISSUES_TEXT linked to it and therefore cannot be closed yet

        # Reset MILESTONE_DATA variable given the milestone is not eligible for closure and therefore should not be processed any further
        MILESTONE_DATA=''
    fi
fi

if [[ $MILESTONE_DATA != '' ]];
then
    OPEN_MILESTONE=$( echo "$MILESTONE_DATA" )
    NUMBER=$( echo "$OPEN_MILESTONE" | jq --raw-output '.number' )
    TITLE=$( echo "$OPEN_MILESTONE" | jq --raw-output '.title' )
    CLOSED_ISSUES=$( echo "$OPEN_MILESTONE" | jq --raw-output '.closed_issues' )
    DUE_ON=$( echo "$OPEN_MILESTONE" | jq --raw-output '.due_on' )

    # Close the OPEN milestone as there are no open issues remaining
    close_milestone_curl_cmd $NUMBER

    # Display the details of the CLOSED milestone
    echo Milestone with the following details has been successfully closed:
    echo Title: "$TITLE"
    echo Number: "$NUMBER"
    echo Closed Issues: "$CLOSED_ISSUES"
    echo Due On: "$DUE_ON"
fi

if [[ $EVENT_TRIGGER_SOURCE == "Pull Request" || $EVENT_TRIGGER_SOURCE == "Issue" || $EVENT_TRIGGER_SOURCE == "Manual" ]];
then
    close_standalone_open_milestones
fi
