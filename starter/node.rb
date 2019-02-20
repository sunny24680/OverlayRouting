require 'csv'
require 'socket'
require 'io/console'
require 'thread'
require_relative 'structs'
require_relative 'IO'
require_relative 'global'
require_relative 'djikstra'
require_relative 'eventQ'

# --------------------- Part 1 --------------------- # 

def edgeb(cmd)
	#puts ("#{dst}")
	sleep 0.5
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
		$EQ.synchronize {
			$pq.insert(Time.new, Event.new("WRITE", [dst_sock, "EDGEB #{src_ip} #{$hostname}"]))
		}
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
  			str = $hostname + "," + name + "," + $routingTable[name].nextHop + "," +$routingTable[name].cost.to_s+"\n"
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
	#puts ("before delete #{$neighbors}")
	#$neighbors[cmd[0]].sock.close
	$neighbors[cmd[0]].sock = nil
	$neighbors.delete(cmd[0])
	#puts ("AFTER #{$neighbors}")
	#updatae overall routing table after any change in topology 
	lsp()
end

def edgeu(cmd)
	#only called when valid 
	#puts ("COMMAND = UPDATE EDGE")
	dst_name = cmd[0]
	cost = cmd[1]

	#check for missing input
	if !dst_name.empty? && !cost.empty?
		#check for invalid input
		if (dst_name.is_a? String) && (cost.to_i.is_a? Integer)
			$neighbors[dst_name].cost = cost
		end
	end
	#puts ("#{$neighbors}")
	#puts ("#{$table}")
	$neighbors[dst_name].sock.puts("UPDATING EDGE")
	#updatae overall routing table after any change in topology 
	lsp()
end

def status()
	puts ("Name: #{$hostname}")
	puts ("Port: #{$port}")
	nString = "Neighbors: "
	$neighbors.keys.sort.each do |name|
		nString << name+","
	end
	nString = nString.chomp(",")
	puts ("#{nString}")
end

# --------------------- Part 3 --------------------- # 
def sendmsg(cmd)
	dst = cmd[0]
	msg = ""
	for x in 1..cmd.length-1 do 
		msg += cmd[x] + " "
	end
	msg = msg[0..-2]
	#check if dst exists 
	if $routingTable.has_key?(dst)
		#fragment the message 
		messages = check_frag(msg, false)
		temp = $routingTable[dst]
		sendOn = $neighbors[temp.nextHop]
		for x in 0..messages.length-1 do
			#puts ("msg frag #{messages[x].moreFrag}")
			data = "SENDMSG #{dst} #{$hostname} #{messages[x].offset} #{messages[x].moreFrag} #{messages[x].msg}"
			writeTo(sendOn.sock, data)
		end
	else
		puts ("SENDMSG ERROR: HOST UNREACHABLE")
	end

	#might hav to check for ack from reciever

end

def req_ping(cmd)
	dst = cmd[0]
	numPings = cmd[1]
	delay = cmd[2]
	debug ("SENDING A PING")
	#puts ("Loop goes #{numPings} times")
	for i in 0..(numPings.to_i - 1) 
		$EQ.synchronize {
			#puts ("table #{$routingTable}")
			$pq.insert(Time.new + $pingTimeout, Event.new("PING_TIMEOUT", [i]))
			if $routingTable.has_key?(dst)
				#puts ("#{$routingTable[dst]}")
				#puts ("#{$neighbors}")
				temp = $routingTable[dst]
				#puts ("hop = #{temp.nextHop}")
				sendOn = $neighbors[temp.nextHop]
				#puts ("sending ping")
				debug ("sending REQ_PING #{$hostname} #{dst} #{Time.new} #{i}")
				$pq.insert(Time.new, Event.new("WRITE", [sendOn.sock, "REQ_PING #{$hostname} #{dst} #{Time.new} #{i}"]))
				#sendOn.sock.puts("REQ_PING #{$hostname} #{dst} #{Time.new} #{i}")
			end
		}
		#puts ("list is now #{$pq.q}")	
		sleep delay.to_i	
	end
end

def traceroute(cmd)
	dst = cmd[0]
	$EQ.synchronize {
		$pq.insert(Time.new + $pingTimeout, Event.new("TRACE_TIMEOUT", [$hostname, 0, dst]))
		if $routingTable.has_key?(dst)
			temp = $routingTable[dst]
			sendOn = $neighbors[temp.nextHop]
			$pq.traceTime($hostname, sendOn.name)
			$pq.insert(Time.new, Event.new("WRITE", [sendOn.sock, "TRACEROUTE #{dst} #{$hostname} #{Time.new} 0 0:#{$hostname}:0"]))
		end
	}
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

	#calls IO file methods
	l_thread = Thread.new{listener()}
	r_thread = Thread.new{read()}
	
	#set up ports, server, buffers
	#	stores all nodes and their ports in hash
	#	reading from nodes file
	File.open(nodes).each do |line| 
		arr = line.split(",")
		name = arr[0]
		port = arr[1]

		$nodes[name] = Node.new(name, port.to_i)
	end


	$cur = $nodes[$hostname]
	#initilize config file
	File.open(config).each do |line|
		#puts ("config file line = #{line}")
		arr = line.split("=")
		cmd = arr[0]
		value = arr[1].to_i
		#puts ("value = #{value} : cmd = #{cmd}")

		case cmd 
		when "updateInterval"
			$updateInterval = value
		when "maxPayload"
			$maxPayload = value
		when "pingTimeout"
			$pingTimeout = value
		end
	end

	#automatically update the routing table after interval 
	#puts ("update = #{$updateInterval}")
	#make believe clock implementation
	
	update_thread = Thread.new do
		while true
			sleep $updateInterval
			#puts ("update")
			$EQ.synchronize {	
				$pq.insert(Time.new, Event.new("FLOOD", []))
			}
		end
	end

	eventQueue = Thread.new do 
		while true
			$EQ.synchronize {
				$pq.run()
			}
			sleep 0.3
		end
	end
	#puts ("entering main")
	main()

end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])