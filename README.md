# ManageIQ.org website

This is primarily a [Jekyll](https://github.com/jekyll/jekyll) site, with some tools to collect and pre-process documentation from multiple sources.

## How To Contribute

In general:

1. Fork this repo
2. Create a feature branch
3. Submit a pull request

The site content has different sources.

### Source Overview

| Directory | Contents                                 |
| --------- | ---------------------------------------- |
| dest      | where the site is built locally          |
| lib       | Ruby code for CLI, processing docs, etc. |
| site      | Site content                             |
| test      | Tests for Ruby code                      |


### Documentation groups

The documentation for ManageIQ comes from several sources which are continuously improved.
Contributions are welcome to each of these, here's where you can help:

#### Getting started
Docs in the getting started group are part of this repo, find them under [site/docs/get-started](/site/docs/get-started)

#### User reference
The user reference docs are hosted at https://github.com/ManageIQ/manageiq_docs. They are written in [Asciidoc](http://asciidoc.org/) and organized in [AsciiBinder](http://www.asciibinder.org/) By default they are built in a temp directory and copied (rsync) to `/site/docs/reference/latest`.

#### API Docs
The API Docs are hosted in the same repo as the User Reference, [under the api directory](https://github.com/ManageIQ/manageiq_docs/tree/master/api)

#### Developer Guides
These guides describe how to work with and contribute to the source code of ManageIQ itself. They are found in this repo: https://github.com/ManageIQ/guides.

Before the Jekyll site is built, YAML front matter is added to each page of the guides, if that page does not already have it.

Currently this is included as a Git submodule.

#### Automation book
[Peter McGowan](https://github.com/pemcg) is working on a book covering the Automation features of ManageIQ. You can find the source for that book here: https://github.com/pemcg/mastering-automation-in-cloudforms-and-manageiq. However, this content is hosted on Gitbook and only linked to from the site.

### Working Locally


```console
$ rake -T
rake build:all                 # Buildes guides, Jekyll site, and reference docs
rake build:guides              # Build guides
rake build:menus               # Regenerate menu yaml files
rake build:reference           # Build Reference Docs
rake build:site                # Build Jekyll site
rake generate:lwimiq[current]  # Generate a LWIMIQ blog post
rake reset:all                 # Reset all repos to clean state
rake reset:guides              # Reset guides to clean state
rake reset:reference           # Delete reference docs tmp directory
rake reset:site                # Reset site repo to clean state
rake serve                     # Does Jekyll serve with appropriate args
rake test                      # Run tests
rake update:all                # Update guides and site from upstream; prime ref doc repo
rake update:guides             # Reset and update guides repo
rake update:reference          # Prime the reference docs staging directory
rake update:site               # Reset and update site repo
```

### Working with large images

Images (img) in documents and blog posts should be "responsive" by default, that is their width should not exceed the width of their container. Add the `.large_img` class to give large images zoomability.

### Questions / Suggestions?
* Chat: https://gitter.im/ManageIQ/manageiq.org
* Forum: http://talk.manageiq.org/c/website
