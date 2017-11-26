# brew-graph

`brew-graph` is a Ruby script that creates a dependency graph of installed or all available Homebrew formulae. The currently supported output options are *Dot* and *GraphML*.

In general, if you'd like to know more about [Untangling Your Homebrew Dependencies][2], check out the blog post by Jonathan Palardy.  

### Installation

You can install `brew-graph` using the [tap repository](https://github.com/martido/homebrew-brew-graph): 

    brew install martido/brew-graph/brew-graph

Alternatively, simply place `brew-graph.rb` somewhere in your `$PATH` as `brew-graph`.

## Usage

If you installed using the above instructions, you can simply execute `brew graph -h` to see options.

If within this repository directory, type `ruby brew-graph.rb -h` to display the options.

    Usage: brew-graph [-f] [-o] [--highlight-leaves] [--highlight-outdated] [--all] [--installed] formula
        -h, --help
        -f, --format FORMAT              Specify FORMAT of graph (dot, graphml). Default: dot
            --highlight-leaves           Highlight formulae that are not dependencies of another formula. Default: false
            --highlight-outdated         Highlight formulae that are outdated. Default: false
        -o, --output FILE                Write output to FILE instead of stdout
            --all                        Create graph for all Homebrew formulae
            --installed                  Create graph for installed Homebrew formulae

## Requirements
You can use Graphviz to visualize Dot graphs.

    brew install graphviz
    brew graph --installed | dot -Tpng -ograph.png
    open graph.png

You can use the [yEd][1] graph editor to visualize GraphML markup. The created markup uses yFiles's extensions to GraphML and heavily relies on defaults to keep the output reasonably small. It contains no layout information because yEd already provides an exhaustive set of algorithms.

[1]: http://www.yworks.com/en/products_yed_about.html
[2]: http://blog.jpalardy.com/posts/untangling-your-homebrew-dependencies
