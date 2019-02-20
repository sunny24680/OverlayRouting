class EventHandler
	#@q = {}
	#@clock = Time.new

	def initialize()
		@clock = Time.new
		@q = {}
	end

	def q()
		@q
	end

	def removeTrace(src)
		@q.delete_if {|key, value|
			next unless value != nil
			value.cmd == "TRACE_TIMEOUT" and value.data[2] == src
		}
	end

	def traceTime(node, nHop)
		@q.each {|key, value|
			next unless value != nil
			if value.cmd == "TRACE_TIMEOUT"
				if value.data[0] == node
					debug ("DATA = #{value.data}")
					value.data[1] = value.data[1] + 1
					value.data[0] = nHop
				end
			end
		}
	end

	def removePing(id)
		@q.delete_if {|key, value|
			next unless value != nil 
			if (value.cmd == "PING_TIMEOUT")
				if value.data[0].to_i == id.to_i
					#puts ("remove ping num #{id}")
					true
				end
			else 
				false
			end
		}
	end

	def timer()
		@clock = Time.new
		temp1 = {}
		@q.each{|e,v|
			temp1[e] = v
		}
		temp = temp1.keys
		if !temp[0].nil?
			min = temp[0]
			temp.each {|key| 
				if key <= min 
					min = key
				end
			}
			min
		else 
			nil
		end
	end

	def insert(time, event)
		@q[time] = event
	end

	def run()
		#puts ("RUNNIGN")
		temp = {}
		@q.each{|e,v|
			temp[e] = v
		}
		if (!temp.empty?)
			@clock = Time.new
			temp.each {|key, value| 
				if (key <= @clock)
					next unless value != nil
					#puts ("running a command #{value}")
					command = value.cmd
					if command == "PING_TIMEOUT"
						puts("PING ERROR: HOST UNREACHABLE")
					elsif command == "FLOOD"
						#puts ("LSP #{$table}")
						lsp()
						djikstra()
					elsif command == "TRACE_TIMEOUT"
						puts("TIMEOUT ON "+value.data[1].to_s)
					elsif command == "WRITE"
						#Thread.new do 
						#$semaphore.synchronize{
						writeSock = value.data[0]
						msg = value.data[1]
						#puts ("Running command #{command} #{msg}")
						#puts ("node = #{writeTo}")
						#puts ("message = #{msg}")
						writeTo(writeSock, msg)
						#}
					#	end			
					end
					@q[key] = nil
				end
			}
		end
	end

end


