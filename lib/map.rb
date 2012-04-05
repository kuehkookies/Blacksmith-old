class Map
  attr_reader :row, :col
  attr_accessor :map
  
  def initialize(options = {})
    @row = options[:row] || 0
    @col = options[:col] || 0    
    @map = options[:map] || [ [ ] ] 
  end
  
  def current
    @map[@row][@col] rescue nil
  end
    
  def next_block
    @col += 1
    current
  end

  def prev_block
    @col -= 1
    current
  end

  def next_stage
    @row -= 1
    current
  end

  def prev_stage
    @row += 1
    current
  end

end