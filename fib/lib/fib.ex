defmodule Fib do
	def hello do
		:world
	end
	def fib_calc(1), do: 1
	def fib_calc(2), do: 1
	def fib_calc(n) do
		l = List.duplicate(0,n-2)
		l=[0,1,1]++l
		{resultn,resultl}=helper(n,l)
		{resultn,resultl}
	end
	def helper(n,l) do
		if Enum.at(l,n) != 0 do
			{Enum.at(l,n),l}
			
		else
			if n>2 do
				if Enum.at(l,n-1)>0 do
					n_val = Enum.at(l,n-1)+Enum.at(l,n-2)
					l = List.replace_at(l,n,n_val)
					{Enum.at(l,n),l}

				else
					{n1,l1}= helper(n-2,l)
					{n2,l2}= helper(n-1,l1)
					l = List.replace_at(l2,n,n1+n2)
					{Enum.at(l,n),l}
					
				end
			else
				{1,l}
				
			end
		end
	end


  	def server(caller) do
		send(caller,{:ready, self()})
		receive do
			{:compute,n,client}->
				send(client,{:answer,n,fib_calc(n)})
				server(caller)
			{:shutdown}->exit(:normal)
		end
	  end
end

defmodule Scheduler do
	def start(num_servers,job_list) do
		spawn_n_servers(num_servers)
		run(num_servers,job_list,[])
	end

	def spawn_n_servers(n) when n<=1 do
		spawn(Fib,:server,[self()])
	end
	def spawn_n_servers(n) do
		spawn(Fib,:server,[self()])
		spawn_n_servers(n-1)
	end

	def run(num_servers,job_list,result_list) do
		receive do
			{:ready, server_pid}->	
				case job_list do
					[] ->
						send(server_pid,{:shutdown})
						if num_servers==1 do
							result_list
						else
							run(num_servers-1,[],result_list)
						end
					[n|remaining]-> 
						send(server_pid,{:compute,n,self()})
						run(num_servers,remaining,result_list)
				end
			{:answer, _n, result} -> run(num_servers,job_list,[result_list|result])
		end
	end
end