class Node 
	attr_accessor :port, :name, :ip, :sock, :cost, :neighborsName, :neighborsSocket, :table, :next
	/
	keeps track of who are next to the node through hashmap
	1. name to node 
	2. socket to node 
	3. table stores routing information 
	/

	def initialize(name, port)
		self.name = name
		self.port = port
		self.neighborsName = {}
		self.neighborsSocket = {}
		self.table = {}
	end

	def updateNeighborCost(node, cost)
		neighborsName[node.name].cost = cost
		neighborsSocket[node.sock].cost = cost
		table[node.name].cost = cost
	end

	def newNeighbor(node)
		setNeighborName(node)
		setNeighborSocket(node)
	end

	def removeNeighbor(node)
		rmNeighborName(node)
		rmNeighborSocket(node)
	end

	def setNeighborName(node)
		neighborsName[node.name] = node
		table[node.name] = node
		table[node.name].cost = 1
		table[node.name].next = node.name
	end

	def getNeighborName(name)
		neighborsName[name]
	end

	def rmNeighborName(node)
		neighborsName.delete(node.name)
	end

	def setNeighborSocket(node)
		neighborsSocket[node.sock] = node
	end

	def getNeighborSocket(sock)
		neighborsSocket[sock]
	end

	def rmNeighborSocket(node)
		neighborsSocket.delete(node.sock)
	end

end