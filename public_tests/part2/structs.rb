class Node 
	#cost is the cost to the neighboring node
	attr_accessor :port, :name, :ip, :sock, :cost, :nextHop, :prev

	def initialize(name, port)
		self.name = name
		self.port = port
	end

end