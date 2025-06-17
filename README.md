# Nuxlper
Nuxlper is bash-based set of tools to help the Nuxeo
developer.
It provides :
- Nuxeo docker container ready to use with a few
options in nuxeo.conf and register the studio instance.
- Fake smtp used by the Nuxeo container.


## Table of contents
- [Getting started](#getting-started)
- [Building the archive](#building-the-archive)
- [Using Nuxlper](#using-nuxlper)
  - [Initializing from scratch](#initializing-from-scratch)
- [Performing Nuxeo hot reload](#performing-nuxeo-hot-reload)

## Getting started

You need Docker to use this tool and you need Bash to buid the archive.

## Building the archive

```bash
./build.sh
```
Archive lays in [build/dist](build/dist) folder.

## Using Nuxlper

### Initializing from scratch

```bash
# unpack your archive
# tar -xf ...
# Use init script if you want
./init_structure.sh
```

Now you are ready to configure _nuxlper.conf_ then launch the script you want.
- **00_install_all.sh**: execute the three scripts below! 
- **01_build_fresh_nuxeo_container.sh**: create the Nuxeo container and configure it using _nuxlper.conf_:
  - enable jpda
  - add proxy if needed
  - configure fake-smtp
👉You have Nuxeo environment ready to use and ready for modules installation
- **02_install_nuxeo_items.sh**: install a few standard module from market place, install your studio project and also install local custom modules
- **03_post_install.sh**: a script to be executed after the 02 script. Can be for example users and groups creation.
- **04_nuxeo_hot_reload.sh**: a script to be executed after the 02 script. Can be for example users and groups creation.

### Performing Nuxeo hot reload
You can use the following command to perform a Nuxeo hot reload
```bash
tools/install_nuxeo_items.sh --reload
# or
tools/install_nuxeo_items.sh -r
```
If you used the _init_structure.sh_ you can launch _04_nuxeo_hot_reload.sh_. 

## Next work
💡I planned to add a tool to build an docker image after _01_build_fresh_nuxeo_container_.

## Author
Quang-Minh TRAN