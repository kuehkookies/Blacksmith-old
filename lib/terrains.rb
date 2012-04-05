# ------------------------------------------------------
# Le Block
# When you need place to place your foot
# ------------------------------------------------------

class Block < GameObject
  trait :bounding_box, :scale => [1,0.9], :debug => false
  trait :collision_detection
  
  def self.solid
    all.select { |block| block.alpha == 128 }
  end

  def self.inside_viewport
    all.select { |block| block.game_state.viewport.inside?(block) }
  end

  def setup
    # @image = Image["block-block.png"]
    # @image = Image["block-#{self.filename}.png"].dup
    @image = Image["tiles/block-#{self.filename}.png"]
		$game_terrains << self
		
    # @color = Color.new(0xff808080)
    cache_bounding_box
  end
end

class Brick < Block; end
class Gravel < Block; end

# class Brick < Block
	# def setup
    # @image = Image["block-brick.png"]
    # cache_bounding_box
  # end
# end

# class Gravel < Block
  # def setup
    # @image = Image["block-gravel.png"]
    # cache_bounding_box
  # end
# end

# class Tile < Block
	# def setup
		# @image = Image["tile1-1.png"]
	# end
# end