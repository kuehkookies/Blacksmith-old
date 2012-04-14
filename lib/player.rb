# ------------------------------------------------------
# Le Player
# Animated
# ------------------------------------------------------
class Player < Chingu::GameObject
	attr_reader 	:direction, :invincible, :maxhp, :status, :action, :last_x # , :running, :sword
	attr_accessor	:hp, :ammo, :wp_level, :subweapon
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
		# @animations = Chingu::Animation.new( :file => "player/mark-small.png", :size => [24,24])
		@animations.frame_names = {
			:stand => 0..1,
			:step => 2..2,
			:walk => 3..10,
			:jump => 11..13,
			:hurt => 14..16,
			:die => 16..16,
			:crouch => 17..18,
			:stead => 19..19,
			:shoot => 20..22,
			:crouch_shoot => 23..26,
			:raise => 27..29
		}
		@animations[:walk].delay = 65
		@image = @animations[:stand].first
		@speed = 2 # 2
		@hp = @maxhp = 16
		@ammo = 05
		@wp_level = 1
		@status = :stand
		@action = :stand
		@invincible = false
		@jumping = false
		@running = false
		@subattack = false
		@subweapon = :none
		
		self.zorder = 250
		# @acceleration_y = 0.5
		@acceleration_y = Environment::GRAV_ACC # 0.3
		@max_velocity = Environment::GRAV_CAP # 6 # 8
		self.rotation_center = :bottom_center
		
		@last_x, @last_y = @x, @y
		@y_flag = @y
		# update
		cache_bounding_box
	end
	
	def stand
		unless @status == :jump or @status == :hurt or die? or @y != @y_flag or @action != :stand
			@image = @animations[:stand].first
			@status = :stand
			@running = false
			@jumping = false
		end
	end
	
	def move_left
		return if (@action == :attack && @status == :stand && @velocity_y < Environment::GRAV_WHEN_LAND + 1 ) || @status == :crouch || die? || @status == :stead || @action == :raise || (@status == :hurt and moved?) || @action == :raise 
		move(-@speed, 0) unless (@status == :hurt and moved?) or @action == :raise
	end
	
	def move_right
		return if (@action == :attack && @status == :stand && @velocity_y < Environment::GRAV_WHEN_LAND + 1 ) || @status == :crouch || die? || @status == :stead || @action == :raise || (@status == :hurt and moved?) || @action == :raise
		move(@speed, 0) unless (@status == :hurt and moved?) or @action == :raise # @x += 1
	end
	
	def jump
		return if self.velocity_y > Environment::GRAV_WHEN_LAND # 1
		return if @status == :crouch or @status == :jump or @status == :hurt or die? or @action != :stand 
		@status = :jump
		@jumping = true
		# @velocity_x = -@speed if holding?(:left)
		# @velocity_x = @speed if holding?(:right)
		@velocity_y = -4
		during(250){
			if holding?(:z) && @jumping
				@velocity_y = -4 unless @velocity_y <=  -Environment::GRAV_CAP
			else
				@jumping = false
			end
		}
	end
	
	def crouch
		unless @status == :jump or disabled or @action == :attack
			@image = @animations[:crouch].first
			@status = :crouch
		end
		if @action == :attack # && (@y - @y_flag > 20 && @status == :jump)
			@image = @animations[:crouch_shoot].last
		end
	end
	
	def steady
		unless @status == :jump or disabled or @action == :attack
			@image = @animations[:stead].first
			@status = :stead
		end
	end
	
	def land
		@jumping = false
		if (@y - @y_flag > 40 or (@y - @y_flag > 20 && @status == :jump) ) && @status != :die
			Sound["sfx/step.wav"].play
			between(1,300) { 
				@status = :crouch; crouch
			}.then { 
				if !die?; @status = :stand; @image = @animations[:stand].first; end
			}
			# @y_flag = @y
		else
			if @status == :jump
				@image = @animations[:stand].first unless Sword.size >= 1
				@status = :stand 
			elsif @velocity_y >= Environment::GRAV_WHEN_LAND + 1 # 2
				@image = @animations[:stand].first unless Sword.size >= 1
				@velocity_y = Environment::GRAV_WHEN_LAND # 1
			end
		end
		@velocity_x = 0
	end
	
	def knockback(damage)
		@status = :hurt
		@invincible = true
		@sword.destroy if @sword != nil
		Sound["sfx/grunt.ogg"].play(0.8)
		@hp -= damage # 3
		@hp = 0 if @hp <= 0
		# self.velocity_x = (self.factor_x*-@speed)
		self.velocity_x = (self.factor_x*-1)
		# self.velocity_y = -5
		self.velocity_y = -3
		land?
	end
	
	def hurt
		self.velocity_x = 0
		if !die?
			between(1,500) { 
				@status = :crouch; crouch
			}.then { @status = :stand; @image = @animations[:stand].first}
			between(500,2000){@color.alpha = 128}.then{@invincible = false; @color.alpha = 255}
		else
			between(1,120) { 
				crouch
			}.then { 
				@status = :die; @image = @animations[:die].first
				game_state.after(1000) { $window.switch_game_state($window.map.current) }
			}
		end
	end
	
	def land?
		self.each_collision($game_terrains) do |me, stone_wall|
			if self.velocity_y < 0  # Hitting the ceiling
				me.y = stone_wall.bb.bottom + me.image.height * me.factor_y
				me.velocity_y = 0
			else  # Land on ground
				if @status == :hurt
					hurt
				else
					land
				end
				me.velocity_y = Environment::GRAV_WHEN_LAND # 1
				me.y = stone_wall.bb.top - 1 # unless me.y > stone_wall.y
			end
		end
	end
	
	def die?
		return false if @hp > 0
		return true if @hp <= 0
	end
	
	def disabled
		@status == :hurt or @status == :die
	end
	
	def weapon_up
		raise
	end
	
	def move(x,y)
		# @image = @animations[:walk].next  if x != 0 && @status != :jump # && !holding_any?(:x)
		if x != 0 && @status != :jump
			@image = @animations[:step].first if !@running
			@image = @animations[:walk].next if @running
			# after(50) { @running = true if !@running and x != 0; @running = true if x == 0 }
			after(50) { @running = true if !@running }
		end
		
		@image = @animations[:hurt].first  if @status == :hurt
		@image = @animations[:raise].first  if @action == :raise
		
		unless @action == :attack || @status == :hurt
			self.factor_x = self.factor_x.abs   if x > 0
			self.factor_x = -self.factor_x.abs  if x < 0
		end
		
		@x += x unless @action == :raise
		self.each_collision($game_terrains) do |me, stone_wall|
			@x = previous_x 
			break
		end
			
		@y += y
		# after(2000) {@running = true if !@running }
		# @running = true if !@running
	end
	
	def check_last_direction
		if @x == @last_x && @y == @last_y or @subattack
			@direction = [self.factor_x*(2), 0]
		else
			@direction = [@x - @last_x, @y - @last_y]
		end
		@last_x, @last_y = @x, @y
	end
	
	def raise
		# unless @wp_level >= 3
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
	
	def fire
		unless disabled or @action == :raise
			if holding?(:up) and @subweapon != :none
				unless @action == :attack || @status == :crouch || @ammo == 0 || Knife.size >= 1 || Axe.size >= 1 || Rang.size >= 1 
					@action = :attack
					@subattack = true					
					between(1,50){@image = @animations[:shoot].first}
					.then	{@image = @animations[:shoot].next}
					after(150) { @image = @animations[:shoot].next
							factor_x = (self.factor_x^0)
							@ammo -= 1
							case @subweapon
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
							@image = @animations[:shoot].next
							@image = @animations[:crouch_shoot].next if @status == :crouch 
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
							@image = @animations[:shoot].last
							@image = @animations[:crouch_shoot].last if @status == :crouch 
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
						unless @action == :raise
							@sword.die
							@action = :stand
							@status = :stand if @status == :stead
							unless disabled
								@image = @animations[:stand].first if @status == :stand or @status == :stead
								@image = @animations[:crouch].first if @status == :crouch
								@image = @animations[:jump].last if @status == :jump
							end
							@animations[:shoot].reset
							@animations[:crouch_shoot].reset
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
			else
				@image = @animations[12] if @velocity_y <= 2
				@image = @animations[:jump].last if @velocity_y > 2
			end
		end
		check_last_direction
		if @velocity_y > Environment::GRAV_WHEN_LAND + 1 && @status != :jump && @action == :stand
			@image = @animations[12] if @velocity_y <= 3
			@image = @animations[:jump].last if @velocity_y > 3
		end
		self.each_collision(Rang) do |me, weapon|
			weapon.die
		end
		@y_flag = @y if @velocity_y == Environment::GRAV_WHEN_LAND # 1
		@wp_level = 3 if @wp_level > 3
	end
end