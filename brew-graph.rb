require 'optparse'
require 'ostruct'

class BrewGraph

  def initialize(arguments)
    @arguments = arguments
  end
  
  def run
    options = parse_options
        
    nodes = send(options.graph)
    edges = edges_between(nodes)
    
    graph = case options.format
      when :dot then Dot.new.to_graph(nodes, edges)
      when :graphml then GraphML.new.to_graph(nodes, edges)
      else puts "Unknown format: #{options.format}"
      end      
      
    if options.output
      File.open(options.output, 'w') do |file|
        file.write(graph)
      end
    else
      puts graph
    end
  end
  
  private
  
    def parse_options      
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
        opts.parse!(@arguments)
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
    
    def all
      %x[brew search].split("\n")
    end
    
    def installed
      %x[brew list].split("\n")
    end
    
    def deps(formula)
      %x[brew deps #{formula}].split("\n")
    end
    
    def edges_between(nodes)
      edges = []
      nodes.each do |formula|
        deps(formula).each do |dependent|
          edges << [formula, dependent]
        end
      end
      edges
    end
end

class Dot
  def to_graph(nodes, edges)
    dot = []
    dot << 'digraph G {'
    nodes.each { |node| dot << create_node(node) }      
    edges.each { |edge| dot << create_edge(edge) }
    dot << '}'
    dot.join("\n")
  end
  
  private
  
    def create_node(node)
      %Q(  "#{node}";)
    end
    
    def create_edge(edge)
      %Q(  "#{edge[0]}" -> "#{edge[1]}";)
    end
end

class GraphML
  def to_graph(nodes, edges)
    out = []
    out << header
    out << '<graph edgedefault="directed" id="G">'
    nodes.each do |node|
      out << create_node(node)
    end
    edges.each do |edge|
      out << create_edge(edge)
    end
    out << '</graph>'
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
    
    def create_edge(edge)
      @edge_id ||= 0
      @edge_id += 1
<<-EOS
    <edge id="e#{@edge_id}" source="#{edge[0]}" target="#{edge[1]}">
      <data key="d1">
        <y:PolyLineEdge>
          <y:BendStyle smoothed="true"/>
        </y:PolyLineEdge>
      </data>
    </edge>
EOS
    end
end

brew = BrewGraph.new(ARGV)
brew.run