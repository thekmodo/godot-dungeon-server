extends CanvasLayer

@onready var host_button: Button = $Panel/VBox/RowHost/HostButton
@onready var join_button: Button = $Panel/VBox/RowJoin/JoinButton
@onready var host_edit: LineEdit = $Panel/VBox/RowJoin/Host
@onready var port_edit: LineEdit = $Panel/VBox/RowJoin/JoinPort
@onready var host_port_edit: LineEdit = $Panel/VBox/RowHost/Port
@onready var invite_edit: LineEdit = $Panel/VBox/InviteRow/Invite
@onready var status_label: Label = $Panel/VBox/Status
@onready var metrics_label: Label = $Panel/VBox/Metrics

@onready var net: Node = $"../Net"

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	net.status_changed.connect(_on_status_changed)
	net.metrics_changed.connect(_on_metrics_changed)

func _on_host_pressed() -> void:
	var port := int(host_port_edit.text)
	var invite := invite_edit.text
	net.host_local(port, invite)

func _on_join_pressed() -> void:
	var host := host_edit.text
	var port := int(port_edit.text)
	var invite := invite_edit.text
	net.join_remote(host, port, invite)

func _on_status_changed(text: String) -> void:
	status_label.text = "Status: %s" % text

func _on_metrics_changed(ping_ms: float, jitter_ms: float) -> void:
	metrics_label.text = "Ping: %.0fms   Jitter: %.0fms" % [ping_ms, jitter_ms]

