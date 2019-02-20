require_relative 'global'

# ------------------------------------------------------------------------------ #

# => This file is to take care of the in and out going connections to the node

# ------------------------------------------------------------------------------ #


# checks if a new socket is connected to the server
def listener()
	$server = TCPServer.open($port)
	puts ("start listening")
	loop {
		client = $server.accept 
		puts ("adding #{client} to reading list")
		# synchronize reading list
		$reading.push(client)	
	}
end

#reads all messages being sent into the node
def read()
	loop {
		#puts ("read list in : #{$reading}")
		rs, ws, es = IO.select($reading, nil, nil, 1)
		if (rs != nil)
			rs.each { |r|
				msg = r.gets
				#only reads in messages sent from a socket
				if (!(msg == nil))
					puts ("just recieved a message #{msg}")
					parseMsg(msg)			
				end
			}
		end
		
	}
end

def parseMsg(msg)
	msg_info = msg.split(" ")
	type = msg_info[0]
	case type 
	when "EDGEB"	
		dst = $nodes[msg_info[2]]
		dst.ip = msg_info[1]
		dst.name = msg_info[2]
		#puts ("dst ip")
		dst.cost = 1
		#puts ("dst cost")
		dst.sock = TCPSocket.open(dst.ip, dst.port.to_i)
		dst.nextHop = dst
		#puts ("#{dst}")
		#puts ("in nodes #{$nodes}")
		$neighbors[dst.name] = dst

		lsp()
		#puts ("in neighbors #{$neighbors}")
	when "LSP"
		src_name = msg_info[1]
		neighbors = msg_info[2]
		seq_num = msg_info[3].to_i

		#checks of the msg sequence num of msg in the newest version
		if ((!$lsp.has_key?(src_name)) or ($lsp[src_name] < seq_num))
			#if the msg is a new msg then read the msg else dont flood it again
			$lsp[src_name] = seq_num
			$table[src_name] = {}
			neighbors.split("|").each do |n|
				#puts ("n = #{n}")
				arr = n.split(":")
				#puts ("after split")
				dst = arr[0]
				cost = arr[1]
				$table[src_name][dst] = cost.to_i
			end
			puts ("TABLE = ")
			puts ("#{$table}")
			#flood to the rest of the neighbors
			flood(msg)
		end
		djikstra()
	when "REQ_PING"
		src = msg_info[1]
		dst = msg_info[2]
		time = msg_info[3]
		seqID = msg_info[4]
		if $hostname == dst
			#if this is the request PING then send a responce back
			$routingTable[src].sock.puts("RESP_PING #{src} #{dst} #{time} #{seqID}")
		else
			#else pass this ping on to the route of the dst
			$routingTable[dst].sock.puts(msg)
	when "RESP_PING"
		src = msg_info[1]
		dst = msg_info[2]
		time = msg_info[3]
		seqID = msg_info[4]
		if $hostname == src
			rtime = Time.new
			rtime = rtime - time
			puts ("#{seqID} #{dst} #{rtime} secs")
	end
end

#create the link state packet
def lsp()
	$sequencenum += 1
	msg = "LSP "
	msg<<"#{$hostname} "
	#puts ("#{$neighbors}")
	$neighbors.each do |key, value|
		msg<<"#{value.name}"
		msg<<":"
		msg<<"#{value.cost}"
		msg<<"|"		
	end
	#puts ("before chomp #{msg}")
	msg = msg.chomp("|")
	msg<<" #{$sequencenum}"
	#puts ("sending msg #{msg}")
	# flooding each neighbor node with lsp
	flood(msg)
end

#pass whatever message you receive to each of the connecting negihbors of the node
def flood(msg)
	$neighbors.each do |key, value|
		puts ("writing to #{value.name} : #{msg} through socket #{value.sock}")
		value.sock.puts("#{msg}")
	end
end