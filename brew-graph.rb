require 'optparse'
require 'ostruct'

class BrewGraph

  def initialize(arguments)
    @arguments = arguments
  end
  
  def run
    options = parse_options
    
    graph = case options.format
      when :dot then Dot.to_graph(installed, edges)
      when :graphml then GraphML.to_graph(installed, edges)
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
      opts.format = :dot;
      opts
    end
    
    def installed
      %x[brew list].split("\n")
    end
    
    def deps(formula)
      %x[brew deps #{formula}].split("\n")
    end
    
    def edges
      edges = []
      installed.each do |formula|
        deps(formula).each do |dependent|
          edges << [formula, dependent]
        end
      end
      edges
    end
end

class Dot
  def self.to_graph(nodes, edges)
    dot = []
    dot << 'digraph G {'
    nodes.each { |node| dot << create_node(node) }      
    edges.each { |edge| dot << create_edge(edge) }
    dot << '}'
    dot.join("\n")
  end
  
  private
  
    def self.create_node(node)
      %Q(  "#{node}";)
    end
    
    def self.create_edge(edge)
      %Q(  "#{edge[0]}" -> "#{edge[1]}";)
    end
end

class GraphML
  require 'rubygems'  
  
  def self.to_graph(nodes, edges)
    xml = Builder::XmlMarkup.new( :indent => 2 )
    xml.instruct! :xml, :encoding => "UTF-8"
    xml.graphml('xmlns' => 'http://graphml.graphdrawing.org/xmlns') {
      xml.graph('id' => 'G', 'edgedefault' => 'directed') {
        nodes.each do |node|
          xml.node('id' => "#{node}")
        end
        edges.each do |edge|
          xml.edge('source' => edge[0], 'target' => edge[1])
        end
      }
    }
  end
  
  def self.const_missing(name)
    # Load the Builder gem on demand.
    if name == :Builder
      require 'builder'
      const_get(name)
    else
      super
    end
  end
end

brew = BrewGraph.new(ARGV)
brew.run