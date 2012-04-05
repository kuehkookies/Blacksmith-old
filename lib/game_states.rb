class Pause < GameState
	def initialize(options={})
		super
		self.input = {:space => :unpause}
		@color = Color.new(0x77000000)
	end
	def draw
		previous_game_state.draw
		$window.draw_quad(  0,0,@color,
										$window.width,0,@color,
										$window.width,$window.height,@color,
										0,$window.height,@color, Chingu::DEBUG_ZORDER)
	end
	def unpause
		pop_game_state(:setup => false)
	end
end

class Pause_Event < GameState
	traits :timer
	def initialize(options={}); super; end
	def draw
		previous_game_state.draw
		# after(500){ pop_game_state(:setup => false) }
	end
	def update
		after(500){ pop_game_state(:setup => false) }
	end
end