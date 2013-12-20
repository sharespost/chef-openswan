package "ppp"
package "openswan"
package "xl2tpd"

service "xl2tpd" do
  action :nothing
end

service "ipsec" do
  action :nothing
end

execute "enable ip forwarding" do
  command "/etc/rc.local"
  action :nothing
end

execute "reload sysctl" do
  command "sysctl -p /etc/sysctl.conf"
  action :nothing
end

template "/etc/ipsec.conf" do
  source "ipsec.conf.erb"
  mode "0644"
  notifies :restart, "service[ipsec]"
  variables(
    :subnet_cidr => node[:openswan][:subnet_cidr],
    :private_ip => node[:opsworks][:instance][:private_ip],
    :public_ip => node[:opsworks][:instance][:ip]
  )
end

template "/etc/ipsec.secrets" do
  source "ipsec.secrets.erb"
  mode "0600"
  notifies :restart, "service[ipsec]"
  variables(
    :public_ip => node[:opsworks][:instance][:ip],
    :ipsec_psk => node[:openswan][:ipsec_psk]
  )
end

template "/etc/xl2tpd/xl2tpd.conf" do
  source "xl2tpd.conf.erb"
  mode "0644"
  notifies :restart, "service[xl2tpd]"
  variables(
    :vpn_ip_range => node[:openswan][:vpn_ip_range],
    :vpn_local_ip => node[:openswan][:vpn_local_ip]
  )
end

cookbook_file "/etc/ppp/options.xl2tpd" do
  source "options.xl2tpd"
  mode "0644"
  notifies :restart, "service[xl2tpd]"
end

template "/etc/ppp/chap-secrets" do
  source "chap-secrets.erb"
  mode "0600"
  notifies :restart, "service[xl2tpd]"
  variables(
    :users => node[:openswan][:users]
  )
end

cookbook_file "/etc/sysctl.conf" do
  source "sysctl.conf"
  mode "0644"
  notifies :run, "execute[reload sysctl]"
end

cookbook_file "/etc/rc.local" do
  source "rc.local"
  mode "0755"
  notifies :run, "execute[enable ip forwarding]"
end
