defmodule Bulletin do

end


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
    :global.register_name(topic_name,self())
    #register pid of topic manager under topic_name
    run([],[])
  end

  def run(subscribers,content) do
    receive do
      #add pid to subscribers list
      {:subscribe,user_name} -> 
        run(subscribers++[user_name], content)
      {:unsubscribe,user_name} ->
        #remove pid from subscribers list
        subscribers_new = Enum.reject(subscribers, fn x -> x == user_name end)
        run(subscribers_new, content)
      {:post, poster, post}-> 
        #send post to all subscribers/..../
        Enum.each(subscribers,fn x -> send(:global.whereis_name(x),{:post,poster,post}) end)
        #add this message to the content list
        run(subscribers,[content|{:post,poster,post}])
    end
  end

end