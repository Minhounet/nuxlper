# Nuxlper
Nuxlper is bash-based set of tools 🔧🔨 to help the Nuxeo
developer.
It provides :
- Nuxeo docker container ready to use with a few
options in nuxeo.conf and register the studio 🎬 instance.
- Fake smtp used by the Nuxeo container.
- Postgresql docker container used by Nuxeo

## 📖 Table of contents
- [Getting started](#getting-started)
- [Building the archive](#building-the-archive)
- [Using Nuxlper](#using-nuxlper)
  - [Initializing from scratch](#initializing-from-scratch)
  - [Performing Nuxeo hot reload](#performing-nuxeo-hot-reload)
  - [Updating studio project](#updating-studio-project)
- [Next work](#next-work)
- [About this project](#about-this-project)
- [Author](#author)

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
  - configure postgresql access
  - ...
👉You have Nuxeo environment ready to use and ready for modules installation
- **02_install_nuxeo_items.sh**: install a few standard module from market place, install your studio project and also install local custom modules
- **03_post_install.sh**: a script to be executed after the 02 script. Can be for example users and groups creation.
- **_nuxeo_hot_reload.sh**: Perform the famous Nuxeo hot reload
- **_nuxeo_install_studio_only.sh**: remove and install studio project (if studio hot reload does not work properly)
- **_nuxeo_restart_only.sh**: restart Nuxeo server

### Performing Nuxeo hot reload
You can use the following command to perform a Nuxeo hot reload
```bash
tools/install_nuxeo_items.sh --reload
# or
tools/install_nuxeo_items.sh -r
```
If you used the _init_structure.sh_ you can launch _nuxeo_hot_reload.sh_. 

### Updating studio project
You can use the following command to perform the studio project update
```bash
tools/install_nuxeo_items.sh --studio-only
# or
tools/install_nuxeo_items.sh -so
```
If you used the _init_structure.sh_ you can launch _install_studio_only.sh_.

## About this project

This came to life for many reasons:
- I was fed up 😡 with Nuxeo chrome plugin with the hot reload
- I wanted to be able to install from scratch all Nuxeo with my customisations

This may look like a Docker compose and in a way you are right because it acts as an orchestrator. But first I like
the power of Bash and I thought it was very easy to call Nuxeo commands directly.

Basically, when I want to be sure to have everything fresh, I use the "install all" script which gives me a fresh Nuxeo
environment with my customizations and I don't have to think if there is any data corrupted or not.

## Author
Quang-Minh TRAN
