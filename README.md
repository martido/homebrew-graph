A Ruby script that creates a simple dependency graph of installed Homebrew formulae. The currently supported output options are *Dot* and *GraphML*. The Homebrew distribution contains a similar, but functionally more extensive, [script][1] written in Python which describes the dependency graph in the Dot language.

## Usage
    Usage: brew-graph [options]
        -h, --help
        -f, --format FORMAT              Specify FORMAT of graph (dot, graphml)
                                         Default: dot
        -o, --output FILE                Write output to FILE instead of stdout
        
## Requirements
The GraphML markup is created using the Builder gem. The gem is required on demand, i.e. it is only needed if you use specify the `-f graphml` option.
> gem install builder

You can use Graphviz to visualize Dot graphs.
> brew install graphviz
> brew-graph | dot -Tsvg -odependency_graph.svg
> open dependency_graph.svg

You can use the [yEd][2] graph editor to visualize GraphML markup. However, the script does not yet support any of yWorks's extensions to the GraphML format. Thus the output is pretty unusable so far.

[1]: https://github.com/mxcl/homebrew/blob/master/Library/Contributions/examples/brew-graph
[2]: http://www.yworks.com/en/products_yed_about.html