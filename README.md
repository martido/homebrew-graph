# brew-graph

`brew-graph` is a Ruby script that creates a dependency graph of installed or all available Homebrew formulae. The currently supported output options are *Dot* and *GraphML*.

### Installation

You can install `brew-graph` using the [tap repository](https://github.com/martido/homebrew-brew-graph): 

    brew install martido/brew-graph/brew-graph

Alternatively, simply place `brew-graph.rb` somewhere in your `$PATH` as `brew-graph`.

## Usage

If you installed using the above instructions, you can simply execute `brew graph -h` to see options.

If within this repository directory, type `ruby brew-graph.rb -h` to display the options. 

## Requirements
You can use Graphviz to visualize Dot graphs.

    brew install graphviz
    brew graph | dot -Tsvg -odependency_graph.svg
    open dependency_graph.svg

You can use the [yEd][1] graph editor to visualize GraphML markup. The created markup uses yFiles's extensions to GraphML and heavily relies on defaults to keep the output reasonably small. It contains no layout information because yEd already provides an exhaustive set of algorithms.

[1]: http://www.yworks.com/en/products_yed_about.html
