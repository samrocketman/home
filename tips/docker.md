# Run docker images with an init process

Docker images should have better process handling.  [Yelp
`dumb-init`][dumb-init] is a nice basic init written in C.

    docker run -d -v /path/to/dumb-init:/dumb-init:ro --entrypoint=/dumb-init <image> <command>

Alternately, docker comes with `tini` init builtin.

    docker run -d --init <image> <command>

[dumb-init]: https://github.com/Yelp/dumb-init/issues/74#issuecomment-217669450

# docker-compose include an init

docker-compose supported the docker init option in their `2.2` specification.
Here's an example `docker-compose.yml` file using the init option.

```yaml
version: '2.2'
services:
  web:
    image: alpine:latest
    init: true
```

Use `dumb-init` as the custom init.

```yaml
version: '2.2'
services:
  web:
    image: alpine:latest
    init: /dumb-init
    volumes:
      - /path/to/dumb-init:/dumb-init:ro
```

[dcf]: https://docs.docker.com/compose/compose-file/compose-file-v2/
