SUBNET="192.168.1.0/24"
GW="192.168.1.1"
MAIN_IF = "enp0s3"
RT_TABLES_FILE="/etc/iproute2/rt_tables"


PING_ADDR = "8.8.8.8"
CLIENTS_TO_SPAWN = 1


def create_interface(if_name)
	`ip link add link #{MAIN_IF} #{if_name} type macvlan mode bridge`
	`ifconfig #{if_name} up`
end

def clean_interface(if_name)
	`ifconfig #{if_name} down`
	`ip link delete #{if_name}`
end

def assign_ip(if_name)
	`dhclient #{if_name}`
end

def get_ip(if_name)
	output = `ip -4 addr show #{if_name}`
	return output.scan( /inet ([\d\.]*)/ ).first.first
end	

def create_routes(if_name,ip)
 	`ip route add #{SUBNET} dev #{if_name} src #{ip} table #{if_name}`
	`ip route add default via #{GW} dev #{if_name} table #{if_name}`
	`ip route flush cache`
	`ip rule add from #{ip} table #{if_name}`
end

def clean_routes(if_name)
	`ip route flush table #{if_name}`	
end

def check_ping(if_name)
	output = `ping -I #{if_name} -c 1 #{PING_ADDR}`
	packets_recieved = output.scan( /([\d]*) received/).first.first.to_i
	return packets_recieved != 0
end

def do_download(ip)
	`wget -qO- http://checkip.dyndns.com/ --bind-address #{ip}`
end

def modify_rt_tables()
	`cp #{RT_TABLES_FILE} #{RT_TABLES_FILE}.bak`
	File.open(RT_TABLES_FILE, 'a') do |f| 
		(1..CLIENTS_TO_SPAWN).each do |i|
			f.write("#{i+10} mac#{i}\n")
		end
	end

end

def clean_rt_tables()
	`cp #{RT_TABLES_FILE}.bak #{RT_TABLES_FILE}`
	`rm #{RT_TABLES_FILE}.bak`
end

clients = []

modify_rt_tables()

(1..CLIENTS_TO_SPAWN).each do |i|
	clients << Thread.new(i) do |i| 
		if_name = "mac#{i}"

		create_interface(if_name)
		puts "Interface created #{if_name}"
		
		assign_ip(if_name)		
		ip = get_ip(if_name)
		puts "IP Assigned #{ip} for #{if_name}"

		create_routes(if_name,ip)
		puts "Routes added for interface #{if_name}"

		if check_ping(if_name)
			do_download(ip)
		else 
			Thread.current[:output] = "Client #{i} failed"
		end
		
		#clean_routes(if_name)
		#clean_interface(if_name)
		
	end
end

clients.each do |client|
	client.join()
	puts client[:output]
end

#clean_rt_tables()

