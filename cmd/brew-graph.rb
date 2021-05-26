#!/usr/bin/env ruby

#:`brew graph` [options] <formula1> <formula2> ... | `--installed` | `--all`
#:
#:Create a dependency graph of Homebrew formulae.
#:
#:Options:
#:
#: `-h`, `--help`          Print this help message.
#: `-f`, `--format FORMAT` Specify FORMAT of graph (dot, graphml). Default: dot
#: `-o`, `--output FILE`   Write output to FILE instead of stdout
#: `--highlight-leaves`    Highlight formulae that are not dependencies of another
#:                         formula. Default: false
#: `--highlight-outdated`  Highlight formulae that are outdated. Default: false
#: `--include-casks`       List formulae and casks
#: `--installed`           Create graph for installed Homebrew formulae
#: `--all`                 Create graph for all Homebrew formulae
#:
#:Examples:
#:
#:`brew graph` `--installed`
#: Create a dependency graph of installed formulae and
#: print it in DOT format to stdout.
#:
#:`brew graph` `-f` graphml `--installed`
#: Same as before, but output GraphML markup.
#:
#:`brew graph` <graphviz> <python>
#: Create a dependency graph of 'graphviz' and 'python' and
#: print it in DOT format to stdout.
#:
#:`brew graph` `-f` graphml `-o` deps.graphml <graphviz> <python>
#: Same as before, but output GraphML markup to a file named 'deps.graphml'.

require 'optparse'

class BrewGraph

  def initialize(argv)
    @options = parse_options(argv)

    # Assume that any remaining arguments are formula names.
    if argv.length >= 1
      @formulae = argv.dup
    end
  end

  def run
    all = @options[:all]
    installed = @options[:installed]
    include_casks = @options[:include_casks]
    format = @options[:format]
    output = @options[:output]
    highlight_leaves = @options[:highlight_leaves]
    highlight_outdated = @options[:highlight_outdated]

    data = if installed
        deps(:installed, include_casks)
      elsif all
        deps(:all, include_casks)
      elsif @formulae
        deps(@formulae, false)
      else
        abort %Q{This command requires one of --installed or --all, or one or more formula arguments.
See brew graph --help.}
      end

    if installed
      remove_optional_deps(data)
    end

    graph = case format
        when :dot then Dot.new(data, highlight_leaves, highlight_outdated && outdated)
        when :graphml then GraphML.new(data, highlight_leaves, highlight_outdated && outdated)
        else abort "Format #{format} not support. Support formats are: dot, graphml"
      end

    if output
      File.open(output, 'w') { |file| file.write(graph) }
    else
      puts graph
    end
  end

  private

    def parse_options(argv)
      options = {}
      options[:format] = :dot
      options[:highlight_leaves] = false
      options[:highlight_outdated] = false
      options[:include_casks] = false
      options[:all] = false
      options[:installed] = false

      opts = OptionParser.new do |opts|

        opts.banner = 'Usage: brew-graph [options] <formula1> <formula2> ... | --installed | --all'

        opts.on('-h', '--help'  ) do
          puts opts
          exit
        end

        opts.on('-f', '--format FORMAT', [:dot, :graphml],
                'Specify FORMAT of graph (dot, graphml). Default: dot') do |f|
          options[:format] = f
        end

        opts.on('-o', '--output FILE',
                'Write output to FILE instead of stdout') do |o|
          options[:output] = o
        end

        opts.on('--highlight-leaves', [:highlight_leaves],
                'Highlight formulae that are not dependencies of another formula. Default: false') do
          options[:highlight_leaves] = true
        end

        opts.on('--highlight-outdated', [:highlight_outdated],
                'Highlight formulae that are outdated. Default: false') do
          options[:highlight_outdated] = true
        end

        opts.on('--include-casks', [:include_casks],
                'Include casks in the graph. Default: false') do
          options[:include_casks] = true
        end

        opts.on('--all', [:all],
                'Create graph for all Homebrew formulae') do
          options[:all] = true
        end

        opts.on('--installed', [:installed],
                'Create graph for installed Homebrew formulae') do
          options[:installed] = true
        end

      end

      begin
        opts.parse!(argv)
      rescue OptionParser::InvalidOption,
             OptionParser::InvalidArgument,
             OptionParser::MissingArgument => e
        abort "#{e.message.capitalize}\nSee brew graph --help."
      end

      options
    end

    def deps(arg, include_casks)
      data = {}
      deps = brew_deps(arg, include_casks).split("\n")
      deps.each do |s|
        node,deps = s.split(':')
        data[node] = deps.nil? ? [] : deps.strip.split(' ').uniq
      end
      data
    end

    def outdated
      brew_outdated.split("\n")
    end

    def brew_deps(arg, include_casks)
      type = include_casks ? nil : '--formulae'

      case arg
        when :all then %x[brew deps --1 --full-name --all #{type}]
        when :installed then %x[brew deps --1 --full-name --installed #{type}]
        else # Treat arg as a list of formulae
          res = {}
          brew_deps_formulae(res, arg.join(' '))
          res.map { |k, v| "#{k}: #{v}" }.join("\n")
      end
    end

    # Gets the first-level dependencies of the input formulae and recurses
    # down to the leaves to get the complete dependency graph.
    #
    # The output of `brew deps --for-each --1 <formulae>` is of the form:
    #   formula1: dep1 dep2 dep3 ...
    #   formula2: dep1 dep2 dep3 ...
    # We need to add additional lines
    #   dep1:
    #   dep2:
    #   dep3:
    # for all dependencies.
    # This is consistent with the output of 'brew deps --installed'.
    # Also, the GraphML markup language requires a separate <node>
    # block for each node in the graph.
    def brew_deps_formulae(res, arg)
      out = %x[brew deps --for-each --1 #{arg}]
      unless $? == 0 # Check exit code
        abort
      end
      out.split("\n").each do |line|
        formula,deps = line.split(':')
        unless res.has_key? formula
          deps = deps.strip
          res[formula] = deps
          unless deps.empty?
            brew_deps_formulae(res, deps)
          end
        end
      end
    end

    def brew_outdated
      %x[brew outdated]
    end

    def print_deps(data)
      data.each_pair do |source, targets|
        puts "#{source} -> #{targets.inspect}"
      end
    end

    # Remove uninstalled, optional dependencies
    def remove_optional_deps(data)
      data.each_value do |deps|
        deps.keep_if do |dep|
          data.include?(dep)
        end
      end
    end
end

class Graph

  def initialize(data, highlight_leaves, outdated)
    @data = data
    @dependencies = data.values.flatten.uniq
    @highlight_leaves = highlight_leaves
    @outdated = outdated
  end

  def is_leaf?(node)
    !@dependencies.include?(node)
  end

  def is_outdated?(node)
    @outdated.include?(node)
  end
end

class Dot < Graph

  def to_s
    dot = []
    dot << 'digraph G {'
    @data.each_key do |node|
      dot << create_node(node, @highlight_leaves && is_leaf?(node), @outdated && is_outdated?(node))
    end
    @data.each_pair do |source, targets|
      targets.each do |target|
        dot << create_edge(source, target)
      end
    end
    dot << '}'
    dot.join("\n")
  end

  private

    def create_node(node, is_leaf, is_outdated)
      %Q(  "#{node}"#{is_outdated ? ' [style=filled;color=red2]' : is_leaf ? ' [style=filled]' : ''};)
    end

    def create_edge(source, target)
      %Q(  "#{source}" -> "#{target}";)
    end
end

class GraphML < Graph

  def to_s
    out = []
    out << header
    out << '  <graph edgedefault="directed" id="G">'
    @data.each_key do |node|
      out << create_node(node, @highlight_leaves && is_leaf?(node), @outdated && is_outdated?(node))
    end
    @data.each_pair do |source, targets|
      targets.each do |target|
        out << create_edge(source, target)
      end
    end
    out << '  </graph>'
    out << '</graphml>'
    out.join("\n")
  end

  private

    def header
<<-EOS
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<graphml
  xmlns="http://graphml.graphdrawing.org/xmlns"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:y="http://www.yworks.com/xml/graphml"
  xmlns:yed="http://www.yworks.com/xml/yed/3"
  xsi:schemaLocation="
    http://graphml.graphdrawing.org/xmlns
    http://www.yworks.com/xml/schema/graphml/1.1/ygraphml.xsd">
  <key for="node" id="d0" yfiles.type="nodegraphics"/>
  <key for="edge" id="d1" yfiles.type="edgegraphics"/>
EOS
    end

    def create_node(node, is_leaf, is_outdated)
      fill_color = is_outdated ? '#FF6666': is_leaf ? '#C0C0C0' : '#FFFFFF'
<<-EOS
    <node id="#{node}">
      <data key="d0">
        <y:ShapeNode>
          <y:NodeLabel>#{node}</y:NodeLabel>
          <y:Fill color="#{fill_color}"/>
          <y:Shape type="ellipse"/>
        </y:ShapeNode>
      </data>
    </node>
EOS
    end

    def create_edge(source, target)
      @edge_id ||= 0
      @edge_id += 1
<<-EOS
    <edge id="e#{@edge_id}" source="#{source}" target="#{target}">
      <data key="d1">
        <y:PolyLineEdge>
          <y:Arrows source="none" target="delta"/>
          <y:BendStyle smoothed="true"/>
        </y:PolyLineEdge>
      </data>
    </edge>
EOS
    end
end

if RUBY_VERSION =~ /1\.8/
  class Hash
    def keep_if(&block)
      delete_if do |key, value|
        !block.call(key, value)
      end
    end
  end

  class Array
    def keep_if(&block)
      delete_if do |elem|
        !block.call(elem)
      end
    end
  end
end

brew = BrewGraph.new(ARGV)
brew.run
