def djikstra()
    @distance={}
    @previous={}
    @visited={}

    $nodes.each do |k, v|#initialization
      @distance[v.name] = 99999 #Unknown distance from source to vertex
      @previous[v.name] = -1 #Previous node in optimal path from source
      @visited[v.name] = false
    end

    @distance[$hostname] = 0 #Distance from source to source

    unvisited_node = [$hostname]
    c = 0
    $neighbors.each_value { |v| unvisited_node[c = c + 1] = v.name} #All nodes initially in Q (unvisited nodes)
    #puts ("unvisited = #{unvisited_node}")
    while (unvisited_node.size > 0)
      u = nil;

      #find shortest distance 
      unvisited_node.each do |min|
        if (not u) or (@distance[min] and @distance[min] < @distance[u])
          #puts ("setting new min = #{min}")
          u = min
        end
      end

      #remove node that we are going to process
      unvisited_node = unvisited_node - [u]
      @visited[u] = true

      #puts ("TABLE = #{$table}")
      if ($table.has_key?(u))
        $table[u].keys.each do |dst|
          if (@visited[dst] == false)
            unvisited_node.push(dst)
            @visited[dst] = true
          end
          alt = @distance[u] + $table[u][dst]
          #puts ("ALT = #{alt} : distance = #{@distance[dst]}")
          if (alt < @distance[dst])
            @distance[dst] = alt
            @previous[dst] = u
          end
        end
      end
    end
    #puts ("distance array = #{@distance}")
    #puts ("prev array = #{@previous}")
    removeIso(@distance, @previous)
    updateRouting(@distance, @previous)
    #puts ("NEW ROUTINGTABLE = #{$routingTable}")
end

def updateRouting(dist, previous)
  #[dst_name] = next hop to get there from current node
  #puts ("WORKING?")
  #puts ("Distance = #{dist}")
  #puts ("Prev = #{previous} #{$neighbors}")

  @nextHop = {}
  previous.keys.each do |name|
    prev = prev
    n =  name;
    #puts ("init n = #{n}")
    if ($neighbors.has_key?(n)) 
      if $neighbors[n].cost != dist[n] 
        n =  previous[n] 
      end 
    end 
    while (!$neighbors.has_key?(n)) 
      n =  previous[n] 
    end 
    @nextHop[name] = n
    temp = $nodes[name].copy()
    temp.cost = dist[name]
    temp.nextHop = n
    $routingTable[name] = temp
  end
  #puts ("finished update")
end

def removeIso(dist, prev)
  dist.delete_if {|key, value| value == 99999 }
  prev.delete_if {|key, value| value == -1 }
end
