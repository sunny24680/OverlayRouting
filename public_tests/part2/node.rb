require 'csv'
require 'socket'
require 'io/console'
require 'thread'
require_relative 'structs'
require_relative 'IO'
require_relative 'clock'
require_relative 'global'
require_relative 'djikstra'

# --------------------- Part 1 --------------------- # 

def edgeb(cmd)
	#puts ("#{dst}")
	src_ip = cmd[0]
	dst_ip = cmd[1]
	dst_name = cmd[2]

	#somehow check if the dst is a neighbor of this node 
	#fail silently if this isnt true/

	port = $nodes[dst_name].port

	#initilizng cost and ip of the node 
	dst = $nodes[dst_name]
	dst.name = dst_name
	dst.ip= dst_ip
	dst.cost= 1

	#opening socket for communciation to dst from src
	#puts "IP = #{port.to_i.class} #{dst_ip.class}"
	dst_sock = TCPSocket.open(dst_ip, port.to_i)
	#puts ("#{dst_sock}")
	if dst_sock 
		dst_sock.puts ("EDGEB #{src_ip} #{$hostname}")
	end
	dst.sock = dst_sock
	dst.nextHop = dst

	#adding it to the host nodes neighboring
	$neighbors[dst_name] = dst

	#update overall routing table after any change in topology 
	lsp()
end

def dumptable(cmd)
	fname = cmd[0].split("./")[1]
	#puts ("#{fname}")
	File.open(fname, "w") do |f|
  		$routingTable.keys.sort.each do |name|
  			str = $hostname + "," + name + "," + $routingTable[name].nextHop + "," +$routingTable[name].cost.to_s
  			f.write(str);
  		end
  	end
  	# ...
end

def shutdown(cmd)
	$server.close
	STDOUT.flush
	STDERR.flush
	exit(0)
end



# --------------------- Part 2 --------------------- # 
def edged(cmd)
	puts ("before delete #{$neighbors}")
	#$neighbors[cmd[0]].sock.close
	$neighbors[cmd[0]].sock = nil
	$neighbors.delete(cmd[0])
	puts ("AFTER #{$neighbors}")
	#updatae overall routing table after any change in topology 
	lsp()
end

def edgeu(cmd)
	#only called when valid 
	dst_name = cmd[0]
	cost = cmd[1]

	#check for missing input
	if !dst_name.empty? && !cost.empty?
		#check for invalid input
		if (dst_name.is_a? String) && (cost.to_i.is_a? Integer)
			$neighbors[dst_name].cost = cost
		end
	end
	puts ("#{$neighbors}")
	puts ("#{$nodes}")
	$neighbors[dst_name].sock.puts("UPDATING")
	#updatae overall routing table after any change in topology 
	lsp()
end

def status()
	puts ("Name: #{$hostname}")
	puts ("Port: #{$port}")
	nString = "Neighbors: "
	$neighbors.keys.sort.each do |name|
		nString << name.name+","
	end
	nString = nString.chomp(",")
	puts ("#{nString}")
end

# --------------------- Part 3 --------------------- # 
def sendmsg(cmd)
	STDOUT.puts "SENDMSG: not implemented"
end

def req_ping(cmd)
	dst = cmd[0]
	numPings = cmd[1]
	delay = cmd[2]
	for i in 0..numPings 
		sendOn = $routingTable[name]
		sendOn.sock.puts("REQ_PING #{$hostname} #{dst} #{Time.new} #{i}")
		sleep $updateInterval	
	end
end

def resp_ping(name)
	if 
	$routingTable[name].sock.puts
end

def traceroute(cmd)
	STDOUT.puts "TRACEROUTE: not implemented"
end

# --------------------- Part 4 --------------------- # 


def ftp(cmd)
	STDOUT.puts "FTP: not implemented"
end

def circuit(cmd)
	STDOUT.puts "CIRCUIT: not implemented"
end

# ----------------- Extra Methods --------------------#


# do main loop here.... 
def main()

	while(line = STDIN.gets())
		line = line.strip()
		arr = line.split(' ')
		cmd = arr[0]
		args = arr[1..-1]
		case cmd
		when "EDGEB"; edgeb(args)
		when "EDGED"; edged(args)
		when "EDGEU"; edgeu(args)
		when "DUMPTABLE"; dumptable(args)
		when "SHUTDOWN"; shutdown(args)
		when "STATUS"; status()
		when "SENDMSG"; sendmsg(args)
		when "PING"; req_ping(args)
		when "TRACEROUTE"; traceroute(args)
		when "FTP"; ftp(args);
		when "CIRCUIT"; circuit(args);
		else STDERR.puts "ERROR: INVALID COMMAND \"#{cmd}\""
		end
	end

end

def setup(hostname, port, nodes, config)
	$hostname = hostname
	$port = port

	#set up ports, server, buffers
	/
		stores all nodes and their ports in hash
		reading from nodes file
	/
	File.open(nodes).each do |line| 
		arr = line.split(",")
		name = arr[0]
		port = arr[1]

		$nodes[name] = Node.new(name, port.to_i)
	end
	$cur = $nodes[$hostname]
	#initilize config file
	File.open(config).each do |line|
		puts ("config file line = #{line}")
		arr = line.split("=")
		cmd = arr[0]
		value = arr[1].to_i
		puts ("value = #{value} : cmd = #{cmd}")

		case cmd 
		when "updateInterval"
			$updateInterval = value
		when "maxPayload"
			$maxPayload = value
		when "pingTimeout"
			$pingTimeout = value
		end
	end

	#calls IO file methods
	l_thread = Thread.new{listener()}
	r_thread = Thread.new{read()}

	#automatically update the routing table after interval 
	puts ("update = #{$updateInterval}"
	#make believe clock implementation
	pq = eventQ.new
	update_thread = Thread.new do
		while true
			sleep $updateInterval	
			pq.add("UPDATE")
		end
	end

	eventQueue = Thread.new do 
		while true 
			pq.run()
		end
	end

	main()

end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])