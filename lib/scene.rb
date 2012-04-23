# ------------------------------------------------------
# Le Scene
# self titled
# ------------------------------------------------------
class Scene < GameState
	traits :viewport, :timer
	attr_reader :player, :terrain, :area, :backdrop

	def initialize
		super
		self.input = { :escape => :exit, :e => :edit, :r => :restart, :space => Pause }
		@backdrop = Parallax.new(:rotation_center => :top_left, :zorder => 10)
		player_start
		@player.sword = nil
		@area = [0,0]
		@file = File.join(ROOT, "#{self.class.to_s.downcase}.yml")
		$window.clear_cache
		game_objects.select { |game_object| !game_object.is_a? Player }.each { |game_object| game_object.destroy }
		load_game_objects(:file => @file) unless self.class.to_s == "Zero"
		#~ between(200,400) {
		#~ @player.move_right
		#~ }.then { @player.stand_still; $window.stop_transferring }
		after(350) { $window.stop_transferring }
		#~ @song = Gosu::Song.new("media/bgm/silence-of-daylight.ogg")
		#~ @song.volume = 0.3
		#~ @song.play(true)
		#~ p "same" if $window.map.current_level == $window.level - 1
		#~ $game_bgm = Gosu::Song.new("media/bgm/#{Module_Game::BGM[$window.level-1]}.ogg", :volume => 0.3)
		#~ p "#{Module_Game::BGM[$window.map.current_level]}.ogg"
		#~ p "#{Module_Game::BGM}"
		@hud.update
	end
	
	def draw
		#~ @backdrop.draw
		@hud.draw unless @hud == nil
		super
	end
	
	def edit
		# Bridges
		#~ push_game_state(GameStates::Edit.new(:grid => [16,16], :classes => [BridgeGray, BridgeGrayLeft, BridgeGrayRight, BridgeGrayPole, BridgeGrayLL, BridgeGrayLR, BridgeGrayMid] ))
		# Small Bridges
		#~ push_game_state(GameStates::Edit.new(:grid => [16,16], :classes => [Ground, GroundLower, GroundLoop, GroundBack, BridgeGraySmall, BridgeGrayLeftSmall, BridgeGrayRightSmall, BridgeGrayPoleSmall, BridgeGrayMidSmall] ))
		# Grounds
		push_game_state(GameStates::Edit.new(:grid => [16,16], :classes => [Ground, GroundLower, GroundLoop, GroundBack, Ball, Zombie, Reaper, Ball_Knife] ))
	end
	
	def restart
		switch_game_state($window.map.first_block)
		$window.block = 1
	end
	
	def player_start
		#~ @player = $game_player == nil ?  Player.create() : $game_player
		@player = Player.create()
		@hud = HUD.create(:player => @player) if @hud == nil
		#~ after(100){@player.status = :stand; @player.action = :stand}
		@player.reset_state
	end
	
	def to_next_block
		@player.status = :blink
		@player.sword.die if @player.sword != nil
		$window.transferring
		#~ $window.block += 1
		switch_game_state($window.map.next_block)
		$window.block += 1
		#~ after(100) { $window.stop_transferring }
	end
	
	def to_next_level
		@player.status = :blink
		@player.sword.die if @player.sword != nil
		$window.transferring
		#~ $window.block += 1
		switch_game_state($window.map.next_level)
		$window.level += 1
		$window.block  = 1
		#~ after(100) { $window.stop_transferring }
	end
	
	#~ def solid_pixel_at?(x, y)
		#~ begin     
		  #~ @backdrop.layers.last.get_pixel(x, y)[3] != 0
		#~ rescue
		  #~ puts "Error in get_pixel(#{x}, #{y})"
		#~ end
	#~ end
	
	#~ def solid?
		#~ return solid_pixel_at?(@player.x, @player.y) && solid_pixel_at?(@player.x + 1, @player.y)
	#~ end
	
	def update
		super
		#~ update_trait
		self.viewport.center_around(@player)
		$game_enemies.each { |enemy| 
			if enemy.paused?
				after(500) {enemy.unpause!}
			end
		}
		Knife.destroy_if {|knife| 
			knife.x > self.viewport.x + $window.width + $window.width/8 or 
			knife.x < self.viewport.x - + $window.width/8 or 
			self.viewport.outside_game_area?(knife)
		}
		Axe.destroy_if {|axe| axe.y > self.viewport.y + $window.height or axe.x < self.viewport.x or axe.x > self.viewport.x + $window.width}
		Rang.destroy_if {|rang| self.viewport.outside_game_area?(rang) and rang.turn_back }
		if @player.y > self.viewport.y + $window.height
			@player.dead 
		end
		@hud.update
		#~ $window.caption = "Le Trial, FPS: #{$window.fps}, #{@player.action}, #{@player.status}, #{@player.x.to_i}:#{@player.y.to_i}[#{@player.y_flag}]"
		#~ $window.caption = "Le Trial, FPS: #{$window.fps}, #{@player.x.to_i}:#{@player.y.to_i}[#{@player.y_flag}] - #{@player.action} #{@player.status} - Level: #{$window.level}-#{$window.block}"
		#~ $window.caption = "Scene0, FPS: #{$window.fps}, #{@player.x.to_i}:#{@player.y.to_i}[#{@player.velocity_y.to_i}-#{@player.y_flag}]"
		$window.caption = "Scene0, FPS: #{$window.fps}, #{@player.status} | #{@player.action} -- #{$window.transfer} | #{$window.map.current_level}-#{$window.map.current_block} | #{$window.level}-#{$window.block}"
	end
end

class Level00 < Scene
	def initialize
		super
		#~ every(2000){@text = Text.create(:name => :woof, :text => "Woof!", :x=>@player.x, :y=>100, :size=>10, :zorder => 400)}
		@area = [800,288]
		@player.x = 32
		@player.y = 246
		@player.y_flag = @player.y
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		@backdrop << {:image => "parallax/panorama1-1.png", :damping => 10, :repeat_x => true, :repeat_y => false}
		@backdrop << {:image => "parallax/bg1-1.png", :damping => 1, :repeat_x => true, :repeat_y => false}
		@backdrop << {:image => "parallax/level00.png", :damping => 1}

		#~ $game_bgm = Gosu::Song.new("media/bgm/#{Module_Game::BGM[$window.level-1]}.ogg", :volume => 0.3)
		#~ $game_bgm.play(true)
		#~ @song = Gosu::Song.new("media/bgm/silence-of-daylight.ogg")
		#~ @song.volume = 0.3
		#~ @song.play(true)
	end
	
	def draw
		@backdrop.draw
		#~ fill_gradient(:from => Color.new(0xff444AFF), :to => Color.new(0xff444AFF), :zorder => -1)
		super
	end
	 
	def update
		super
		if @player.x >= @area[0]-(@player.bb.width) && (@player.y > 214 && @player.y < 216) # self.viewport.x+$window.width-(@player.bb.width/2)-1
			#~ @player.x = self.viewport.x+(@player.bb.width/2)
			#~ @player.status = :blink
			#~ @player.sword.die
			#~ $window.block += 1
			#~ switch_game_state($window.map.next_block)
			to_next_block
		end
		@backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i
		@backdrop.update
	end
end

class Level01< Scene	
	def initialize
		super
		@area = [592,288]
		@player.x = self.viewport.x+(@player.bb.width/2)
		@player.y = 215
		@player.y_flag = @player.y
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		#~ @backdrop = Parallax.new(:x => 0, :y => 0, :rotation_center => :top_left, :zorder => 10)
		@backdrop.add_layer(:image => "parallax/panorama1-1.png", :damping => 10, :repeat_x => true, :repeat_y => false)
		#~ @backdrop.add_layer(:image => "parallax/bg1-1.png", :damping => 1, :repeat_x => true, :repeat_y => false)
		#~ @song = Gosu::Song.new("media/bgm/silence-of-daylight.ogg")
		#~ @song.volume = 0.3
		#~ @song.play(true)
		every(2000){Zombie.create(:x => $window.width + self.viewport.x, :y => 215)}
	end

	def draw
		@backdrop.draw
		#~ fill_gradient(:from => Color.new(0xff444AFF), :to => Color.new(0xff444AFF), :zorder => -1)
		super
	end
	 
	def update
		super
		if @player.x >= @area[0]-(@player.bb.width) && (@player.y > 214 && @player.y < 216) # self.viewport.x+$window.width-(@player.bb.width/2)-1
			#~ @player.x = self.viewport.x+(@player.bb.width/2)
			#~ @player.sword.die
			#~ $window.block += 1
			#~ switch_game_state($window.map.next_block)
			to_next_block
		end
		@backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i
		@backdrop.update
	end
end

class Level02 < Scene
	def initialize
		super
		@area = [384,288]
		@player.x = self.viewport.x+(@player.bb.width/2)
		@player.y = 263
		@player.y_flag = @player.y
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		#~ @backdrop = Parallax.new(:x => 0, :y => 0, :rotation_center => :top_left, :zorder => 10)
		#~ @song = Gosu::Song.new("media/bgm/level03-binding.ogg")
		#~ @song.volume = 0.3
		#~ @song.play(true)
	end
	
	def draw
		@backdrop.draw
		super
	end
	 
	def update
		super
		if @player.x >= @area[0]-(@player.bb.width) # self.viewport.x+$window.width-(@player.bb.width/2)-1
			#~ @player.x = self.viewport.x+(@player.bb.width/2)
			#~ @player.status = :blink
			#~ @player.sword.die
			#~ $window.block += 1
			#~ switch_game_state($window.map.next_block)
			to_next_level
		end
		@backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i
		@backdrop.update
	end
end

class Level10 < Scene
	def initialize
		super
		#~ every(2000){@text = Text.create(:name => :woof, :text => "Woof!", :x=>@player.x, :y=>100, :size=>10, :zorder => 400)}
		@area = [800,288]
		@player.x = 32
		@player.y = 246
		@player.y_flag = @player.y
		self.viewport.game_area = [0,0,@area[0],@area[1]]
		@backdrop << {:image => "parallax/panorama1-1.png", :damping => 10, :repeat_x => true, :repeat_y => false}
		@backdrop << {:image => "parallax/bg1-1.png", :damping => 1, :repeat_x => true, :repeat_y => false}
		@backdrop << {:image => "parallax/level00.png", :damping => 1}

		#~ $game_bgm = Gosu::Song.new("media/bgm/#{Module_Game::BGM[$window.level-1]}.ogg", :volume => 0.3)
		#~ $game_bgm.play(true)
		#~ @song = Gosu::Song.new("media/bgm/silence-of-daylight.ogg")
		#~ @song.volume = 0.3
		#~ @song.play(true)
	end
	
	def draw
		@backdrop.draw
		#~ fill_gradient(:from => Color.new(0xff444AFF), :to => Color.new(0xff444AFF), :zorder => -1)
		super
	end
	 
	def update
		super
		if @player.x >= @area[0]-(@player.bb.width) && (@player.y > 214 && @player.y < 216) # self.viewport.x+$window.width-(@player.bb.width/2)-1
			#~ @player.x = self.viewport.x+(@player.bb.width/2)
			#~ @player.status = :blink
			#~ @player.sword.die
			#~ $window.block += 1
			#~ switch_game_state($window.map.next_block)
			to_next_block
		end
		@backdrop.camera_x, @backdrop.camera_y = self.viewport.x.to_i, self.viewport.y.to_i
		@backdrop.update
	end
end