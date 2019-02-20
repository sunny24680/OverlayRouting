require_relative 'global'

# ------------------------------------------------------------------------------ #

# => This file is to take care of the in and out going connections to the node

# ------------------------------------------------------------------------------ #


# checks if a new socket is connected to the server
def listener()
	$server = TCPServer.open($port)
	#puts ("start listening")
	loop {
		client = $server.accept()
		#puts ("adding #{client} to reading list")
		# synchronize reading list
		$semaphore.synchronize {
			$reading.push(client)	
		}
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
					msg_info = msg.split(" ")
					#if msg_info[0] != "LSP"
					#puts("just recieved a message #{msg}")
					#end
					#puts ("just recieved a message #{msg}")
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
		#puts("got LSP = #{msg}")
		#checks of the msg sequence num of msg in the newest version
		if ((!$lsp.has_key?(src_name)) or ($lsp[src_name] < seq_num))
			#if the msg is a new msg then read the msg else dont flood it again
			$semaphore.synchronize {
				$lsp[src_name] = seq_num
				$table[src_name] = {}
				neighbors.split("|").each do |n|
					#puts ("n = #{n}")
					arr = n.split(":")
					#puts ("after split")
					dst = arr[0]
					cost = arr[1]
					#puts ("update cost of #{dst} to #{cost}")
					$table[src_name][dst] = cost.to_i
				end
				#puts ("table in LSP = #{$table}")
			}
			#puts ("TABLE = ")
			#puts ("#{$table}")
			#flood to the rest of the neighbors	
			$semaphore.synchronize{		
				djikstra()
			}
			flood(msg)
		end
	when "SENDMSG"
		#puts ("got a message")
		dst = msg_info[1]
		src = msg_info[2]
		offset = msg_info[3]
		frag = msg_info[4]
		incomingmsg = ""
		for x in 5..msg_info.length-1 do 
			incomingmsg += msg_info[x] + " "
		end
		incomingmsg = incomingmsg[0..-2]
		if $hostname == dst
			debug ("FRAG = #{frag} #{frag == "true"}")
			if (frag == "true")
				if !$readMsg.has_key?(src)
					$readMsg[src] = incomingmsg
				else
					debug ("prev #{$readMsg[src]}")
					$readMsg[src] += incomingmsg
				end
			else
				if $readMsg.has_key?(src)
					$readMsg[src] += incomingmsg
				else
					$readMsg[src] = incomingmsg
				end
				puts ("SENDMSG: #{src} --> #{$readMsg[src]}")
				$readMsg.delete(src)
			end
		else
			fwd = $routingTable[dst].nextHop
			debug ("incoming mesg = #{incomingmsg}")
			messages = check_frag(incomingmsg, frag)
			for x in 0..messages.length-1 do
				debug ("message frag = #{messages[x].moreFrag}")
				data = "SENDMSG #{dst} #{src} #{messages[x].offset} #{messages[x].moreFrag} #{messages[x].msg}"
				debug ("sending #{data}")
				writeTo($routingTable[fwd].sock, data)
			end
		end
	when "REQ_PING"
		src = msg_info[1]
		dst = msg_info[2]
		date = msg_info[3]
		time = msg_info[4]
		reg = msg_info[5]
		seqID = msg_info[6]
		debug ("recieved A PING REQUEST")
		if $hostname == dst
			#if this is the request PING then send a responce back
			$EQ.synchronize {
				#puts ("sending back message to #{src}")
				#puts ("table = #{$routingTable}")
				fwd = $routingTable[src].nextHop
				$pq.insert(Time.new, Event.new("WRITE", [$routingTable[fwd].sock, "RESP_PING #{src} #{dst} #{date} #{time} #{reg} #{seqID}"]))
			}
		else
			#else pass this ping on to the route of the dst
			debug ("routing table = #{$routingTable}")
			fwd = $routingTable[dst].nextHop
			debug ("fwd = #{$routingTable[fwd].sock}")
			writeTo($routingTable[fwd].sock, msg)			
		end
	when "RESP_PING"
		#puts ("GOT A RESPONCE PING")
		src = msg_info[1]
		dst = msg_info[2]
		date = msg_info[3]
		time = msg_info[4]
		reg = msg_info[5]
		seqID = msg_info[6]
		if $hostname == src
			rtime = Time.new
			year = date.split("-")[0]
			month = date.split("-")[1].to_i
			day = date.split("-")[2].to_i
			hour = time.split(":")[0].to_i
			min = time.split(":")[1].to_i
			sec = time.split(":")[2].to_i
			reg.insert(3, ":")
			time2 = Time.new(year, month, day, hour, min, sec, reg)
			rtime = rtime - time2
			#puts ("RECEIVED PING #{Time.new}")
			$EQ.synchronize {
				$pq.removePing(seqID)	
			}
			
			puts ("#{seqID} #{dst} #{rtime}")
		else
			fwd = $routingTable[src].nextHop
			writeTo($routingTable[fwd].sock, msg)
			#puts ("forwarding response to #{fwd} = #{$routingTable}")
		end
	when "TRACEROUTE"
		dst = msg_info[1]
		src = msg_info[2]
		date = msg_info[3]
		time = msg_info[4]
		reg = msg_info[5]
		hopCount = msg_info[6].to_i
		rtime = Time.new
		year = date.split("-")[0]
		month = date.split("-")[1].to_i
		day = date.split("-")[2].to_i
		hour = time.split(":")[0].to_i
		min = time.split(":")[1].to_i
		sec = time.split(":")[2].to_i
		reg.insert(3, ":")
		time2 = Time.new(year, month, day, hour, min, sec, reg)
		rtime = rtime - time2
		data = msg_info[7].to_s
		hopCount = hopCount + 1
		data = hopCount.to_s+":"+$hostname+":"+rtime.to_s
		msg = msg_info[0]+" "+dst+" "+src+" "+time2.to_s+" "+hopCount.to_s+" "+data
		debug ("RECIEVED TRACEROUTE #{msg}")
		if $hostname == dst 
			fwd = $routingTable[src].nextHop
			writeTo($routingTable[fwd].sock, "RESP_TRACEBACK #{src} #{$hostname} end #{data}")
			#$pq.insert(Time.new, Event.new("WRITE", [$routingTable[fwd].sock, "RESP_TRACEBACK #{src} #{data}"]))
		else 
			#else pass this ping on to the route of the dst
			fwd = $routingTable[src].nextHop
			writeTo($routingTable[fwd].sock, "RESP_TRACEBACK #{src} #{$hostname} #{$routingTable[dst].nextHop} #{data}")
			fwd = $routingTable[dst].nextHop
			writeTo($routingTable[fwd].sock, "TRACEROUTE #{dst} #{src} #{time2} #{hopCount}")
			debug ("PASSING MESSAGE TO #{fwd}")
			#$pq.insert(Time.new, Event.new("WRITE", [$routingTable[fwd].sock, msg]))
		end
	when "RESP_TRACEBACK"
		dst = msg_info[1]
		src = msg_info[2]
		nHop = msg_info[3]
		data = msg_info[4]
		#puts ("#{$hostname} RESPONCE TRACEBACK : dst = #{dst} : data = #{data}")
		if dst == $hostname
			$EQ.synchronize {
				$pq.traceTime(src, nHop)
				$pq.removeTrace(src)
			}
			#puts ("RESPONDED TO TRACEROUTE")
			data.split("|").each { |msg|
				d = msg.split(":")
				hop = d[0]
				node = d[1]
				time = d[2]
				puts ("#{hop} #{node} #{time}")
			}
		else 
			fwd = $routingTable[dst].nextHop
			#puts ("PASSING MESSAGE TO #{fwd}")
			writeTo($routingTable[fwd].sock, "RESP_TRACEBACK #{dst} #{src} #{nHop} #{data}")
		end
	end
end

def check_frag(msg, frags)
	messages = []
	start = 0
	ending = $maxPayload
	debug ("length = #{msg.length}")
	debug ("playload = #{$maxPayload}")
	while msg.length > $maxPayload
		messages.push(Message.new(msg[0, ending], start, true))
		start = start + ending
		msg = msg[ending..-1]
	end
	debug ("frags = #{frags}")
	if (frags == "true")
		messages.push(Message.new(msg[0..-1], start, true))
	else 
		messages.push(Message.new(msg[0..-1], start, false))
	end
	#puts ("fragments #{messages}")
	messages
end

def writeTo(sock, msg)
	$writing.synchronize {
		if (sock != nil)
			sock.puts(msg);	
		end
	}	
end

def debug(msg)
	if false
		puts (msg)
	end
end

#create the link state packet
def lsp()
	$sequencenum += 1
	msg = "LSP "
	msg<<"#{$hostname} "
	#puts ("neighbor in lsp = #{$neighbors}")
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
	#puts ("flooding msg = #{msg}")
	flood(msg)
end

#pass whatever message you receive to each of the connecting negihbors of the node
def flood(msg)
	#$semaphore.synchronize{
	$neighbors.each do |key, value|
	#puts ("writing to #{value.name} : #{msg} through socket #{value.sock}")
	#value.sock.puts("#{msg}")\
		writeTo(value.sock, msg)
		#$pq.insert(Time.new, Event.new("WRITE", [value.sock, msg]))
	end
	#}
end