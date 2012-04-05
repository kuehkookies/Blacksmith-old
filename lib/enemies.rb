# ------------------------------------------------------
# Le Ball
# Don't stop me now!
# ------------------------------------------------------
class Enemy < GameObject
	traits :collision_detection, :effect, :velocity, :timer
	attr_reader :invincible, :hp, :damage, :harmful
	
	def setup
		@player = parent.player
		@invincible = false
		@harmful = true
		self.zorder = 200
		@gap_x = @x - @player.x
		@gap_y = @y - @player.y
		@last_x, @last_y = @x, @y
		$game_enemies << self
	end
	
	def hit(weapon)
		unless die?
			# Spark.create(:x => self.x+((self.bb.width*3/5)*-@player.factor_x), :y => self.y-(self.height*1/5), :angle => 30*@player.factor_x)
			Spark.create(:x => self.x, :y => self.y-@player.height*1/4, :angle => 30*@player.factor_x)
			Sound["sfx/hit.wav"].play(0.5)
			@hp -= weapon.damage
			die
		end
	end
	
	def die
		destroy
	end
	
	def die?
		return @hp <= 0
	end
	
	def destroyed?
		return true if self == nil
	end
	
	def harmful?
		return @harmful
	end
	
	def land?
		self.each_collision($game_terrains) do |me, stone_wall|
			if self.velocity_y < 0  # Hitting the ceiling
				me.y = stone_wall.bb.bottom + me.image.height * me.factor_y
				me.velocity_y = 0
			else  
				me.velocity_y = Environment::GRAV_WHEN_LAND
				me.y = stone_wall.bb.top - 1 unless me.y > stone_wall.y
			end
		end
	end
	
	def check_collision
		self.each_collision(Sword, Axe, Rang, Knife) do |enemy, weapon|
			unless enemy.invincible
				enemy.hit(weapon)
				weapon.die if weapon.is_a?(Knife)
			end
		end
		self.each_collision(@player) do |enemy, me|
			me.knockback(@damage) unless me.invincible or enemy.die? or !enemy.harmful? # or (enemy.is_a? Enemy and enemy.hp <= 0)
		end
	end
	
	# def update
		# self.each_collision(@player) do |enemy, me|
			# me.knockback unless me.invincible or enemy.die? # or (enemy.is_a? Enemy and enemy.hp <= 0)
		# end
	# end
end

class Ball < Enemy
	trait :bounding_box, :debug => false
	def setup
		super
		@image = Image["enemies/ball.png"]
		@hp = 1
		@damage = 1
		@harmful = false
		cache_bounding_box
	end
	
	def die
		if @hp <= 0
			during(150){ 
				self.collidable = false; @factor_x += 0.1; @factor_y += 0.1; @color.alpha -= 10 
			}.then {
				destroy
				i = rand(1)
				case i
					when 0
					# Ammo.create(:x => self.x, :y => self.y)
					# when 1
					#~ Item_Knife.create(:x => self.x, :y => self.y)
					# when 2
					# Item_Axe.create(:x => self.x, :y => self.y)
					# when 3
					# Item_Rang.create(:x => self.x, :y => self.y)
					# when 4
					Item_Sword.create(:x => self.x, :y => self.y)
				end
			} 
		else
			@invincible = true
			dir = self.velocity_x
			self.velocity_x *= 0
			after(400) { @invincible = false; self.velocity_x = dir}
		end
	end
	
	def update
		check_collision
	end
end

# ------------------------------------------------------
# Raven
# ------------------------------------------------------
class Raven < Enemy
	trait :bounding_box, :debug => false
	
	def setup
		super
		@animations = Chingu::Animation.new( :file => "enemies/raven.png", :size => [16,16])
		@animations.frame_names = {:idle => 0..0, :flutter => 1..3}
		@image = @animations[:idle].first
		@max_velocity = 5
		@acceleration_y = 0
		@hp = 1
		@damage = 2
		cache_bounding_box
		# @gap_x = @x - @player.x
		# @gap_y = @y - @player.y
		wait
	end
	
	def wait
		self.velocity_x = 0
		self.velocity_y = 0
		self.factor_x = -@gap_x/(@gap_x.abs).abs
		unless @flutter != nil
		every(500){ 
			if @gap_x > -150 and @gap_x < 150 and @flutter == nil
				during(300) { @image = @animations[:flutter].next; self.velocity_x = 0.5*self.factor; self.velocity_y = -0.5 }.then {flutter}
			end
			}
		end
	end
	
	def dive(flip, dist, alt)
		return if @hp <= 0
		dist_scale = (dist/20)
		alt_scale = (alt/20)
		dist_scale = 3 if dist_scale.abs.to_i < 3
		self.velocity_x = dist_scale.abs.to_i < 4 ? dist_scale.abs*flip : 4*flip
		self.velocity_x *= -1
		self.velocity_y = alt_scale.abs.to_i < 4 ? alt_scale.abs : 4
		during(1000) { @image = @animations[:flutter].first; self.velocity_y -= 0.1; self.velocity_y = -3 if self.velocity_y < -3 }.then {flutter}
		# between(1, 750) {self.velocity_y -= 0.02*self.velocity_y}
	end
	
	def flutter
		return if @hp <= 0
		@flutter = true
		if @flutter
			self.velocity_x = 0
			self.velocity_y = 0
				every(200) {
				@gap_x = @x - @player.x
				@gap_y = @y - @player.y
				@gap_x = self.factor_x if @gap_x == 0
				self.factor_x = -@gap_x/(@gap_x.abs).abs
			}
			after(3000) { @flutter = false;	dive(-self.factor_x, @gap_x, @gap_y) }
		end
	end
	
	def update
		super
		unless @flutter != nil
			@gap_x = @x - @player.x
			@gap_y = @y - @player.y
		end
		@image = @animations[:flutter].next if @flutter
		@image = @animations[:flutter].first if !@flutter
		@image = @animations[:idle].first if @flutter == nil
		destroy if self.parent.viewport.outside_game_area?(self)
		check_collision
	end
	
	def die
		if @hp <= 0
			@flutter = false
			self.velocity_x = 0 if self.velocity_x != 0 
			self.velocity_y = 0 if self.velocity_y != 0 
			self.collidable = false
			self.factor_y = -1
			# self.velocity_x = self.velocity_x
			self.velocity_y = 0.5
			self.velocity_x = 0.2*-self.factor
			@acceleration_y = 0
			i = rand(2)
			case i
				when 1
				Ammo.create(:x => self.x, :y => self.y)
			end
			after(300) {
				destroy
			}
		end
	end
end

# ------------------------------------------------------
# Ghouls
# ------------------------------------------------------
class Ghoul < Enemy
	trait :bounding_box, :scale => [0.2, 0.7], :debug => false
	def setup
		super
		@animations = Chingu::Animation.new(:file => "enemies/ghouls.png", :size => [32,32])
		@sword = Ghoul_Sword.create(:x => @x+(3*-@factor), :y => (@y-6), :velocity => @direction, :factor_x => -@factor, :zorder => self.zorder + 1)
		@animations.frame_names = {
			:walk => 0..3,
			:attack => 4..5
		}
		@animations[:walk].delay = 150
		@animations[:walk].bounce = true
		@speed = 0.25
		@hp = 6
		@damage = 3
		@action = :idle
		@acceleration_y = Environment::GRAV_ACC
		@max_velocity = Environment::GRAV_CAP # 8
		@velocity_y = 2
		self.rotation_center = :bottom_center
		@image = @animations[:walk].first
		@factor_x = -@gap_x/(@gap_x.abs).abs
		cache_bounding_box
	end
	
	def attack
		@action = :attack
		@animations[:walk].reset
		between(0,200){
			unless die?
				@image = @animations[:attack].first
				@sword.x, @sword.y = @x+(3*@sword.factor_x), @y-11
			end
		}.then{
			unless die?
				@image = @animations[:attack].last
				@sword.x, @sword.y = @x+(14*@sword.factor_x), @y-13
			end
		}
		after(500){
			unless die?
				@image = @animations[:walk].first
				@sword.x, @sword.y = @x+(3*@sword.factor_x), @y-6
			end
		}
		after(1000){@action = :walk unless die?}
	end
	
	def update
		super
		
		@gap_x = @x - @player.x
		@gap_y = @y - @player.y
		if @gap_x < 0 #and @action != :attack
			@factor_x = 1 unless @action == :attack
		else
			@factor_x = -1 unless @action == :attack
		end
		
		land?
		destroy if self.parent.viewport.outside_game_area?(self)
		check_collision
		
		if @gap_x.abs < 32 and @gap_y.abs < 16
			attack unless @action == :attack
		end
		
		unless die? or @action == :attack
			@sword.x = @x+(3*@sword.factor_x)
			@sword.y = @y-6 if @velocity_y > Environment::GRAV_WHEN_LAND
			@sword.factor_x = @factor_x
			# @sword.bb.x = @sword.x
			# @sword.bb.x += @sword.width if @factor_x == -1
		end
		@animations.on_frame(0){@sword.y = @y-6 unless die? }
		@animations.on_frame(1){@sword.y = @y-7 unless die? }
		@animations.on_frame(2){@sword.y = @y-7 unless die? }
		@animations.on_frame(3){@sword.y = @y-6 unless die? }
		
		if @action != :attack
			if (@x - @last_x).abs > 1
				@x += 0
				unless die? or @action == :attack
					@sword.x = @x+(3*@sword.factor_x)
					@sword.y = @y-6 
				end
				after(400){
					@last_x = @x
					@image = @animations[:walk].first if @velocity_y > Environment::GRAV_WHEN_LAND
				}
			else
				unless self.velocity_y > Environment::GRAV_WHEN_LAND or @invincible or @gap_x.abs < 32
					@image = @animations[:walk].next
					@x += @speed*@factor_x
				end
				@image = @animations[:walk].first if @velocity_y > Environment::GRAV_WHEN_LAND
			end
		end
	end
	
	def die
		# pause!
		if @hp <= 0
			i = rand(2)
			case i
				when 1
				Ammo.create(:x => self.x, :y => self.y)
			end
			@sword.die
			@x += 0
			@y += 0
			@color.alpha = 128
			after(300){destroy}
		else
			@invincible = true
			after(400) { @invincible = false; } # unpause! }
		end
	end
end

# ------------------------------------------------------
# Musket
# ------------------------------------------------------
class Musket < Enemy
	trait :bounding_box, :scale => [0.4, 0.9], :debug => false
	def setup
		super
		@animations = Chingu::Animation.new(:file => "enemies/musket.png", :size => [30,24])
		@animations.frame_names = {
			:aim =>  0..2,
			:shoot => 3..3,
			:reload => 4..5,
			:die => 6..9
		}
		@animations[:aim].delay = 150
		@animations[:shoot].delay = 50
		@animations[:reload].delay = 200
		@animations[:reload].bounce = true
		@animations[:die].delay = 75
		@animations[:die].loop = false
		@hp = 3
		@damage = 2
		
		@acceleration_y = 0.3
		@max_velocity = 6 # 8
		self.rotation_center = :bottom_center
		
		@shooting = false
		@idle = true
		@image = @animations[:aim].first
		self.factor_x = -@gap_x/(@gap_x.abs).abs
		cache_bounding_box
		wait
	end
	
	def wait
		@shooting = false
		if @idle
			@image = @animations[:aim].first unless @hp <= 0
			every(1000) {
				if @gap_y.abs < 60 and @gap_x.abs < 200 and !@shooting 
					@idle = false	
					during(300){@image = @animations[:aim].next unless @hp <= 0}.then {@image = @animations[:aim].last unless @hp <= 0}
					after(750){shoot unless @hp <= 0; @shooting = true}
				end
			}
		end
	end
	
	def shoot
		unless @hp <= 0
			@image = @animations[:shoot].first
			Sound["sfx/rifle.ogg"].play(0.3)
			# Shot.create(:x => self.x+14*self.factor_x, :y => self.y+4, :factor_x => self.factor_x)
			# Bullet_Musket.create(:x => self.x+14*self.factor_x, :y => self.y+4, :factor_x => self.factor_x)
			Shot.create(:x => self.x+14*self.factor_x, :y => self.y-9, :factor_x => self.factor_x)
			Bullet_Musket.create(:x => self.x+14*self.factor_x, :y => self.y-9, :factor_x => self.factor_x)
			after(100){@image = @animations[:aim].last}
			after(1000){
				unless @hp <= 0
					@image = @animations[:shoot].first
					Sound["sfx/rifle.ogg"].play(0.3)
					# Shot.create(:x => self.x+14*self.factor_x, :y => self.y+4, :factor_x => self.factor_x)
					# Bullet_Musket.create(:x => self.x+14*self.factor_x, :y => self.y+4, :factor_x => self.factor_x)
					Shot.create(:x => self.x+14*self.factor_x, :y => self.y-9, :factor_x => self.factor_x)
					Bullet_Musket.create(:x => self.x+14*self.factor_x, :y => self.y-9, :factor_x => self.factor_x)
				end
			}
			after(1100){reload}
		end
	end
	
	def reload
		@image = @animations[:reload].first unless @hp <= 0
		# during(750){@image = @animations[:reload].next unless @hp <= 0}.then {@image = @animations[:aim].first unless @hp <= 0; wait; @idle = true}
		during(1000){@image = @animations[:reload].next unless @hp <= 0}.then {@image = @animations[:aim].first unless @hp <= 0; wait; @idle = true}
	end
	
	def update
		super
		land?
		@gap_x = @x - @player.x
		@gap_y = @y - @player.y
		check_collision
	end
	
	def die
		pause! unless @hp <= 0
		if @hp <= 0
			@image = @animations[:die].first
			@shooting = false
			@idle = false
			i = rand(2)
			case i
				when 1
				Ammo.create(:x => self.x, :y => self.y)
			end
			during(300) {@image = @animations[:die].next}.then {
				@image = @animations[:die].last
			}
			after(500){
				destroy
			}
		else
			@invincible = true
			after(400) { @invincible = false; self.unpause! }
		end
	end
end