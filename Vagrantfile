# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  N = 3 # max number of worker nodes
  Ver = '1.18.4' # Kubernetes Version to install

  #=============#
  # Master Node #
  #=============#

    config.vm.define "m-k8s" do |cfg|
      cfg.vm.box = "sysnet4admin/CentOS-k8s"
      cfg.vm.provider "virtualbox" do |vb|
        vb.name = "m-k8s"
        vb.cpus = 2
        vb.memory = 10240
        vb.customize ["modifyvm", :id, "--groups", "/k8s-SgMST-1.13.1(sns_project)"]
      end
      cfg.vm.host_name = "m-k8s"
      cfg.vm.network "private_network", ip: "192.168.1.10"
      cfg.vm.network "forwarded_port", guest: 22, host: 60010, auto_correct: true, id: "ssh"
      cfg.vm.synced_folder "../data", "/vagrant", disabled: true 
      cfg.vm.provision "shell", path: "config.sh", args: N
      cfg.vm.provision "shell", path: "install_pkg.sh", args: [ Ver, "Main" ]
      cfg.vm.provision "shell", path: "master_node.sh"
    end

  #==============#
  # Worker Nodes #
  #==============#

  (1..N).each do |i|
    config.vm.define "w#{i}-k8s" do |cfg|
      cfg.vm.box = "sysnet4admin/CentOS-k8s"
      cfg.vm.provider "virtualbox" do |vb|
        vb.name = "w#{i}-k8s"
        vb.cpus = 1
        vb.memory = 6144
        vb.customize ["modifyvm", :id, "--groups", "/k8s-SgMST-1.13.1(sns_project)"]
      end
      cfg.vm.host_name = "w#{i}-k8s"
      cfg.vm.network "private_network", ip: "192.168.1.10#{i}"
      cfg.vm.network "forwarded_port", guest: 22, host: "6010#{i}", auto_correct: true, id: "ssh"
      cfg.vm.synced_folder "../data", "/vagrant", disabled: true
      cfg.vm.provision "shell", path: "config.sh", args: N
      cfg.vm.provision "shell", path: "install_pkg.sh", args: Ver
      cfg.vm.provision "shell", path: "work_nodes.sh"
    end
  end

end