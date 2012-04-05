require 'rubygems' rescue nil
$LOAD_PATH.unshift File.join(File.expand_path(__FILE__), "..", "..", "lib")
require 'chingu'
require 'texplay'
include Gosu
include Chingu

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

$game_enemies = []
$game_hazards = []
$game_terrains = []
$game_items = []
$game_subweapons = []

# ------------------------------------------------------
# Le Main process
# Everything started here.
# ------------------------------------------------------
class Game < Chingu::Window
	attr_accessor :level, :lives, :map
	
	def initialize
		# super(544,416)
		# super(480,360)
		super(400,300)
		
		Sound["sfx/swing.wav"]
		Sound["sfx/klang.wav"]
		Sound["sfx/hit.wav"]
		Sound["sfx/grunt.ogg"]
		Sound["sfx/step.wav"]
		Sound["sfx/rifle.ogg"]
		
		# self.factor = 2
		retrofy # THE classy command!
		# push_game_state(Play)
		blocks = [
			[Level00] #level 0
		]
		@map = Map.new(:map =>blocks, :row => $window.level, :col => 0)
		switch_game_state(@map.current)
		# self.caption = "Le Trial"
	end
	
	def reset_game
		@level = 0
		@lives = 3
	end
	
	# def update
	# end
	
	# def draw
	# end
end

# This is is important.
Game.new.show
