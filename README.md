A Ruby script that creates a dependency graph of installed or all available Homebrew formulae. The currently supported output options are *Dot* and *GraphML*. The Homebrew distribution contains a similar, [script][1] written in Python which describes the dependency graph in the Dot language.

## Usage
Type `ruby brew-graph.rb -h` to display a list of available options.
        
## Requirements
You can use Graphviz to visualize Dot graphs.

    brew install graphviz
    brew-graph | dot -Tsvg -odependency_graph.svg
    open dependency_graph.svg

You can use the [yEd][2] graph editor to visualize GraphML markup. The created markup uses yFiles's extensions to GraphML and heavily relies on defaults to keep the output reasonably small. It contains no layout information because yEd already provides an exhaustive set of algorithms.

[1]: https://github.com/mxcl/homebrew/blob/master/Library/Contributions/examples/brew-graph
[2]: http://www.yworks.com/en/products_yed_about.html