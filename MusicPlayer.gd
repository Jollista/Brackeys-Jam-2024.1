extends AudioStreamPlayer

func play_song(song:AudioStream):
	if song != stream:
		set_stream(song)
		play()
