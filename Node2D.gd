extends Node2D

var sound = null

func _on_Button_pressed():
	$FileDialog.popup()

func _on_FileDialog_file_selected(path):
	if $AudioStreamPlayer.playing:
		$AudioStreamPlayer.stop()
	var file = File.new()
	file.open(path, File.READ)
	var bytes = file.get_buffer(file.get_len())
	if ".wav" in path:
		# следующий кусок кода анализирует заголовок файла wav для правильного воспроизведения
		# данный фрагмент предлагается оставить на будущее, так как он не входит в процесс обучения ввиду сложности кодирования.
		sound = AudioStreamSample.new()
		var bits_per_sample = 0
		for i in range(0, 100):
			var those4bytes = str(char(bytes[i])+char(bytes[i+1])+char(bytes[i+2])+char(bytes[i+3]))
			if those4bytes == "RIFF": 
				print ("RIFF OK at bytes " + str(i) + "-" + str(i+3))
				#RIP bytes 4-7 integer for now
			if those4bytes == "WAVE": 
				print ("WAVE OK at bytes " + str(i) + "-" + str(i+3))
			if those4bytes == "fmt ":
				print ("fmt OK at bytes " + str(i) + "-" + str(i+3))
				var formatsubchunksize = bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)
				var fsc0 = i+8 #fsc0 is byte 8 after start of "fmt "
				var format_code = bytes[fsc0] + (bytes[fsc0+1] << 8)
				var format_name
				if format_code == 0: format_name = "8_BITS"
				elif format_code == 1: format_name = "16_BITS"
				elif format_code == 2: format_name = "IMA_ADPCM"
				else: 
					format_name = "UNKNOWN (trying to interpret as 16_BITS)"
					format_code = 1
				sound.format = format_code
				var channel_num = bytes[fsc0+2] + (bytes[fsc0+3] << 8)
				if channel_num == 2: sound.stereo = true
				var sample_rate = bytes[fsc0+4] + (bytes[fsc0+5] << 8) + (bytes[fsc0+6] << 16) + (bytes[fsc0+7] << 24)
				sound.mix_rate = sample_rate
				var byte_rate = bytes[fsc0+8] + (bytes[fsc0+9] << 8) + (bytes[fsc0+10] << 16) + (bytes[fsc0+11] << 24)
				var bits_sample_channel = bytes[fsc0+12] + (bytes[fsc0+13] << 8)
				bits_per_sample = bytes[fsc0+14] + (bytes[fsc0+15] << 8)
			if those4bytes == "data":
				assert(bits_per_sample != 0)
				var audio_data_size = bytes[i+4] + (bytes[i+5] << 8) + (bytes[i+6] << 16) + (bytes[i+7] << 24)
				var data_entry_point = (i+8)
				var data = bytes.subarray(data_entry_point, data_entry_point+audio_data_size-1)
				if bits_per_sample in [24, 32]:
					sound.data = convert_to_16bit(data, bits_per_sample)
				else:
					sound.data = data
		var samplenum = sound.data.size() / 4
		sound.loop_end = samplenum
		sound.format = AudioStreamSample.FORMAT_16_BITS
		sound.stereo = true
	elif ".ogg" in path:
		sound = AudioStreamOGGVorbis.new()
		sound.data = bytes
	elif ".mp3" in path:
		sound = AudioStreamMP3.new()
		sound.data = bytes
	file.close()
	$AudioStreamPlayer.stream = sound

func _on_Play_pressed():
	$AudioStreamPlayer.play()

func _on_Stop_pressed():
	$AudioStreamPlayer.stop()


func convert_to_16bit(data: PoolByteArray, from: int) -> PoolByteArray:
	print("converting to 16-bit from %d" % from)
	var time = OS.get_ticks_msec()
	# 24 bit .wav's are typically stored as integers
	# so we just grab the 2 most significant bytes and ignore the other
	if from == 24:
		var j = 0
		for i in range(0, data.size(), 3):
			data[j] = data[i+1]
			data[j+1] = data[i+2]
			j += 2
		data.resize(data.size() * 2 / 3)
	# 32 bit .wav's are typically stored as floating point numbers
	# so we need to grab all 4 bytes and interpret them as a float first
	if from == 32:
		var spb := StreamPeerBuffer.new()
		var single_float: float
		var value: int
		for i in range(0, data.size(), 4):
			spb.data_array = data.subarray(i, i+3)
			single_float = spb.get_float()
			value = single_float * 32768
			data[i/2] = value
			data[i/2+1] = value >> 8
		data.resize(data.size() / 2)
	print("Took %f seconds for slow conversion" % ((OS.get_ticks_msec() - time) / 1000.0))
	return data
