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

pushd .
cd /tmp

echo -e "${YELLOW}Cloning Kibana...${NC}"

rm -rf kibana
git clone https://github.com/elastic/kibana.git
cd kibana

versions=$(git tag | grep -o -e '^v[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}$' | cut -dv -f2-)	# Filter only final versions
popd


create_version() {
	kibana=$1
	node=$2
	tagname=$3
	
	ans="n"
	while [ "$ans" = "n" ]; do
		echo -e "${YELLOW}Check if this is correct:${NC}"
		echo "    Node version: $node"
		echo "  Kibana version: $kibana"
		read -r -p "This is correct (YES/No/Skip)? " ans
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
	sed -i "s/.*ENV KIBANA_VERSION.*/ENV KIBANA_VERSION $kibana/" Dockerfile
	git add Dockerfile
	git commit -m "Kibana v$tagname"
	git tag $tagname

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

	create_version $version $node_version $version
	create_version $version $node_version-slim $version-slim
	create_version $version $node_version-alpine $version-alpine
done

git push --tags --force

