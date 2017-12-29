# Docker Kibana Development

[![](https://images.microbadger.com/badges/image/rigon/kibana-dev.svg)](https://microbadger.com/images/rigon/kibana-dev "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/rigon/kibana-dev.svg)](https://microbadger.com/images/rigon/kibana-dev "Get your own version badge on microbadger.com")

Docker image with Kibana for plugin developement

## Image variants

The `rigon/kibana-dev` images come in many flavors, each designed for a specific use case. They are from [node](https://hub.docker.com/_/node/) image:

 - `rigon/kibana-dev:<version>`: the defacto image. If you are unsure, you probably want to use this one.
 - `rigon/kibana-dev:<version>-alpine`: based on the popular Alpine Linux project. Much smaller image.
 - `rigon/kibana-dev:<version>-slim`: do not contain the common packages as in the default tag and only contains the minimal packages needed to run node.


## How to run

This image requires an [elasticsearch](https://hub.docker.com/_/elasticsearch/) up and running with the same version of Kibana:

    $ docker run --name some-elasticsearch -p 9200:9200 -d docker.elastic.co/elasticsearch/elasticsearch:[version]

This image includes EXPOSE 5601 (default port). If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used:

    $ docker run --name some-kibana --link some-elasticsearch:elasticsearch -p 5601:5601 -t rigon/kibana-dev

If you are developing plugins for Kibana, you might want to mount your plugins folder in Kibana through a volume:

    $ docker run --name some-kibana -v your_plugins_folder:/kibana/plugins:rw --link some-elasticsearch:elasticsearch -p 5601:5601 -t rigon/kibana-dev

Or if you are only developing one plugin, you might want to mount the plugin folder directly into Kibana:

    $ docker run --name some-kibana -v your_plugin_path:/kibana/plugins/your_plugin_name:rw --link some-elasticsearch:elasticsearch -p 5601:5601 -t rigon/kibana-dev
    
    
## How to build

The script `build.sh` automatically creates tags for every version of Kibana, just run it and follow the instructions!
