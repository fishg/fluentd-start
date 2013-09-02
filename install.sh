#!/bin/sh
#注意:fluentd forward端口需要tpc和 udp 都支持
install_dir="/root/soft"
jemalloc_install_dir="/usr/local"
fluentd_config_dir="/data/fluentd"
ruby_version="1.9.3"
 
#系统参数调节,如果已经修改过,不必运行这一段
ulimit -n 65535
echo "root soft nofile 65536" >>/etc/security/limits.conf
echo "root hard nofile 65536" >>/etc/security/limits.conf
echo "* soft nofile 65536" >>/etc/security/limits.conf
echo "* hard nofile 65536" >>/etc/security/limits.conf
echo "net.ipv4.tcp_tw_recycle = 1" >>/etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >>/etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 10240    65535" >>/etc/sysctl.conf
sysctl -w 
mkdir -p $install_dir/fluentd
#=============jemalloc 安装==============
cd $install_dir
wget http://www.canonware.com/download/jemalloc/jemalloc-3.2.0.tar.bz2
tar -jxf jemalloc-3.2.0.tar.bz2
cd jemalloc-3.2.0
./configure --prefix=$jemalloc_install_dir --exec-prefix=$jemalloc_install_dir
make
make install
cd /usr/bin
wget https://raw.github.com/fishg/fluentd-start/master/jemalloc.sh
chmod +x jemalloc.sh
#===============rvm and ruby安装===========
cd $install_dir
echo "export LC_CTYPE=\"UTF-8\"" >> /etc/rc.local
#echo "export LC_ALL=\"UTF-8\"" >> /etc/rc.local
export LC_CTYPE="UTF-8" 
#export LC_ALL="UTF-8"
\curl -L https://get.rvm.io | bash
echo "export PATH=/usr/local/rvm/bin:\$PATH" >> /etc/rc.local
export PATH=/usr/local/rvm/bin:$PATH
rvm get stable
sed -i 's!ftp.ruby-lang.org/pub/ruby!ruby.taobao.org/mirrors/ruby!' /usr/local/rvm/config/db 
rvm install ruby-$ruby_version
rvm use $ruby_version
#==============fluent安装==================
gem sources --remove https://rubygems.org/
gem sources -a http://ruby.taobao.org/
gem sources -l
gem install bundler
gem install jeweler 
cd $install_dir/
git clone https://github.com/fishg/fluentd
cd fluentd
rake build
gem install pkg/fluentd-0.10.30.gem
#官方插件有 bug,不支持 ruby 1.9.*
#fluent-gem install fluent-plugin-scribe -v 0.10.10 
#从我 fork 的分支安装
  rm -rf $install_dir/fluent-plugin-scribe
  fluent-gem uninstall -x fluent-plugin-scribe
cd $install_dir/ 
git clone https://github.com/fishg/fluent-plugin-scribe
cd fluent-plugin-scribe
fluent-gem build fluent-plugin-scribe.gemspec
fluent-gem install fluent-plugin-scribe-0.10.10.gem
  
#/etc/init.d脚本安装
cd /etc/init.d/
wget https://raw.github.com/fishg/fluentd-start/master/fluentd
chmod +x fluentd
cd ~
#==============fluent配置===================
mkdir -p $fluentd_config_dir
cd $fluentd_config_dir
git clone https://github.com/fishg/fluentd-start
cp -r $fluentd_config_dir/fluentd-start/config/* $fluentd_config_dir
mv fluentd-start /tmp/fluentd-start

##启动测试
#fluentd --setup .
#fluentd -c $fluentd_config_dir/fluent.conf  -vv &
#echo '{"json":"message"}' | fluent-cat debug.test
 
##正式启动,如需指定用户:
/etc/init.d/fluentd start
tail -f $fluentd_config_dir/fluent/fluent.log