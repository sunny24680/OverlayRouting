require 'csv'
require 'socket'
require 'io/console'
require 'thread'
require_relative 'structs'

#@ instance
#@@ static variables
#$ gloabl variables

$updateInterval = nil
$maxPayload = nil
$pingTimeout = nil
$nodes = {}
$sock_array = {}

$cur = nil
$server = nil
$hostname = nil
$port = nil
# --------------------- Part 1 --------------------- # 

def listener()
	$server = TCPServer.open($port)
	#puts ("start listening")
	loop {
		Thread.start($server.accept) do |client|
			msg = client.gets
			puts ("just recieved a message #{msg}")
			msg_info = msg.split(" ")
			type = msg_info[0]
			case type 
			when "EDGEB"
				puts ("in edge #{$nodes}")
				dst = $nodes[msg_info[2]]
				dst.ip = msg_info[1]
				puts ("dst ip")
				dst.cost = 1
				puts ("dst cost")
				dst.sock = TCPSocket.open(dst.ip, dst.port.to_i)
				puts ("#{dst}")
				dst.sock = TCPSocket.open(dst.ip, dst.port.to_i)
				$nodes[$hostname].newNeighbor(dst)
			end
		end		
	}
end

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

	#adding it to the host nodes neighboring
	$nodes[$hostname].newNeighbor(dst)
end

def dumptable(cmd)
	fname = cmd[0].split("./")[1]
	#puts ("#{fname}")
	File.open(fname, "w") do |f|
  		$cur.table.keys.sort.each do |name|
  			str = $hostname + "," + name + "," + $cur.table[name].next + "," +$cur.table[name].cost.to_s
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
	puts ("before delete #{$nodes}")
	$nodes[$hostname].removeNeighbor($nodes[cmd[0]])
	puts ("AFTER #{$nodes}")
end

def edgeu(cmd)
	dst_name = cmd[0]
	cost = cmd[1].to_i
	$nodes[$hostname].updateNeighborCost($nodes[dst_name], cost)
	puts ("#{$nodes[dst_name]}")
end
#working on - Jon
def status()
	puts "Name: #{$hostname}"
	puts "Port: #{$port}"

	#check it this works
	key_array = $nodes.keys
	key_array.sort!
	print"Neighbors: #{key_array}"
end


# --------------------- Part 3 --------------------- # 
def sendmsg(cmd)
	STDOUT.puts "SENDMSG: not implemented"
end

def ping(cmd)
	STDOUT.puts "PING: not implemented"
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
		when "EDGEU"; edgeU(args)
		when "DUMPTABLE"; dumptable(args)
		when "SHUTDOWN"; shutdown(args)
		when "STATUS"; status()
		when "SENDMSG"; sendmsg(args)
		when "PING"; ping(args)
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
		arr = line.split(",")
		cmd = arr[0]
		value = arr[1]
		case cmd 
		when "updateInterval"
			$updateInterval = value
		when "maxPayload"
			$maxPayload = value
		when "pingTimeout"
			$pingTimeout = value
		end
	end

	l_thread = Thread.new{listener()}

	main()

end

setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])