defmodule Bulletin do
end


defmodule User do
  subscriptions = []
  def run() do
    receive do
      {:post,poster,content} -> IO.puts(content)
    end
    run()
  end

  def subscribe(topic_name, user_name) do
    case :global.whereis_name(topic_name) do
      #if undefined
      undefined -> 
        pid = spawn(TopicManager,:start,[topic_name])
        send(pid, {:subscribe, self()})
        #TODO: SAVE GLOBAL SUBSCRIPTIONS
        subscriptions = [pid]+subscriptions
      pid ->  
        send(pid,{:subscribe, self()})
        subscriptions = [pid]+subscriptions
    end

  end


  def unsubscribe(topic_name,user_name) do
    managerpid = :global.whereis_name(topic_name)
    subscriptions = Enum.reject(subscriptions, fn x -> x == managerpid end)
    send(managerpid,{:unsubscribe,self()})
  end
  def post(user_name, topic_name, content) do
    
  end
  def fetch_news() do
    #enumerate through subscriptions list and send each pid a :fetch message
    Enum.each(subscriptions,fn x -> send(x,{:fetch_news,self()}))
  end

end

defmodule TopicManager do
  def start(topic_name) do
    :global.register_name(self(),topic_name)
    run([],[])
  end

  def run(subscribers,content) do
    receive do
      #add pid to subscribers list
      {:subscribe,pid} -> run([subscribers|pid], content)
      {:unsubscribe,pid} ->
        #remove pid from subscribers list
        subscribers_new = Enum.reject(subscribers, fn x -> x == pid end)
        run(subscribers_new, content)
      {:fetch_news, caller} -> 
        #send the caller every message in content
        Enum.each(content, fn x -> send(caller, x)
        run(subscribers,content)
      {:post, poster, post}-> 
        #add this message to the content list
        run(subscribers,[content|{:post,poster,post}])
        #send post to all subscribers/..../
    end
  end

end