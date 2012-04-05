# ------------------------------------------------------
# Le Scene
# self titled
# ------------------------------------------------------
class Scene < GameState
	traits :viewport, :timer
	attr_reader :player, :terrain

	def initialize
		super
		self.input = { :escape => :exit, :e => :edit, :r => :restart, :space => Pause }
		@player = Player.create(:x => 64, :y => 240)
	end
	
	def setup
		@file = File.join(ROOT, "#{self.class.to_s.downcase}.yml")
		game_objects.select { |game_object| !game_object.is_a? Player }.each { |game_object| game_object.destroy_all }
		load_game_objects(:file => @file)
	end
	
	def draw
		#~ @backdrop.draw
		#~ @hud.draw if @hud != nil
		super
	end
	
	def edit
		push_game_state(GameStates::Edit.new(:grid => [24,24], :classes => [Brick, Gravel, Ball, Ghoul, Raven, Musket]))
	end
	
	def restart
		#~ clear_game_states
		@backdrop.destroy if @backdrop != nil
		#~ @hud.destroy
		switch_game_state($window.map.current)
		#~ switch_game_state(Zero)
		#~ after(500){switch_game_state($window.map.current)}
	end
	
	def update
		super
		$game_enemies.each { |enemy| 
			if enemy.paused?
				after(500) {enemy.unpause!}
			end
		}
		self.viewport.center_around(@player)
		#~ @backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i
		#~ @backdrop.camera_x, @backdrop.camera_y = self.viewport.x, self.viewport.y
		#~ @backdrop.update
		#~ @hud.update if @hud != nil
		$window.caption = "Le Trial, FPS: #{$window.fps}, #{@player.action}, #{@player.status}"
	end
end

class Level00 < Scene
	def setup
		super
		self.viewport.game_area = [0,0,600,300]
		@player.x = 64
		@player.y = 256
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

class Zero < Scene; end
