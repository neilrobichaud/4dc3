defmodule Bulletin do

end


defmodule User do
  def run() do
    run()
  end

  def subscribe(topic_name, user_name) do
    case :global.whereis_name(topic_name) do
      #if undefined
      undefined ->
        pid = spawn(TopicManager,:start,[topic_name])
        send(pid, {:subscribe, self()})
      pid ->
        send(pid,{:subscribe, self()})
    end
  end


  def unsubscribe(topic_name,user_name) do
    #lookup pid of topicmanager of this topic
    managerpid = :global.whereis_name(topic_name)
    #tell the manager to remove this User from it's list
    send(managerpid,{:unsubscribe,self()})
  end

  def post(user_name, topic_name, content) do
    #lookup pid of topicmanager
    managerpid = :global.whereis_name(topic_name)
    #send the post to the topicmanager of this topic
    send(managerpid,{:post,self(),content})

  end

  def fetch_news() do
    #enumerate through subscriptions list and send each pid a :fetch message
    #Enum.each(subscriptions,fn x -> send(x,{:fetch_news,self()}) end)
    receive do
      {:post,poster,post} -> IO.puts(post)
      fetch_news()
    end
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
      {:post, poster, post}-> 
        #send post to all subscribers/..../
        Enum.each(subscribers,fn x -> send(x,{:post,poster,post}) end)
        #add this message to the content list
        run(subscribers,[content|{:post,poster,post}])
    end
  end

end