class HUD < Chingu::BasicGameObject
	# include Chingu
	def initialize(options={})
		super
		@player = options[:player] || parent.player
		@x = options[:x]; @y = options[:y]
		@old_hp = @player.hp
		@hud = Image["misc/hud.png"]
		@sub = Image["misc/hud_#{@player.subweapon}.png"] unless @player.subweapon == :none
		@ammo = Text.new(@player.ammo, :x => 36, :y => 55, :zorder => 300, :align => :right, :max_width => 16, :size => 16, :color => Color.new(0xFFDADADA), :font => "fonts/runescape_uf_regular.ttf")
		@rect = Rect.new(45,23,168,10)
		@gap = (@rect.width - 168*@player.hp/@player.maxhp).to_f
	end
	
	def draw
		@hud.draw(15,15,300)
		@sub.draw(21,24,301) unless @sub == nil
		# @bar.draw
		# @life.draw
		@ammo.draw
		# @sub.draw
		# parent.fill_rect(Rect.new(45,23,168,10), Color.new(128,40,40,40), 150)
		# @rect = Rect.new(45,23,168*@player.hp/@player.maxhp,10)
		parent.fill_gradient(:from => Color.new(255,20,20), :to => Color.new(160,20,20), :rect => @rect, :orientation => :vertical, :zorder => 290 )
	end
	
	def update
		# @life.text = @player.hp.to_s unless @player.hp.to_s == @life.text
		# @sub.text = @player.subweapon.to_s unless @player.subweapon.to_s == @sub.text
		@sub = Image["misc/hud_#{@player.subweapon}.png"] unless @player.subweapon == @sub or @player.subweapon == :none
		@ammo.text = @player.ammo.to_s unless @player.ammo.to_s == @ammo.text
		if @player.hp < @old_hp
			unless @rect.width <= 168*@player.hp/@player.maxhp
				@rect.width -= 4 if @gap > 4
				@rect.width -= 2 if @gap <= 4 and @gap > 2
				@rect.width -= 1 if @gap <= 2
			end
		end
	end
end