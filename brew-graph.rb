#!/usr/bin/env ruby

require 'optparse'

class BrewGraph

  def initialize(argv)
    @options = parse_options(argv)

    # If there's one or more remaining arguments, take the first one
    # and assume that it is the name of a formula
    if argv.length >= 1
      @formula = argv.first
    end
  end

  def run
    all = @options[:all]
    installed = @options[:installed]
    format = @options[:format]
    output = @options[:output]

    data = if installed
        deps(:installed)
      elsif all
        deps(:all)
      elsif @formula
        deps(@formula)
      else
        abort 'This command requires one of --installed or --all, or a formula argument'
      end

    if installed
      remove_optional_deps(data)
    end

    graph = case format
        when :dot then Dot.new(data)
        when :graphml then GraphML.new(data)
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
      options[:all] = false
      options[:installed] = false
      options[:format] = :dot

      opts = OptionParser.new do |opts|

        opts.banner = 'Usage: brew-graph [-f] [-o] [--all] [--installed] formula'

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
        abort "#{e.message.capitalize}\n#{opts}"
      end

      options
    end

    def deps(arg)
      data = {}
      deps = brew_deps(arg).split("\n")
      deps.each do |s|
        node,deps = s.split(':')
        data[node] = deps.nil? ? nil : deps.strip.split(' ').uniq
      end
      data
    end

    def brew_deps(arg)
      case arg
        when :all then %x[brew deps --all]
        when :installed then %x[brew deps --installed]
        else # Treat argument as the name of a formula
          out = %x[brew deps #{arg}]
          unless $? == 0 # Check exit code
            abort
          end
          # Transform output to the form "formula: dep1 dep2 dep3 ..."
          "#{arg}: #{out.split("\n").map { |dep| dep.strip }.join(' ')}"
      end
    end

    def print_deps(data)
      data.each_pair do |source, targets|
        puts "#{source} -> #{targets.inspect}"
      end
    end

    # Remove uninstalled, optional dependencies
    def remove_optional_deps(data)
      data.each_pair do |source, targets|
        targets.keep_if do |target|
          data.include?(target)
        end
      end
    end
end

class Dot

  def initialize(data)
    @data = data
  end

  def to_s
    dot = []
    dot << 'digraph G {'
    @data.each_key do |node|
      dot << create_node(node)
    end
    @data.each_pair do |source, targets|
      next if targets.nil?
      targets.each do |target|
        dot << create_edge(source, target)
      end
    end
    dot << '}'
    dot.join("\n")
  end

  private

    def create_node(node)
      %Q(  "#{node}";)
    end

    def create_edge(source, target)
      %Q(  "#{source}" -> "#{target}";)
    end
end

class GraphML

  def initialize(data)
    @data = data
  end

  def to_s
    out = []
    out << header
    out << '  <graph edgedefault="directed" id="G">'
    @data.each_key do |node|
      out << create_node(node)
    end
    @data.each_pair do |source, targets|
      next if targets.nil?
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

    def create_node(node)
<<-EOS
    <node id="#{node}">
      <data key="d0">
        <y:ShapeNode>
          <y:NodeLabel>#{node}</y:NodeLabel>
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
