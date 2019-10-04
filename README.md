**Attention:** This repository has been renamed from `brew-graph` to `homebrew-graph` to adhere to the Homebrew naming conventions of [tap repositories][3].
Please update your local clones or forks (for consistency only, GitHub makes sure everything still works for you):

    git remote set-url origin https://github.com/martido/homebrew-graph

# brew-graph

`brew-graph` is a Ruby script that creates a dependency graph of installed or all available Homebrew formulae. The currently supported output options are *DOT* and *GraphML*.

In general, if you'd like to know more about [Untangling Your Homebrew Dependencies][2], check out the blog post by Jonathan Palardy.  

### Installation

You can install `brew-graph` using the [tap repository](https://github.com/martido/homebrew-brew-graph): 

    brew install martido/brew-graph/brew-graph

Alternatively, simply place `brew-graph.rb` somewhere in your `$PATH` as `brew-graph`.

## Usage

If you installed using the above instructions, you can simply execute `brew graph -h` to see options.

If within this repository directory, type `ruby brew-graph.rb -h` to display the options.

    Usage: brew-graph [-f] [-o] [--highlight-leaves] [--highlight-outdated] <formulae|--installed|--all>
    Examples:
      brew graph --installed                                - Create a dependency graph of all installed formulae and print it in dot format to stdout.
      brew graph -f graphml --installed                     - Same as before, but output GraphML markup.
      brew graph -f graphml graphviz python                 - Create a dependency graph of the 'graphviz' and 'python' formulae and print it in GraphML markup to stdout.
      brew graph -f graphml -o deps.graphml graphviz python - Same as before, but output to a file named 'deps.graphml'.
        -h, --help
        -f, --format FORMAT              Specify FORMAT of graph (dot, graphml). Default: dot
            --highlight-leaves           Highlight formulae that are not dependencies of another formula. Default: false
            --highlight-outdated         Highlight formulae that are outdated. Default: false
        -o, --output FILE                Write output to FILE instead of stdout
            --all                        Create graph for all Homebrew formulae
            --installed                  Create graph for installed Homebrew formulae

## Requirements
You can use Graphviz to visualize DOT graphs.

    brew install graphviz
    brew graph --installed | dot -Tpng -ograph.png
    open graph.png

Of course, you can also use a different Graphviz layout, such as `fdp`. Simply replace `dot` with `fdp`:

    brew graph --installed | fdp -Tpng -ograph.png

You can use the [yEd][1] graph editor to visualize GraphML markup. The created markup uses yFiles's extensions to GraphML and heavily relies on defaults to keep the output reasonably small. It contains no layout information because yEd already provides an exhaustive set of algorithms.

[1]: http://www.yworks.com/en/products_yed_about.html
[2]: http://blog.jpalardy.com/posts/untangling-your-homebrew-dependencies
[3]: https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap
