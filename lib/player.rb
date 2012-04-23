# ------------------------------------------------------
# Le Player
# Animated
# ------------------------------------------------------
class Player < Chingu::GameObject
	attr_reader 	:direction, :invincible, :last_x # , :running, :sword
	attr_accessor	:y_flag, :sword, :status, :action, :running, :animations
	trait :bounding_box, :scale => [0.4, 0.8], :debug => false
	traits :timer, :collision_detection, :velocity
		
	# def initialize(option={})
	def setup
		# super
		self.input = {
			:holding_left => :move_left,
			:holding_right => :move_right,
			:holding_down => :crouch,
			:holding_up => :steady,
			[:released_left, :released_right, :released_down, :released_up] => :stand,
			:z => :jump,
			:x => :fire
		}
		@animations = Chingu::Animation.new( :file => "player/mark.png", :size => [32,32])
		@animations.frame_names = {
			:stand => 0..2,
			:step => 3..3,
			:walk => 4..11,
			:jump => 12..14,
			:hurt => 15..17,
			:die => 17..17,
			:crouch => 18..19,
			:stead => 20..20,
			:shoot => 21..23,
			:crouch_shoot => 24..27,
			:raise => 28..30
		}
		@animations[:stand].delay = 50
		@animations[:stand].bounce = true
		@animations[:walk].delay = 65
		@image = @animations[:stand].first
		@speed = 2 
		@status = :stand
		@action = :stand
		@invincible = false
		@jumping = false
		@vert_jump = false
		@running = false
		@subattack = false
		#~ @subweapon = :none
		
		self.zorder = 250
		# @acceleration_y = 0.5
		@acceleration_y =Module_Game::Environment::GRAV_ACC # 0.3
		@max_velocity = Module_Game::Environment::GRAV_CAP # 6 # 8
		self.rotation_center = :bottom_center
		
		every(2000){
			unless die?
				if @action == :stand && @status == :stand && @last_x == @x
					p "idle"
					during(150){
						@image = @animations[:stand].next
					}.then{@image = @animations[:stand].reset; @image = @animations[:stand].first}
					#~ @image = @animations[:stand].last
					#~ after(100){@image = @animations[:stand].first}
				end
			end
		}
		
		@last_x, @last_y = @x, @y
		@y_flag = @y
		# update
		cache_bounding_box
	end
	
	def reset_state
		@status = :stand; @action = :stand
		@sword = nil
		@invincible = false
		@jumping = false
		@vert_jump = false
		@running = false
		@subattack = false
	end
	
	def stand
		unless @status == :jump or disabled or die? or @y != @y_flag or @action != :stand
			@image = @animations[:stand].first
			@status = :stand
			@running = false
			@jumping = false
		end
	end
	
	def crouch
		unless @status == :jump or disabled or @action == :attack or die?
			@image = @animations[:crouch].first
			@status = :crouch
		end
	end
	
	def steady
		unless @status == :jump or disabled or @action == :attack or die?
			@image = @animations[:stead].first
			@status = :stead
		end
	end
	
	def land
		delay = 300
		delay = 400 if @action == :attack
		if (@y - @y_flag > 48 or (@y - @y_flag > 32 && @status == :jump ) ) && @status != :die
		#~ if (@y - @y_flag > 40) && @status != :die
			Sound["sfx/step.wav"].play
			between(1,delay) { 
				@status = :crouch; crouch
			}.then { 
				if !die?; @status = :stand; @image = @animations[:stand].first; end
			}
			# @y_flag = @y
		else
			if @status == :jump
				@image = @animations[:stand].first unless Sword.size >= 1
				@status = :stand 
			elsif @velocity_y >= Module_Game::Environment::GRAV_WHEN_LAND + 1 # 2
				@image = @animations[:stand].first unless Sword.size >= 1
				@velocity_y = Module_Game::Environment::GRAV_WHEN_LAND # 1
			end
		end
		@jumping = false if @jumping
		@vert_jump = false if !@jumping
		@velocity_x = 0
		@y_flag = @y
	end
	
	def move_left
		return if (@action == :attack && @status == :stand && @velocity_y < Module_Game::Environment::GRAV_WHEN_LAND + 1 ) || @status == :crouch || die? || @status == :stead || disabled || (@status == :hurt and moved?) || @action == :raise || @status == :blink
		move(-@speed, 0) # unless (@status == :hurt and moved?) or @action == :raise
	end
	
	def move_right
		return if (@action == :attack && @status == :stand && @velocity_y < Module_Game::Environment::GRAV_WHEN_LAND + 1 ) || @status == :crouch || die? || @status == :stead || disabled || (@status == :hurt and moved?) || @action == :raise || @status == :blink
		move(@speed, 0) # unless (@status == :hurt and moved?) or @action == :raise # @x += 1
	end
	
	def jump
		return if self.velocity_y > Module_Game::Environment::GRAV_WHEN_LAND # 1
		return if @status == :crouch or @status == :jump or @status == :hurt or die? or @action != :stand 
		@status = :jump
		@jumping = true
		jump_add = 0
		# @velocity_x = -@speed if holding?(:left)
		# @velocity_x = @speed if holding?(:right)
		#~ @velocity_y = -7
		@velocity_y = -4
		during(200){
			@vert_jump = true if !holding_any?(:left, :right)
			if holding?(:z) && @jumping && !disabled
				@velocity_y = -4  unless @velocity_y <=  -Module_Game::Environment::GRAV_CAP || !@jumping
			else
				@velocity_y = -1 unless !@jumping
			end
		}
	end
	
	def raise
		@action = :raise
		dir = [self.velocity_x, self.velocity_y]
		@image = @animations[:shoot].last
		@sword.die if @sword != nil
		factor = (self.factor_x^0)*(-1)
		self.velocity_x = self.velocity_y = @acceleration_y = 0
		@image = @animations[:raise].first
		@sword = Sword.create(:x => @x+(5*factor), :y => (@y-15), :factor_x => -factor, :angle => 90*factor)
		after(500) {@sword.die; @image = @animations[:stand].first; @image = @animations[:jump].last if @status == :jump; @action = :stand; self.velocity_x, self.velocity_y = dir[0], dir[1]; @acceleration_y = 0.3}
	end
	
	def at_edge?
		@x < (bb.width/2)  || @x > parent.area[0]-(bb.width/2) 
	end
	
	def disabled
		@status == :hurt or @status == :die
	end
	
	def weapon_up
		raise
	end
	
	def die?
		return false if $window.hp > 0
		return true if $window.hp <= 0
		#~ if $window.hp <= 0 or parent.outside_game_area(self)
			#~ $game_bgm.stop
			#~ return true 
		#~ end
	end
	
	def land?
		self.each_collision($game_terrains) do |me, stone_wall|
			if self.velocity_y < 0  # Hitting the ceiling
				me.y = stone_wall.bb.bottom + me.image.height * me.factor_y
				me.velocity_y = 0
				@jumping = false
			else  # Land on ground
				if @status == :hurt
					hurt
				else
					land
				end
				me.velocity_y = Module_Game::Environment::GRAV_WHEN_LAND # 1
				me.y = stone_wall.bb.top - 1 # unless me.y > stone_wall.y
			end
		end
		self.each_collision($game_bridges) do |me, bridge|
			if me.y < bridge.y && me.velocity_y >= 0
				if @status == :hurt
					hurt
				else
					land
				end
				me.velocity_y = Module_Game::Environment::GRAV_WHEN_LAND # 1
				me.y = bridge.bb.top - 1
			end
		end
	end

	def knockback(damage)
		@status = :hurt
		@action = :stand
		@invincible = true
		@sword.destroy if @sword != nil
		Sound["sfx/grunt.ogg"].play(0.8)
		$window.hp -= damage # 3
		$window.hp = 0 if $window.hp <= 0
		self.velocity_x = (self.factor_x*-1)
		self.velocity_y = -3
		land?
	end
	
	def hurt
		@velocity_x = 0
		@jumping = false
		if !die?
			between(1,500) { 
				@status = :crouch; crouch
			}.then { @status = :stand; @image = @animations[:stand].first}
			between(500,2000){@color.alpha = 128}.then{@invincible = false; @color.alpha = 255}
		else
			dead
		end
	end

	def dead
		$window.hp = 0
		$game_bgm.stop
		@sword.die if @sword != nil
		#~ between(1,120) { 
			#~ crouch
		@status = :die
		@image = @animations[:stand].last
		after(100){@image = @animations[16]}
		#~ }.then {
		after(200){
			@image = @animations[:die].first
			@x += 8*@factor_x unless @y > $window.height + parent.viewport.y
			game_state.after(1000) { 
				$window.transferring
				#~ $window.setup_player
				@sword.die if @sword != nil
				$window.switch_game_state($window.map.first_block)
				$window.setup_player
				reset_state
				#~ $window.push_game_state(Zero)
			}
		}
		$window.block = 1
		#~ $window.setup_player
		#~ reset_stats
	end
	
	def move(x,y)
		return if @status == :blink
		# @image = @animations[:walk].next  if x != 0 && @status != :jump # && !holding_any?(:x)
		if x != 0 && @status != :jump
			@image = @animations[:step].first if !@running
			@image = @animations[:walk].next if @running
			after(50) { @running = true if !@running }
		end
		
		@image = @animations[:hurt].first  if @status == :hurt
		@image = @animations[:raise].first  if @action == :raise
		
		unless @action == :attack || @status == :hurt
			self.factor_x = self.factor_x.abs   if x > 0
			self.factor_x = -self.factor_x.abs  if x < 0
		end
		
		unless @action == :raise
			@x += x if !@vert_jump
			@x += x/2 if @vert_jump
		end
		
		self.each_collision($game_terrains) do |me, stone_wall|
			@x = previous_x 
			break
		end
		@x = previous_x  if at_edge?
			
		@y += y
	end
	
	def check_last_direction
		if @x == @last_x && @y == @last_y or @subattack
			@direction = [self.factor_x*(2), 0]
		else
			@direction = [@x - @last_x, @y - @last_y]
		end
		@last_x, @last_y = @x, @y
	end
	
	def fire
		unless disabled or @action == :raise
			if holding?(:up) and $window.subweapon != :none
				unless @action == :attack || @status == :crouch || $window.ammo == 0 || Knife.size >= 1 || Axe.size >= 1 || Rang.size >= 1 
					@action = :attack
					@subattack = true					
					between(1,50){@image = @animations[:shoot].first}
					.then	{@image = @animations[:shoot].next}
					after(150) { @image = @animations[:shoot].next
							factor_x = (self.factor_x^0)
							#~ @ammo -= 1
							$window.ammo -= 1
							case $window.subweapon
								when :knife
									Knife.create(:x => @x+(10*factor_x), :y => @y-(self.height/2), :velocity => @direction, :factor_x => factor_x) unless Knife.size >= 1
								when :axe
									Axe.create(:x => @x+(8*factor_x), :y => @y-(self.height/2)-4, :velocity => @direction, :factor_x => factor_x) unless Axe.size >= 1
								when :rang
									Rang.create(:x => @x+(10*factor_x), :y => @y-(self.height/2), :velocity => @direction, :factor_x => factor_x) unless Rang.size >= 1
							end
							Sound["sfx/swing.wav"].play
							}
					after(250) { @image = @animations[:shoot].last}
					after(400) { 
						@action = :stand
						@status = :stand if @status == :stead
						unless disabled
							@image = @animations[:stand].first if @status == :stand or @status == :stead
							@image = @animations[:crouch].first if @status == :crouch
							@image = @animations[:jump].last if @status == :jump
						end
						@animations[:shoot].reset
						@animations[:crouch_shoot].reset
					}
				end
			else
				unless Sword.size >= 1
					@action = :attack
					@image = @animations[:shoot].first
					@image = @animations[:crouch_shoot].first if @status == :crouch
					factor = -(self.factor_x^0)
					@sword = Sword.create(:x => @x+(5*factor), :y => (@y-14), :velocity => @direction, :factor_x => -factor, :angle => 90*factor)
					between(1, 50) {
						unless disabled or @action == :raise
							@sword.x = @x+(7*factor)
							# @sword.y = (@y-12)
							@sword.y = (@y-(self.height/2)-3)
							@sword.y = (@y-(self.height/2)+2) if @status == :crouch or @status == :jump
							@sword.y = (@y-(self.height/2)+2) if @status == :jump
							@sword.angle = 120*factor
							@sword.velocity = @direction
						end
					}. then {
						Sound["sfx/swing.wav"].play
					}
					between(50,150) {
						unless disabled or @action == :raise
							@sword.x = @x+(7*factor)
							@sword.y = (@y-(self.height/2)-3)
							@sword.y = (@y-(self.height/2)+2) if @status == :crouch # or @status == :jump
							@sword.angle = 140*(factor)
							@sword.velocity = [0,0]
						end
					}.then {
						unless disabled or @action == :raise
							if @status == :crouch 
								@image = @animations[:crouch_shoot].next
							else
								@image = @animations[:shoot].next
							end
						end
						@sword.collidable = true
						#~ @sword.bb.width = (@sword.bb.width*4/5)
						@sword.bb.height = (@sword.bb.width)*-1
						@sword.angle = 130*(factor) unless @action == :raise
					}
					between(150,250) {
						unless disabled or @action == :raise
							# @sword.x = @x-(4*factor)
							@sword.x = @x-(9*factor)
							@sword.y = (@y-(self.height/2)-1)
							@sword.y = (@y-(self.height/2)+4) if @status == :crouch # or @status == :jump
							# @sword.angle = 45*(factor)
							@sword.angle -= 20*(factor)
							@sword.velocity = [0,0]
						end
					}.then {
						unless disabled or @action == :raise
							if @status == :crouch 
								@image = @animations[:crouch_shoot].last
							else
								@image = @animations[:shoot].last
							end
						end
						#~ @sword.bb.width = @sword.bb.width*14/12
						@sword.bb.height = ((@sword.bb.width*1/10))
					}
					between(250, 500) {
						unless disabled or @action == :raise
							@sword.zorder = self.zorder - 1
							@sword.x = @x-(13*factor)+((-1)*factor)
							@sword.x = @x-(11*factor)+((-1)*factor) if @status == :crouch
							# @sword.y = @y-10
							@sword.y = (@y-(self.height/2)+6)
							@sword.y = (@y-(self.height/2)+11) if @status == :crouch # or @status == :jump
							@sword.angle = 0*(factor)
							@image = @animations[:crouch_shoot].last if @status == :crouch
						end
					}.then {
						unless disabled or @action == :raise
							@sword.die
							@action = :stand
							unless disabled
								@image = @animations[:stand].first if @status == :stand or @status == :stead
								@image = @animations[:crouch].first if @status == :crouch
								@image = @animations[:jump].last if @status == :jump
							end
							@animations[:shoot].reset
							@status = :stand if @status == :stead || !holding?(:down)
							#~ @animations[:crouch_shoot].reset
						end
					}
				end
			end
		end
	end
	
	def update
		land?
		if @x == @last_x
			@running = false
			@animations[:walk].reset
		end
		if @status == :jump and @action == :stand
			if @last_y > @y 
				@image = @animations[:jump].first
				@image = @animations[13] if @vert_jump
			else
				@image = @animations[13] if @velocity_y <= 2
				@image = @animations[:jump].last if @velocity_y > 2
			end
		end
		check_last_direction
		if @velocity_y > Module_Game::Environment::GRAV_WHEN_LAND + 1 && @status != :jump && @action == :stand
			@image = @animations[13] if @velocity_y <= 3
			@image = @animations[:jump].last if @velocity_y > 3
		end
		self.each_collision(Rang) do |me, weapon|
			weapon.die
		end
		@y_flag = @y if @velocity_y == Module_Game::Environment::GRAV_WHEN_LAND && !@jumping # 1
	end
	
	def to_s
		puts "#{@running} #{@jumping} #{@vert_jump} #{@subattack} #{@invincible} #{@sword}"
	end
end