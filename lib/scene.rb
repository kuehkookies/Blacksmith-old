# ------------------------------------------------------
# Le Scene
# self titled
# ------------------------------------------------------
class Scene < GameState
	traits :viewport, :timer
	attr_reader :player, :terrain

	def initialize
		super
		#~ self.input = { :escape => :exit, :e => :edit, :r => :restart, :space => Pause }
		@player = Player.create()
		@hud = HUD.create(:player => @player)
	end
	
	def setup
		self.input = { :escape => :exit, :e => :edit, :r => :restart, :space => Pause }
		#~ @player = Player.create(:x => 64, :y => 240)
		@file = File.join(ROOT, "#{self.class.to_s.downcase}.yml")
		clear_cache
		game_objects.select { |game_object| !game_object.is_a? Player }.each { |game_object| game_object.destroy }
		load_game_objects(:file => @file)
	end
	
	def draw
		#~ @backdrop.draw
		@hud.draw
		super
	end
	
	def edit
		push_game_state(GameStates::Edit.new(:grid => [16,16], :classes => [Ground, GroundLower, GroundLoop, BridgeGray, BridgeGrayLeft, BridgeGrayRight, BridgeGrayPole, BridgeGrayMid, Ghoul] ))
	end
	
	def clear_cache
		$game_enemies = []
		$game_hazards = []
		$game_terrains = []
		$game_items = []
		$game_subweapons = []
	end
	
	def restart
		#~ clear_game_states
		#~ @backdrop.destroy if @backdrop != nil
		#~ @hud.destroy
		switch_game_state($window.map.current)
		#~ switch_game_state(Zero)
		#~ push_game_state(Zero)
		#~ after(500){push_game_state($window.map.current)}
		#~ after(500){pop_game_state}
	end
	
	def update
		super
		$game_enemies.each { |enemy| 
			if enemy.paused?
				after(500) {enemy.unpause!}
			end
		}
		self.viewport.center_around(@player)
		@hud.update
		$window.caption = "Le Trial, FPS: #{$window.fps}, #{@player.action}, #{@player.status}, #{@player.velocity_y.to_i}"
	end
end

class Level00 < Scene
	def setup
		super
		self.viewport.game_area = [0,0,592,288]
		@player.x = 64
		@player.y = 192
		@backdrop = Parallax.new(:x => 0, :y => 0, :rotation_center => :top_left, :zorder => 10)
		@backdrop.add_layer(:image => "parallax/panorama1-1.png", :damping => 10, :repeat_x => true, :repeat_y => false)
		@backdrop.add_layer(:image => "parallax/bg1-1.png", :damping => 1, :repeat_x => true, :repeat_y => false)
	end
	
	def draw
		@backdrop.draw
		super
	end
	 
	def update
		super
		@backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i
		@backdrop.camera_x, @backdrop.camera_y = self.viewport.x, self.viewport.y
		@backdrop.update
	end
end

class Zero < Scene
	def setup
		super
		@player.x = 0
		@player.y = 0
	end
	
	def update
		after(500) {switch_game_state($window.map.current)}
	end
end
