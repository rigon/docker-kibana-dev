#!/bin/sh

RED="\033[0;31m"
BLUE="\033[0;34m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color


if [ ! -e Dockerfile ]; then
	echo -e "${RED}Dockerfile not found!${NC}"
	exit 1
fi

echo "A clone of Kibana repository in /tmp is required to proceed!"
read -r -p "Do you want clone it (YES/No)? " ans
if [ "$ans" != "n" ]; then
	pushd .
	cd /tmp
	echo -e "${YELLOW}Cloning Kibana...${NC}"
	rm -rf kibana
	git clone https://github.com/elastic/kibana.git
	popd
fi

# Get list of tags from Kibana repository
pushd .
cd /tmp/kibana
# Get and filter only final versions
versions=$(git tag | grep -o -e '^v[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$' | cut -dv -f2-)
popd

echo -e "${RED}CAUTION: THIS ACTION IS IRREVERSIBLE!!${NC}"
echo "This will delete all tags in the local repository!"
read -r -p "Do you want delete all tags in local reposiroty (yes/NO)? " ans
if [ "$ans" = "yes" ]; then
	git tag --delete $(git tag)
fi


create_version() {
	kibana=$1
	node=$2
	tagname=$3
	
	if [ "$ans" != "a" ]; then
		ans="n"
	fi
	while [ "$ans" = "n" ]; do
		echo -e "${YELLOW}Check if this is correct:${NC}"
		echo "    Node version: $node"
		echo "  Kibana version: $kibana"
		read -r -p "This is correct (YES/No/Skip/All)? " ans
		if [ "$ans" = "n" ]; then
			read -r -p "Node version? " nver
		fi
	done
	
	# Skip
	if [ "$ans" = "s" ]; then
		return
	fi
	
	# Create version
	git tag -d $tagname		# Delete existing version
	sed -i "s/.*FROM node.*/FROM node:$node/" Dockerfile
	sed -i "s/.*ENV KIBANA_VERSION.*/ENV KIBANA_VERSION tags\/v$kibana/" Dockerfile
	git add Dockerfile
	git commit -m "Kibana v$tagname"
	git tag $tagname
	git reset HEAD~
	git checkout -- Dockerfile
}


for version in $versions; do
	echo -e "${BLUE}-- ${GREEN}Version $version${NC}"

	# Get corresponding node version
	pushd .
	cd /tmp/kibana
	git checkout tags/v$version
	if [ -e .node-version ]; then
		node_version=$(cat .node-version | sed "s/.x//")
	else
		node_version="0.10"		# Older versions
	fi
	popd

	# Main versions
	git checkout main
	create_version $version $node_version $version
	# Slim versions
	git checkout slim
	create_version $version $node_version-slim $version-slim
	# Alpine versions
	git checkout alpine
	create_version $version $node_version-alpine $version-alpine
done

# Back to master
git checkout master

echo
echo -e "${RED}CAUTION: THIS ACTION IS IRREVERSIBLE!!${NC}"
echo "This will delete all tags in the REMOTE repository!"
read -r -p "Do you want delete all tags in REMOTE repository (yes/NO)? " ans
if [ "$ans" = "yes" ]; then
	git push --delete origin $(git ls-remote --tags origin | cut -f 2-)
fi

echo
echo "This will push all local tags to the remote repository!"
read -r -p "Do you want push tags changes (YES/No)? " ans
if [ "$ans" != "n" ]; then
	git push --tags --force
fi

echo
echo -e "${YELLOW}Docker Hub trigger token is required to trigger builds${NC}"
read -r -p "Trigger token: " trigger_token
if [ "$trigger_token" = "" ]; then
	echo -e "${RED}No trigger token provided!${NC}"
	echo "Exiting..."
	exit 1
fi


echo
echo -e "${YELLOW}We are about to trigger builds${NC}"
echo "This will trigger builging all versions, i. e. all tags."
echo "If not, you will be asked to build main, slim and alpine versions."
read -r -p "Do you want to trigger building all versions (Yes/NO)? " ans
if [ "$ans" = "y" ]; then
	for tag in $(git tag); do
		echo -n -e "${YELLOW}$tag${NC} "
		curl -X POST -H "Content-Type: application/json" \
			--data \{\"source_type\":\ \"Tag\",\ \"source_name\":\ \"${tag}\"\} \
			https://registry.hub.docker.com/u/rigon/kibana-dev/trigger/$trigger_token/;
		echo
		sleep 1m
	done
	echo -e "${GREEN}DONE!${NC}"
	exit 0
fi


echo
read -r -p "Do you want to trigger building all main versions (YES/No)? " ans
if [ "$ans" != "n" ]; then
	for tag in $(git tag | grep -v -E "alpine|slim"); do
		echo -n -e "${YELLOW}$tag${NC} "
		curl -X POST -H "Content-Type: application/json" \
			--data \{\"source_type\":\ \"Tag\",\ \"source_name\":\ \"${tag}\"\} \
			https://registry.hub.docker.com/u/rigon/kibana-dev/trigger/$trigger_token/;
		echo
		sleep 1m
	done
fi


echo
read -r -p "Do you want to trigger building all slim versions (YES/No)? " ans
if [ "$ans" != "n" ]; then
	for tag in $(git tag | grep slim); do
		echo -n -e "${YELLOW}$tag${NC} "
		curl -X POST -H "Content-Type: application/json" \
			--data \{\"source_type\":\ \"Tag\",\ \"source_name\":\ \"${tag}\"\} \
			https://registry.hub.docker.com/u/rigon/kibana-dev/trigger/$trigger_token/;
		echo
		sleep 1m
	done
fi

echo
read -r -p "Do you want to trigger building all alpine versions (YES/No)? " ans
if [ "$ans" != "n" ]; then
	for tag in $(git tag | grep alpine); do
		echo -n -e "${YELLOW}$tag${NC} "
		curl -X POST -H "Content-Type: application/json" \
			--data \{\"source_type\":\ \"Tag\",\ \"source_name\":\ \"${tag}\"\} \
			https://registry.hub.docker.com/u/rigon/kibana-dev/trigger/$trigger_token/;
		echo
		sleep 1m
	done
fi

echo -e "${GREEN}DONE!${NC}"
