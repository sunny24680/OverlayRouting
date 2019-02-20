class eventHandler 
	q = {}
	clock = Time.new

	def initialize()
		clock = Time.new

	end

	def add(time, msg)
		q[time] = msg
	end

	def add(msg)
		q[Time.new] = msg
	end

	def run()
		q.delete_if {|key, value| 
			if (key <= Time.new)
				if q[key] == 'PING':
					ping()
				elsif q[key] == 'FLOOD':
					lsp()
					djikstra()
			key <= Time.new
			}
end