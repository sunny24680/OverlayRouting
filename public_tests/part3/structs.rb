class Node 
	#cost is the cost to the neighboring node
	attr_accessor :port, :name, :ip, :sock, :cost, :nextHop, :prev

	def initialize(name, port)
		self.name = name
		self.port = port
	end

	def copy()
		t = Node.new(self.name, self.port)
		t.ip = self.ip
		t.sock = self.sock
		t.cost = self.cost
		t.nextHop = self.nextHop
		t.prev = self.prev
		t
	end

end

class Message 
	#secure random.hex to create message id to fragment on
	attr_accessor :msg, :offset, :moreFrag

	def initialize(msg, off, frags)
		self.msg = msg
		self.offset = off
		self.moreFrag = frags
	end
end

class Event 
	attr_accessor :cmd, :data
	
	def initialize(command, data)
		self.cmd = command
		self.data = data
	end

end