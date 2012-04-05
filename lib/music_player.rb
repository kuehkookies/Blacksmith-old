require 'sdl'

#Plays sound via SDL.
module DJ
	SoundVol = 75.0; MusicVol = 50.0
	Samples = {} #Links names to samples
	#Mute set by main
	include SDL
	
	def self.start
		SDL.init INIT_AUDIO
		Mixer.open	Mixer::DEFAULT_FREQUENCY, Mixer::DEFAULT_FORMAT, Mixer::DEFAULT_CHANNELS
		Mixer.set_volume_music MusicVol
	end
	start
	
	def self.play name #Play a WAV sound sample once.
		# return if Mute
		name = path "data/sound/#{name}.wav"
		sample = Samples.has_key?(name) ? Samples[name] : (Samples[name] = Mixer::Wave.load(name).set_volume MusicVol)
		#sample = DJ_SAMPLES[name]
		#if not sample #If never seen this sample before, load it up.
		#	sample = DJ_SAMPLES[name] = Mixer::Wave.load name
		#	sample.set_volume SOUND_VOL
		#end
		
		begin
			Mixer.play_channel -1, sample, 0 #Next available channel, 0 loops.
		rescue SDL::Error
			puts 'WARNING: DJ ran out of sound channels!'
		end
	end
	
	def self.play_music name #Play an OGG music file indefinitely
		# return if Mute
		# music = Mixer::Music.load path "data/music/#{name}.mid"
		music = Mixer::Music.load "media/bgm/#{name}.mid"
		Mixer.play_music music, -1
	end
	
	def self.stop
		#EDIT
	end
end