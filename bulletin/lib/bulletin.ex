defmodule User do
  def start(user_name) do
    :global.register_name(user_name,self())
  end

  def subscribe(topic_name, user_name) do
    #case Registry.lookup(Registry.Processes,topic_name) do
    case :global.whereis_name(topic_name) do
      #if undefined
      :undefined ->
        pid = spawn(TopicManager,:start,[topic_name])
        send(pid, {:subscribe, user_name})
      pid ->
        send(pid,{:subscribe, user_name})
    end
  end


  def unsubscribe(topic_name,user_name) do
    #lookup pid of topicmanager of this topic
    managerpid = :global.whereis_name(topic_name)
    #tell the manager to remove this User from it's list
    send(managerpid,{:unsubscribe,user_name})
  end

  def post(topic_name, user_name, content) do
    #lookup pid of topicmanager
    managerpid = :global.whereis_name(topic_name)
    #send the post to the topicmanager of this topic
    send(managerpid,{:post,user_name,content})

  end

  def fetch_news() do
    #read message from inbox , timeout after 1s
    receive do
      {:post,poster,post} -> IO.puts("#{poster},#{post}")
      fetch_news()
    after 1000 -> :empty 
    end
  end
end

defmodule TopicManager do
  def start(topic_name) do
    #register pid of topic manager under topic_name
    :global.register_name(topic_name,self())
    #for each connected node, spawn a new topicmanager and store it's pid
    secondary_pids = List.foldl(Node.list(), [], fn x, acc -> acc ++ [Node.spawn(x, TopicManager, :start_secondary, [[],Node.self(),length(acc),topic_name])] end)
    IO.puts("secondary_pids= #{inspect(secondary_pids)}")
    run([],secondary_pids)
  end
  #wait is the starting state for secondary nodes
  def start_secondary(subscribers,master_node,rank,topic_name) do
        Node.monitor(master_node,true)
        wait(subscribers,rank,topic_name)
  end
  def wait(subscribers,rank,topic_name) do
    #IO.puts("these are my subs #{rank}: #{subscribers}")
    receive do
      {:nodedown,_node} -> 
        #master died, check if rank 0
        #if rank == 0 do
            # I am the master now!
            :global.re_register_name(topic_name,self())
            #IO.puts("msg: #{msg}")
            #this only works for a single failure...btw
            run(subscribers,[])
        #end
      {:subscribe,user_name} -> wait(subscribers++[user_name], rank,topic_name)
      {:unsubscribe,user_name} -> 
        #get rid of this username
        subscribers_new = Enum.reject(subscribers, fn x -> x == user_name end)
        wait(subscribers_new,rank,topic_name)
    end
  end
  #only the master node gets to call run
  def run(subscribers,secondary_pids) do
    receive do
      #add pid to subscribers list and notify all secondary managers
      {:subscribe,user_name} -> 
        #send all the secondary managers the new subscriber
        Enum.each(secondary_pids, fn x -> send(x,{:subscribe,user_name}) end)
        run(subscribers++[user_name],secondary_pids)
      {:unsubscribe,user_name} ->
        Enum.each(secondary_pids, fn x -> send(x,{:unsubscribe,user_name}) end)
        #remove pid from subscribers list
        subscribers_new = Enum.reject(subscribers, fn x -> x == user_name end)
        run(subscribers_new,secondary_pids)
      {:post, poster, post} -> 
        #send post to all subscribers
        #IO.puts("My subscribers are: #{subscribers}")
        Enum.each(subscribers,fn x -> unless :global.whereis_name(x) == :undefined do send(:global.whereis_name(x),{:post,poster,post}) end end)
        run(subscribers,secondary_pids)
    end
  end

end