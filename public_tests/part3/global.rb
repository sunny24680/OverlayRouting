#@ instance
#@@ static variables
#$ gloabl variables
require_relative 'eventQ'
require 'monitor'

Thread.abort_on_exception = true

#values we get from the config file
$updateInterval = nil
$maxPayload = nil
$pingTimeout = nil

#hash of the entire layout 
$nodes = {}

#keeps track of neighbors to the host node
$neighbors = {}

#keeps track of overall routing table 2D table with [source][dst]=COST
$table = {}

#routing table with [dst_name] = node object (that stores nextHop and cost)
$routingTable = {}

#keeps track of all incoming sockets
$reading = []

# keeps track of how many changes have occured
$sequencenum = 0;

# keeps track of all the link state packets we recieve 
# checks seq num of each node to see if its the updated version
$lsp = {}

#stores hash of incoming sendmsg
$readMsg = {}

#saves the structure of the current node 
$cur = nil

#the server we create with the current node
$server = nil

$hostname = nil
$port = nil

#initializes the EventHandler
$pq = EventHandler.new

#keeps track of synchro
$semaphore = Mutex.new
$EQ = Mutex.new
$writing = Mutex.new