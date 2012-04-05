# ------------------------------------------------------
# Le Ball
# Don't stop me now!
# ------------------------------------------------------
class Items < GameObject
  trait :bounding_box, :debug => false
  traits :collision_detection, :velocity, :timer
	
	def setup
		@image = Image["items/#{self.filename}.png"]
		@player = parent.player
		@acceleration_y = 0.5
		@max_velocity = 8
		self.zorder = 300
		self.rotation_center = :bottom_center
		$game_items << self
		cache_bounding_box
	end
	
	def update
		unless destroyed?
			self.each_collision(Brick, Gravel) do |me, stone_wall|
				unless me.y > stone_wall.y
					me.y = stone_wall.bb.top - 1
					@acceleration_y = 0
				end
			end
			@player.each_collision(self) do |me, item|
				unless destroyed?
				item.die # unless destroyed?
					if item.is_a?(Item_Sword)
						# parent.push_game_state(Pause_Event) unless @player.wp_level > 3
						$game_enemies.each { |enemy| 
							enemy.pause! unless @player.wp_level > 3 # or enemy.paused?
							# after(500) {enemy.unpause!}
						}
						# parent.push_game_state(Pause_Event) unless @player.wp_level > 3
						@player.wp_level = 3 if @player.wp_level > 3
					end
				end
			end
			after(3000) {self.destroy}
		end
	end
	
	def destroyed?
		return true if self == nil
	end
	
	def die
		Sound["sfx/klang.wav"].play(0.3)
		self.destroy
	end
end

class Ammo < Items
	def setup; super; @color = Color.new(0xff00ff00); end
	def die; @player.ammo += 1; @player.ammo = 99 if @player.ammo > 99; super; end
end

class Item_Sword < Items
	def setup; super; end
	def die
		unless @player.status == :hurt
			super
			@player.wp_level += 1
			@player.weapon_up unless @player.wp_level > 3
		end
	end
end

class Item_Knife < Items
	def setup; super; end
	def die; super; @player.subweapon = :knife; end
end

class Item_Axe < Items
	def setup; super; end
	def die; super; @player.subweapon = :axe; end
end

class Item_Rang < Items
	def setup; super; end
	def die; super; @player.subweapon = :rang; end
end