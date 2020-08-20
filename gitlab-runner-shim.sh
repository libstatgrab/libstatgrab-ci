#!/usr/bin/env bash

# Written by Tim Bishop <tim@bishnet.net>, February 2019.

# gitlab-runner-shim is a script that replicates the artifact
# downloading and uploading features found in gitlab-runner. Its
# intended use case is on systems where you can't easily run
# gitlab-runner (or don't want to). It's probably most useful on
# systems where you're using the ssh executor (or the virtualbox or
# parallels executors which both use the ssh executor internally).

# Relevant APIs can be found here (linked commit works as of writing
# this, so check changes from there onwards if things break):
#
# https://gitlab.com/gitlab-org/gitlab-ce/blob/747a5c425a0ce1aa5e9005a03804f2ea513aa73b/lib/api/runner.rb#L298
# https://gitlab.com/gitlab-org/gitlab-ce/blob/747a5c425a0ce1aa5e9005a03804f2ea513aa73b/lib/api/runner.rb#L231
#
# And the gitlab-runner sources doing the same thing:
#
# https://gitlab.com/gitlab-org/gitlab-runner/blob/2979aa0623d58e5af746b6d69b49bbb3613b8443/network/gitlab.go#L486
# https://gitlab.com/gitlab-org/gitlab-runner/blob/2979aa0623d58e5af746b6d69b49bbb3613b8443/network/gitlab.go#L433

CMD=$1
shift
while (( "$#" )); do
	case "$1" in
		--url)
			URL="$2"
			shift 2
			;;
		--token)
			TOKEN="$2"
			shift 2
			;;
		--id)
			ID="$2"
			shift 2
			;;
		--path)
			ARTIFACTPATHS="$ARTIFACTPATHS $2"
			shift 2
			;;
		--expire-in)
			EXPIREIN=`echo $2 | tr " " "+"`
			shift 2
			;;
		--artifact-format)
			ARTIFACTFORMAT="$2"
			shift 2
			;;
		--artifact-type)
			ARTIFACTTYPE="$2"
			shift 2
			;;
		*)
			shift # just ignore unknown flags
			;;
	esac
done

if [ X"${CMD}" = X"artifacts-downloader" ]; then
	curl \
		--silent --location \
		--retry 10 \
		--cacert "${CI_SERVER_TLS_CA_FILE}" \
		--header "JOB-TOKEN: ${TOKEN}" \
		--output artifacts.zip \
		"${URL}api/v4/jobs/${ID}/artifacts"
	unzip -o -q artifacts.zip
	rm -f artifacts.zip
fi

if [ X"${CMD}" = X"artifacts-uploader" ]; then
	rm -f artifacts.zip
	zip -qr artifacts.zip ${ARTIFACTPATHS}
	curl \
		--silent --location \
		--retry 10 \
		--cacert "${CI_SERVER_TLS_CA_FILE}" \
		--header "JOB-TOKEN: ${TOKEN}" \
		-F "file=@artifacts.zip" \
		"${URL}api/v4/jobs/${ID}/artifacts?artifact_format=${ARTIFACTFORMAT}&artifact_type=${ARTIFACTTYPE}&expire_in=${EXPIREIN}" >/dev/null
	rm -f artifacts.zip
fi

# Otherwise implicit success, which is necessary because gitlab-runner
# checks --version works before trying to use the above.
