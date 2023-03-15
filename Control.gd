extends Control

const VU_CNT = 16.0
const FRQMAX = 12000.0
const w = 500
const h = 120
const MIN_DB = 60

var spectrum: AudioEffectInstance

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(1,0) # (Дорожка, номер эффекта)

func _process(delta):
	update()

func _draw():
	var colw = w / VU_CNT
	var prev_hz = 0
	for i in range(1, VU_CNT + 1):
		var hz = i * FRQMAX / VU_CNT
		var mag: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clamp((MIN_DB + linear2db(mag)) / MIN_DB, 0, 1)
		var colh = energy * h
		draw_rect(Rect2(colw * i + 20, h - colh+60, colw*0.95, colh * 2), Color.palevioletred)
		prev_hz = hz
