extends Node
## Small original electronic interface effects. All audio is generated locally:
## no downloaded songs, copyrighted samples or heavy music playback.

var players: Dictionary = {}
const SAMPLE_RATE := 22050

func _ready() -> void:
    players["pulse"] = _tone(.13,690.0,135.0,.22)
    players["tag"] = _tone(.25,470.0,1040.0,.20)
    players["shield"] = _tone(.24,250.0,105.0,.29)
    players["recharge"] = _tone(.33,310.0,680.0,.18)

func _tone(duration: float, start_hz: float, end_hz: float, volume: float) -> AudioStreamPlayer:
    var length := maxi(64,roundi(duration*float(SAMPLE_RATE)))
    var pcm := PackedByteArray()
    pcm.resize(length*2)
    var phase := 0.0
    var freq := start_hz
    for i in range(length):
        var t := float(i) / float(length)
        var env := pow(1.0-t,2.1)*minf(1.0, t*70.0)
        var jitter := sin(float(i)*.13)*.045
        freq = lerpf(start_hz,end_hz,t)
        phase += TAU*(freq+freq*jitter)/float(SAMPLE_RATE)
        var harmonic := .72*sin(phase)+.20*sin(phase*2.01)+.08*sin(phase*3.0)
        var value := clampi(roundi(harmonic*env*volume*32767.0),-32767,32767)
        pcm.encode_s16(i*2,value)
    var wav := AudioStreamWAV.new()
    wav.mix_rate = SAMPLE_RATE
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.stereo = false
    wav.data = pcm
    var player := AudioStreamPlayer.new()
    player.stream = wav
    player.volume_db = -7
    add_child(player)
    return player

func play_effect(effect: String) -> void:
    var player: AudioStreamPlayer = players.get(effect)
    if player != null:
        player.stop()
        player.play()
