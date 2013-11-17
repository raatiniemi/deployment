# [deployment](https://github.com/raatiniemi/deployment)

deployment is a simple bash script that relies on [rsync](http://en.wikipedia.org/wiki/Rsync) to copy a local folder to a remote source. The file transfer uses the SSH protocol, i.e. you should setup the authorization outside of the deployment script with SSH keys and `authorized_keys` on the remote source.

## How to

First of, copy the example files (`example.properties` and `example.exclude`) and setup the deployment information (user, host, remote folder, and local folder). Note that your new files must have the same basename, excluding of cource the extension.

Now, to deploy the source to the remote target simply execute the `deploy.sh` script with the target as argument.

	// Deploy the example target
	sh ./deploy.sh example