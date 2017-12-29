FROM node:slim

# Choose which Kibana version you want
# follow Git terminology to checkout tags: "tags/v<version>"
ENV KIBANA_VERSION master

RUN set -x \
	&& apt-get update \
	&& apt-get install -y git \
	&& git clone https://github.com/elastic/kibana.git \
	&& cd kibana \
	&& git checkout $KIBANA_VERSION \
	&& rm -rf .git \
	&& npm install \
	
	# the default "server.host" is "localhost" in 5+
	&& sed -ri "s!^(\#\s*)?(server\.host:).*!\2 '0.0.0.0'!" /kibana/config/kibana.yml \
	&& grep -q "^server\.host: '0.0.0.0'\$" /kibana/config/kibana.yml \
	
	# ensure the default configuration is useful when using --link
	&& sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 'http://elasticsearch:9200'!" /kibana/config/kibana.yml \
	&& grep -q "^elasticsearch\.url: 'http://elasticsearch:9200'\$" /kibana/config/kibana.yml

EXPOSE 5601
WORKDIR /kibana
VOLUME /kibana/plugins
CMD ["npm", "start"]
