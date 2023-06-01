## Usage

### Setup

```console
$ docker compose build
```

### Load default data

```console
$ docker compose run redmine bin/rake redmine:load_default_data REDMINE_LANG=ja
```

### Run Redmine

```console
$ docker compose up
```
