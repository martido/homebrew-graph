#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'

class BrewGraph

  def initialize(arguments)
    @arguments = arguments
  end

  def run
    options = parse_options(@arguments)

    data = case options.graph
      when :installed then
        deps_all.keep_if do |formula, deps|
          installed.include?(formula)
        end
      when :all then deps_all
      end

    graph = case options.format
      when :dot then Dot.new.to_graph(data)
      when :graphml then GraphML.new.to_graph(data)
      end

    if options.output
      File.open(options.output, 'w') { |file| file.write(graph) }
    else
      puts graph
    end
  end

  private

    def parse_options(arguments)
      options = default_options

      opts = OptionParser.new do |opts|

        opts.on('-h', '--help') do
          puts opts
          exit
        end

        opts.on('-g', '--graph OPTION', [:installed, :all],
                'Create graph for <installed|all> Homebrew formulae',
                'Default: installed') do |g|
          options.graph = g
        end

        opts.on('-f', '--format FORMAT', [:dot, :graphml],
                'Specify FORMAT of graph (dot, graphml)',
                'Default: dot') do |f|
          options.format = f
        end

        opts.on('-o', '--output FILE',
                'Write output to FILE instead of stdout') do |o|
          options.output = o
        end
      end

      begin
        opts.parse!(arguments)
      rescue OptionParser::InvalidOption,
             OptionParser::InvalidArgument,
             OptionParser::MissingArgument => e
        abort "#{e.message.capitalize}\n#{opts}"
      end

      options
    end

    def default_options
      opts = OpenStruct.new
      opts.graph = :installed;
      opts.format = :dot;
      opts
    end

    def installed
      @installed ||= %x[brew list].split("\n")
    end

    def deps_all
      data = {}
      all = %x[brew deps --all].split("\n")
      all.each do |s|
        node,deps = s.split(":")
        data[node] = deps.nil? ? nil : deps.strip.split(" ")
      end
      data
    end
end

class Dot
  def to_graph(data)
    dot = []
    dot << 'digraph G {'
    data.each_key do |node|
      dot << create_node(node)
    end
    data.each_pair do |source, targets|
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
  def to_graph(data)
    out = []
    out << header
    out << '  <graph edgedefault="directed" id="G">'
    data.each_key do |node|
      out << create_node(node)
    end
    data.each_pair do |source, targets|
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
end

brew = BrewGraph.new(ARGV)
brew.run
