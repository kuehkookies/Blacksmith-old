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

  def update; end

end

class Bridge < GameObject
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
	$game_bridges << self
		
    # @color = Color.new(0xff808080)
    cache_bounding_box
  end
end

class Decoration < GameObject  
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
	#~ $game_decorations << self
  end
end

class Ground < Block; end
class GroundLower < Block; end
class GroundLoop < Block; end

class BridgeGray < Block; end
class BridgeGrayLeft < Block; end
class BridgeGrayRight < Block; end
class BridgeGrayMid < Block; end

class BridgeGraySmall < Bridge; end
class BridgeGrayLeftSmall < Bridge; end
class BridgeGrayRightSmall < Bridge; end
class BridgeGrayMidSmall < Bridge; end

class GroundBack < Decoration;  def setup; super; @color = Color.new(0xff808080); end; end
class BridgeGrayPole < Decoration; end
class BridgeGrayPoleSmall < Decoration; end
class BridgeGrayLL < Decoration; end
class BridgeGrayLR < Decoration; end

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