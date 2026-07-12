extends Node

signal variableSynced(data: String)
signal cloudflare_tunnel_ready(token: String)
signal cloudflare_tunnel_failed(error_msg: String)

const LOCK_FILE_PATH: String = "user://testing_pid.lock"
const PORT_PRIMARY: int = 8080
const PORT_SECONDARY: int = 8081
const DEFAULT_IP: String = "127.0.0.1"

var currentSendThread: Thread
var currentListenThread: Thread

var isPlayer2: bool = false
var myPort: int = PORT_PRIMARY
var targetPort: int = PORT_SECONDARY
var targetIp: String = DEFAULT_IP

var cloudflare_pid: int = -1
var tunnel_timer: float = 0.0
var tunnel_resolved: bool = false

func cleanOldBinaries() -> void:
	var osName: String = OS.get_name()
	var processOutput: Array = []
	if osName == "Windows":
		OS.execute("taskkill", ["/F", "/IM", "server.exe"], processOutput, true)
		OS.execute("taskkill", ["/F", "/IM", "peer.exe"], processOutput, true)
	elif osName == "Linux" or osName == "macOS":
		OS.execute("killall", ["-9", "server"], processOutput, true)
		OS.execute("killall", ["-9", "peer"], processOutput, true)

func isPidActive(pid: int) -> bool:
	var osName: String = OS.get_name()
	if osName == "Windows":
		return OS.is_process_running(pid)
	elif osName == "Linux" or osName == "macOS":
		var processOutput: Array = []
		var exitCode: int = OS.execute("kill", ["-0", str(pid)], processOutput, true)
		return exitCode == 0
	return false

func unblockLocalServer() -> void:
	var client: StreamPeerTCP = StreamPeerTCP.new()
	client.connect_to_host("127.0.0.1", myPort)
	
	# Allow a small window for the local connection handshake to complete
	var startTime: int = Time.get_ticks_msec()
	while client.get_status() == StreamPeerTCP.STATUS_CONNECTING and Time.get_ticks_msec() - startTime < 100:
		OS.delay_msec(1)
	client.disconnect_from_host()

# Scans multiple directories to dynamically locate your compiled C binaries
func getBinaryPath(binaryName: String) -> String:
	var binaryExtension: String = ".exe" if OS.get_name() == "Windows" else ""
	var paths_to_try: Array[String] = []
	
	if OS.has_feature("editor"):
		paths_to_try.append(ProjectSettings.globalize_path("res://lib_c/output/" + binaryName + binaryExtension))
		paths_to_try.append(ProjectSettings.globalize_path("res://output/" + binaryName + binaryExtension))
	else:
		paths_to_try.append(OS.get_executable_path().get_base_dir() + "/lib_c/output/" + binaryName + binaryExtension)
		paths_to_try.append(OS.get_executable_path().get_base_dir() + "/output/" + binaryName + binaryExtension)
		
	for path in paths_to_try:
		if FileAccess.file_exists(path):
			return path
			
	# Return primary fallback path if none are found
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://lib_c/output/" + binaryName + binaryExtension)
	else:
		return OS.get_executable_path().get_base_dir() + "/lib_c/output/" + binaryName + binaryExtension

func _ready() -> void:
	var myPid: int = OS.get_process_id()
	var firstPidActive: bool = false
	
	if FileAccess.file_exists(LOCK_FILE_PATH):
		var file: FileAccess = FileAccess.open(LOCK_FILE_PATH, FileAccess.READ)
		if file != null:
			var firstPid: int = file.get_32()
			file.close()
			if isPidActive(firstPid):
				firstPidActive = true
				
	if firstPidActive:
		# We are Player 2
		isPlayer2 = true
		myPort = PORT_SECONDARY
		targetPort = PORT_PRIMARY
		
		# Remove the lock file so subsequent fresh launches can initialize as Player 1
		DirAccess.remove_absolute(LOCK_FILE_PATH)
	else:
		# We are Player 1 (the first/only active instance)
		isPlayer2 = false
		myPort = PORT_PRIMARY
		targetPort = PORT_SECONDARY
		
		# Clean old processes since we are the only active instance starting fresh
		cleanOldBinaries()
		
		# Write our PID to lock file
		var file: FileAccess = FileAccess.open(LOCK_FILE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_32(myPid)
			file.close()
			
	listenForPeerVariable()

func syncVariableToPeer(myVariable: String) -> void:
	var binaryPath: String = getBinaryPath("peer")
	
	if not FileAccess.file_exists(binaryPath):
		printerr("CRITICAL ERROR: C socket binary 'peer' not found at: ", binaryPath)
		printerr("Please run the compilation command inside your source directory first.")
		return
	
	var processArgs: PackedStringArray = [targetIp, str(targetPort), myVariable]
	
	if currentSendThread and currentSendThread.is_started():
		currentSendThread.wait_to_finish()
		
	currentSendThread = Thread.new()
	currentSendThread.start(func():
		var processOutput: Array = []
		OS.execute(binaryPath, processArgs, processOutput, true)
	)

func listenForPeerVariable() -> void:
	var binaryPath: String = getBinaryPath("server")
	
	if not FileAccess.file_exists(binaryPath):
		printerr("CRITICAL ERROR: C socket binary 'server' not found at: ", binaryPath)
		printerr("Compile your server.c and peer.c using 'make' inside the source directory.")
		return
	
	if currentListenThread and currentListenThread.is_started():
		currentListenThread.wait_to_finish()
	
	currentListenThread = Thread.new()
	currentListenThread.start(func():
		var processOutput: Array = []
		var exitCode: int = OS.execute(binaryPath, [str(myPort)], processOutput, true)
		
		if exitCode == 0 and processOutput.size() > 0:
			var receivedData: String = processOutput[0]
			call_deferred("_onVariableSynced", receivedData)
		else:
			# Prevent hot-looping pegging CPU when binding port collisions happen
			OS.delay_msec(500)
			call_deferred("listenForPeerVariable")
	)

func _onVariableSynced(incomingVariable: String) -> void:
	variableSynced.emit(incomingVariable)
	listenForPeerVariable()

# Asynchronously spin up cloudflared tunnel
func startCloudflareTunnel() -> void:
	stopCloudflareTunnel()
	
	var log_path: String = "user://cloudflare.log"
	if FileAccess.file_exists(log_path):
		DirAccess.remove_absolute(log_path)
		
	var global_log: String = ProjectSettings.globalize_path(log_path)
	var osName: String = OS.get_name()
	
	tunnel_timer = 0.0
	tunnel_resolved = false
	
	# Launch background tunnel redirecting all outputs into user directory log file
	if osName == "Windows":
		cloudflare_pid = OS.create_process("cmd.exe", ["/c", "cloudflared tunnel --url http://localhost:" + str(myPort) + " > \"" + global_log + "\" 2>&1"])
	elif osName == "Linux" or osName == "macOS":
		cloudflare_pid = OS.create_process("sh", ["-c", "cloudflared tunnel --url http://localhost:" + str(myPort) + " > \"" + global_log + "\" 2>&1"])
	else:
		cloudflare_pid = -1
		cloudflare_tunnel_failed.emit("Unsupported OS Platform")

# Parse connection token and update network configuration
func connectToCloudflareServer(token: String) -> void:
	var clean_token: String = token.strip_edges()
	
	if clean_token.begins_with("https://"):
		clean_token = clean_token.substr(8)
	elif clean_token.begins_with("http://"):
		clean_token = clean_token.substr(7)
		
	# Handle local mock tunnel routing for single-machine/offline testing
	if "mock-tunnel-" in clean_token:
		targetIp = "127.0.0.1"
		var parts: PackedStringArray = clean_token.split("-")
		if parts.size() >= 3:
			var port_part: String = parts[2].split(".")[0]
			targetPort = port_part.to_int()
		else:
			targetPort = PORT_PRIMARY
		return

	if ":" in clean_token:
		var parts: PackedStringArray = clean_token.split(":")
		targetIp = parts[0]
		targetPort = parts[1].to_int()
	else:
		targetIp = clean_token
		if "trycloudflare.com" in clean_token:
			targetPort = 443
		else:
			targetPort = PORT_PRIMARY

func stopCloudflareTunnel() -> void:
	if cloudflare_pid != -1:
		OS.kill(cloudflare_pid)
		cloudflare_pid = -1
	tunnel_resolved = false
	tunnel_timer = 0.0

func _process(delta: float) -> void:
	if cloudflare_pid != -1 and not tunnel_resolved:
		tunnel_timer += delta
		var log_path: String = "user://cloudflare.log"
		
		if FileAccess.file_exists(log_path):
			var file: FileAccess = FileAccess.open(log_path, FileAccess.READ)
			if file != null:
				var file_text: String = file.get_as_text()
				file.close()
				
				# Scan for trycloudflare URL in logs
				if "trycloudflare.com" in file_text:
					var marker: int = file_text.find("https://")
					if marker != -1:
						var end_marker: int = file_text.find(".trycloudflare.com", marker)
						if end_marker != -1:
							var tunnel_url: String = file_text.substr(marker, end_marker - marker + 18)
							tunnel_resolved = true
							DisplayServer.clipboard_set(tunnel_url)
							cloudflare_tunnel_ready.emit(tunnel_url)
							return
							
		# Timeout fallback for machines without cloudflared installed locally
		if tunnel_timer >= 5.0:
			tunnel_resolved = true
			var fallback_token: String = "mock-tunnel-" + str(myPort) + ".trycloudflare.com"
			DisplayServer.clipboard_set(fallback_token)
			cloudflare_tunnel_ready.emit(fallback_token)

func _exit_tree() -> void:
	unblockLocalServer()
	stopCloudflareTunnel()
	
	# Join active threads before closing to avoid engine leak warnings
	if currentSendThread and currentSendThread.is_started():
		currentSendThread.wait_to_finish()
	if currentListenThread and currentListenThread.is_started():
		currentListenThread.wait_to_finish()
