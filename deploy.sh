#!/bin/bash
# +------------------------------------
# | Exit codes
# +--------------------------
#	0 - Successful.
#	1 - General failure.
#	2 - File is missing.
#	3 - Property not defined.

# +------------------------------------
# | Set up basic settings and file references.
# +--------------------------
## Assemble the environment variables.
NAME=$1
ENVIRONMENT="$NAME.properties"
ENVIRONMENT_EXCLUDE="$NAME.exclude"

## Rsync options. The --delete-excluded flag will remove files that are
## excluded in the source from the remote destination.
DEFAULT_RSYNC_OPTIONS="-av --delete-excluded"

# Check that the user has supplied an environment name.
if [ -z $1 ]; then
	echo "You have to supply a deployment environment name."
	exit 1
fi

# Check that the environment specific property file exists.
if [ -a $ENVIRONMENT ]; then
	# Check that the environment specific exclude file exists.
	if [ ! -e $ENVIRONMENT_EXCLUDE ]; then
		echo
		echo "Exclude file ($ENVIRONMENT_EXCLUDE) for environment '$NAME' is missing."
		exit 1
	fi

	echo
	echo "Initialize deployment to '$NAME' environment."

	echo "Loading '$ENVIRONMENT'."
	source $ENVIRONMENT

	# Check that the deployment source have been defined
	# within the environment specific properties.
	if [ -z $DEPLOYMENT_SOURCE ]; then
		echo
		echo "'DEPLOYMENT_SOURCE' for deployment environment '$NAME' have not been defined."
		exit 3
	fi

	# Check that the deployment target have been defined
	# within the environment specific properties.
	if [ -z $DEPLOYMENT_FOLDER ]; then
		DEPLOYMENT_FOLDER=""
	else
		DEPLOYMENT_FOLDER="$DEPLOYMENT_FOLDER/"
	fi

	# Check that the deployment host have been defined
	# within the environment specific properties.
	if [ -z $DEPLOYMENT_HOST ]; then
		echo
		echo "'DEPLOYMENT_HOST' for deployment environment '$NAME' have not been defined."
		exit 3
	fi

	# Check that the deployment user have been defined
	# within the environment specific properties.
	if [ -z $DEPLOYMENT_USER ]; then
		echo
		echo "'DEPLOYMENT_USER' for deployment environment '$NAME' have not been defined."
		exit 3
	fi

	# ----------------------------------------
	# Password should not be defined within the properties.
	# Partially because it would be a security issue, and the use
	# of SSH public keys is a far better solution.
	#
	# If the user do not have an accepted public key on the deployment
	# server, the password field will be prompted.
	# -----------------------------

	# Check if the additional rsync options have been defined within
	# environment properties. Use an empty string if it's not set.
	if [ -z $DEPLOYMENT_RSYNC_OPTIONS ]; then
		DEPLOYMENT_RSYNC_OPTIONS=""
	fi
	# Assemble the rsync option flags.
	RSYNC_OPTIONS="$DEFAULT_RSYNC_OPTIONS $DEPLOYMENT_RSYNC_OPTIONS"

	# Get the absolute path for the deployment source and assemble
	# the full destination, with user, host, and target folder.
	SOURCE="$(readlink -f $DEPLOYMENT_SOURCE)/"
	DESTINATION="$DEPLOYMENT_USER@$DEPLOYMENT_HOST:$DEPLOYMENT_FOLDER"

	echo
	echo "Deploying source: $SOURCE"
	echo "To destination: $DESTINATION"
	echo

	# Run the pre setup script.
	if [ -n "$DEPLOYMENT_SCRIPT_PRE" ]; then
		echo "Executing pre script '$DEPLOYMENT_SCRIPT_PRE'."
		$DEPLOYMENT_SCRIPT_PRE
		echo
	fi

	# Run the rsync command.
	# The command have been wrapped with an if-statement to check if the
	# command was successful or failed.
	if rsync $RSYNC_OPTIONS --exclude-from $ENVIRONMENT_EXCLUDE $SOURCE $DESTINATION
	then
		echo
		echo "Deployment have been completed."

		# Run the success post setup/clean up script.
		if [ -n "$DEPLOYMENT_SCRIPT_POST_SUCCESS" ]; then
			echo
			echo "Executing post script '$DEPLOYMENT_SCRIPT_POST_SUCCESS'."
			$DEPLOYMENT_SCRIPT_POST_SUCCESS
			echo
		fi

		exit 0
	else
		echo
		echo "Deployment have failed."

		# Run the failure post setup/clean up script.
		if [ -n "$DEPLOYMENT_SCRIPT_POST_FAILURE" ]; then
			echo
			echo "Executing post script '$DEPLOYMENT_SCRIPT_POST_FAILURE'."
			$DEPLOYMENT_SCRIPT_POST_FAILURE
			echo
		fi

		exit 1
	fi
else
	# Handle error.
	echo "No property file is available for the environment '$NAME'."
	exit 2
fi