require "spec_helper"

describe "openswan::default" do
  let(:chef) { ChefSpec::Runner.new }

  subject(:chef_run) { chef.converge(described_recipe) }

  before do
    Chef::Recipe.any_instance.stub(:include_recipe).with("deploy")
    chef.node.set[:opsworks][:instance] = {
      ip: "1.2.3.4.5",
      private_ip: "0.0.0.0.0",
    }
  end

  context "when an openswan configuration exists" do
    before do
      chef.node.set[:openswan][:vpn_local_ip] = "some kind of pokemon"
      chef.node.set[:openswan][:vpn_ip_range] = "9am-5pm"
      chef.node.set[:openswan][:subnet_cidr] = "10.0.1.0.1.2/what"
      chef.node.set[:openswan][:ipsec_psk] = "i am a psk"
      chef.node.set[:openswan][:users] = [
        {username: "user", password: "pass"}
      ]
    end

    describe "packages" do
      it { should install_package "ppp" }
      it { should install_package "openswan" }
      it { should install_package "xl2tpd" }
    end

    describe "/etc/ipsec.conf" do
      it { should render_file("/etc/ipsec.conf").with_content(%r|virtual_private=%v4:10\.0\.1\.0\.1\.2/what|) }
      it { should render_file("/etc/ipsec.conf").with_content(/left=0\.0\.0\.0\.0/) }
      it { should render_file("/etc/ipsec.conf").with_content(%r|leftsubnet=0\.0\.0\.0\.0/32|) }
      it { should render_file("/etc/ipsec.conf").with_content(/leftid=1\.2\.3\.4\.5/) }
      specify { chef_run.template("/etc/ipsec.conf").should notify("service[ipsec]").to(:restart) }
    end

    describe "/etc/ipsec.secrets" do
      it { should render_file("/etc/ipsec.secrets").with_content(/1\.2\.3\.4\.5.+i am a psk/) }
      specify { chef_run.template("/etc/ipsec.secrets").should notify("service[ipsec]").to(:restart) }
    end

    describe "/etc/xl2tpd/xl2tpd.conf" do
      it { should render_file("/etc/xl2tpd/xl2tpd.conf").with_content(/port = 1701/) }
      specify { chef_run.template("/etc/xl2tpd/xl2tpd.conf").should notify("service[xl2tpd]").to(:restart) }
    end

    describe "/etc/ppp/options.xl2tpd" do
      it { should render_file("/etc/ppp/options.xl2tpd").with_content(/ipcp-accept-local/) }
      specify { chef_run.cookbook_file("/etc/ppp/options.xl2tpd").should notify("service[xl2tpd]").to(:restart) }
    end

    describe "/etc/ppp/chap-secrets" do
      it { should render_file("/etc/ppp/chap-secrets").with_content(/user.+pass/) }
      specify { chef_run.template("/etc/ppp/chap-secrets").should notify("service[xl2tpd]").to(:restart) }
    end

    describe "/etc/rc.local" do
      it { should render_file("/etc/rc.local").with_content(/POSTROUTING.+MASQUERADE/) }
      specify { chef_run.cookbook_file("/etc/rc.local").should notify("execute[enable ip forwarding]").to(:run) }
    end

    describe "/etc/sysctl.conf" do
      it { should render_file("/etc/sysctl.conf").with_content(/net.ipv4.ip_forward=1/) }
      it { should render_file("/etc/sysctl.conf").with_content(/net.ipv4.conf.all.accept_redirects = 0/) }
      it { should render_file("/etc/sysctl.conf").with_content(/net.ipv4.conf.all.send_redirects = 0/) }
      specify { chef_run.cookbook_file("/etc/sysctl.conf").should notify("execute[reload sysctl]").to(:run) }
    end
  end
end
