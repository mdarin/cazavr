#!/usr/bin/perl -w
#** ------------------------------------------------------------------
#** Подготовка среды для развёртывания сервиса
#** ------------------------------------------------------------------
# nam: CargoZavr project auto installer
# vsn: 0.0.2
# dsc: Tries to install and prepare your env to use CargoZarv project automatically
# crt: Пн мар  5 21:24:56 MSK 2018
# upd:
# ath:
# lic: 
# cnt: 
# 
##
# ChangeLog
# 0.0.1 использовался глобальный sudo, утанка от root
# 0.0.2 ближе к инструкции используется sudo для нужных команд, установка от $user
#       утановил всё окружение вроде бы без проблем
use warnings;
use strict;
use File::Basename qw(basename dirname);
use File::Spec;
use autodie;
# TODO: use Opt::Long для опций
# Обязатетельыне аргументы передаваемы при запуске
# ?пароль root для sudo 
# желаемый каталог в кторый склонируется проект, без HOME! либо прдётся чистить...
# пользователь git
# пароль для git
# имя сервера
# порт на котором будет дотупен сайт
my $usage = q(Usage: 
	sudo install.pl rootpasswd path/to/project gituser gitpasswd 
	...);

#die $usage
#	if (4 > @ARGV);


print ">>> agrgumers: @ARGV" . "\n";
print ">>> path templates: " . File::Spec->catfile(dirname($0), "templates") .  " \n";
# понять кто я
# whoamakdf
my $user = `whoami`;
chomp $user;
print ">>> user: " . $user . "\n";
#die "	You shoul be a root or run with sudo!"
#	if ($user ne "root");
# получить пароль суперпользвоателя для запуска sudo
my $passwd = $ARGV[1] || "111111111"; # defaut password :)
print ">>> rootpassword: " . "$passwd" . "\n";
# получить домашний каталог
# $HOME
my $home_dir = $ENV{HOME};
print ">>> home directory: " . $home_dir . "\n";
# подготовить структуру каталогов?
# $HOME/code/cargo
# каталог с шаблонами конфигов
my $templates_dir = File::Spec->catfile(dirname($0), "templates");
print ">>> " . "templates: $templates_dir" . "\n";
# это путь потом надо будет в конфигах nginx использовать как параметр корня
my $default_cargo_root = File::Spec->catfile("code", "cargo");
# подготовить шаблоны файлов для замены, прям суда их запихнуть чтоб не терялись...
my $cargo_root = $ARGV[4] || $default_cargo_root;
my $full_path_to_root = File::Spec->catfile($home_dir, $cargo_root);
print ">>> " . "cargo root directory: " . $full_path_to_root . "\n";
my $port = $ARGV[5] || "8000"; # default port
print ">>> port:" . $port . "\n";
# 
#	sup(install.pl) fork -> 
#		[worker1 "apt-get install git
#		[worker2 "apt-get install nginx]
#		[worker3 "apt-get intall node] 
#		and so on...

#0. Клон проекта через HTTP
#пока заведено что проект расположен по такому пути /home/user/code/ user инменно user никаких фривольностей :)
#git clone http://code.tvzavr.ru/cargo/cargo.git
# тут надо проверить наличие гитика, если его нет то установить
my $git_res = `git --version` || "";
chomp $git_res;
print " * " . "$git_res" . "\n"
	if ($git_res ne "");
#print ">>> 
system("echo $passwd | sudo -S apt-get install -y git")#\n"
	if ($git_res eq "");
# проверить установку 
$git_res = `git --version`;
chomp $git_res;
print ">>> " . "[ ok ] git is installed!\n"
	if ($git_res ne "");
print ">>> clonnig cargo to your root directory: " . $full_path_to_root . "\n";
#после установки должно получится так:
#/home/user/code/cargo 
#это будет корень(root) проекта
# TODO: тут надо удалять каталог если он есть и содержимое в мём перед клонироваем
# и создавать если всего этого нету...
#всё это не железно и гвоздями не приколочено, просто настройка конфигов в ручную(пока) это потеря времени и лишняя головная боль
# клонируем прект cargo по указанному пути
# TODO: тут надо пользователя же вводить!!
#print ">>> " . "
system("git clone http://code.tvzavr.ru/cargo/cargo.git $full_path_to_root");# . "\n";
#
#chicagoboss уже там вмонтажен. его не надо искать
#
# Настройка chicagoboss

#взять у коллег файл boss.conf (чистый кастом)
#и положить его в корень проекта (каталог называется cargo это корень(root))
#должно получиться так
#/paht/to/project/rootdir/cargo/boss.conf
print ">>> " . "generating boss.config file...\n";
# открыть файл шаблона boss.config на ввод
my $boss_conf_tpl_fname = File::Spec->catfile($templates_dir, "boss.config.tpl");
open FIN, "<$boss_conf_tpl_fname"
	or die "Cannot open $boss_conf_tpl_fname:$!";
#открыть целевой файл генерируемого конфига на вывод
my $boss_conf_target_fname = File::Spec->catfile($templates_dir, "boss.config");
open FOUT, ">$boss_conf_target_fname"
	or die "Cannot open $boss_conf_target_fname:$!";
#прогнать через преобразователь
map { chomp;
	# TODO: здесь вставить правила преобразования
	print FOUT "$_\n";
} <FIN>;
#закрыть файл шаблона
close FIN
	or die "Cannot close $boss_conf_tpl_fname:$!";
#закрыть файл конфига
close FOUT
	or die "Cannot close $boss_conf_target_fname:$!";
#перемесить сгенерированный кофиг в каталог /etc/nginx
system("mv $boss_conf_target_fname $full_path_to_root");

# Установка nginx
# проверить не установлени ли? что-то типа nginx -v
my $nginx_res = `nginx -v 2>&1` ||  "";
chomp $nginx_res;
print " * " . "$nginx_res". "\n"
	if ($nginx_res ne "");
# даём команду на установку
# sudo apt install nginx
#print ">>> ". "
system("echo $passwd | sudo -S apt-get install -y nginx")#\n"
	if ($nginx_res eq "");
# проверить устанвоку
$nginx_res =  `nginx -v 2>&1` || "";
chomp $nginx_res;
print ">>> " . "[ ok ] nginx is installed!\n"
	if ($nginx_res ne "");
# затем надо заменить файл
# (я перед заменой сделал cp nginx.conf nginx.conf.bac :)
# /ect/nginx/nginx.conf на наш nginx.conf 
# и в каталог /etc/nginx/conf.d
# скопировать файл cargo.conf
# получится результат
# /etc/nginx/conf.d/cargo.conf
print ">>> configureing nginx...\n";
# эти файлы надо брать у коллег (чистый кастом местного розлива)
# открыть файл шаблона nginx.config на ввод
my $nginx_conf_tpl_fname = File::Spec->catfile($templates_dir, "nginx.conf.tpl");
open FIN, "<$nginx_conf_tpl_fname"
	or die "Cannot open $nginx_conf_tpl_fname:$!";
#открыть целевой файл генерируемого конфига на вывод
my $nginx_conf_target_fname = File::Spec->catfile($templates_dir, "nginx.conf");
open FOUT, ">$nginx_conf_target_fname"
	or die "Cannot open $nginx_conf_target_fname:$!";
#прогнать через преобразователь
map { chomp;
	# TODO: здесь вставить правила преобразования
	print FOUT "$_\n";
} <FIN>;
#закрыть файл шаблона
close FIN
	or die "Cannot close $nginx_conf_tpl_fname:$!";
#закрыть файл конфига
close FOUT
	or die "Cannot close $nginx_conf_target_fname:$!";
#сделать резервную копию существующего файла если он есть
system("echo $passwd | sudo -S cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak");
#перемесить сгенерированный кофиг в каталог /etc/nginx
system("echo $passwd | sudo -S mv $nginx_conf_target_fname /etc/nginx");

# открыть файл шаблона cargo.config на ввод
my $cargo_conf_tpl_fname = File::Spec->catfile($templates_dir, "cargo.conf.tpl");
open FIN, "<$cargo_conf_tpl_fname"
	or die "Cannot open $cargo_conf_tpl_fname:$!";
#открыть целевой файл генерируемого конфига на вывод
my $cargo_conf_target_fname = File::Spec->catfile($templates_dir, "cargo.conf");
open FOUT, ">$cargo_conf_target_fname"
	or die "Cannot open $cargo_conf_target_fname:$!";
#прогнать через преобразователь
map { chomp;
	# TODO: здесь вставить правила преобразования
	if (s/\$\{port\}/$port/) {
		print FOUT "$_\n";
	} elsif (s/\$\{cargo_root\}/$cargo_root/) {
		print FOUT "$_\n";
	} else {
		print FOUT "$_\n";
	}
} <FIN>;
#закрыть файл шаблона
close FIN
	or die "Cannot close $cargo_conf_tpl_fname:$!";
#закрыть файл конфига
close FOUT
	or die "Cannot close $cargo_conf_target_fname:$!";
#перемесить сгенерированный кофиг в каталог /etc/nginx
system("echo $passwd | sudo -S mv $cargo_conf_target_fname /etc/nginx/conf.d");

#nginx надо запустить или перезапустить
#sudo service nginx restart
#print ">>> 
system("echo $passwd | sudo -S service nginx restart");#\n";
#и проверить запущен ли он(не возникло ли ошибок в ходе запуска) 
#sudo service nginx status
#print ">>> \
$nginx_res = `echo $passwd | sudo -S service nginx status`;#\n";
if ($nginx_res =~ /Active:\s*active/gim) {
	print ">>> " . "[ ok ] nginx is running...\n";
}
#если всё хорошо, то появится приблизительно следующее:
#Контролить зелёненький :)
#● nginx.service - A high performance web server and a reverse proxy server
#   Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
#   Active: active (running) since Пт 2018-02-16 15:40:37 MSK; 58s ago
#  Process: 20469 ExecStop=/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.p
#  Process: 20476 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUC
#  Process: 20472 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, sta
# Main PID: 20477 (nginx)
#   CGroup: /system.slice/nginx.service
#           ├─20477 nginx: master process /usr/sbin/nginx -g daemon on; master_process on
#           ├─20478 nginx: worker process                           
#           ├─20479 nginx: worker process                           
#           ├─20480 nginx: worker process                           
#           └─20481 nginx: worker process                         

#2. Установка nodejs и npm
# проверям не установлена ли нода node -v
#8.
#вот тут срослось
#https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions

#[opt] если его нету то надо поставить перед установкой
#curl -v если нету то надо его ставить
my $curl_res = `curl --version` || "";
chomp $curl_res;
print " * " . "$curl_res" . "\n"
	if ($curl_res ne "");
#sudo apt install curl
#print ">>> " . "
system("echo $passwd | sudo -S apt-get install -y curl")#\n"
	if ($curl_res eq "");
# проверим установку
$curl_res = `curl --version` || "";
chomp $curl_res;
print ">>> " . "[ ok ] curl is installed!\n"
	if ($curl_res ne "");
# проверяем не установлена ли нода(кстати если установлена и не та, её надо бы снести и так со всем...)
my $node_res = `node -v` || "";
chomp $node_res;
print " * " . "node $node_res" . "\n"
	if ($node_res ne "");
# првоверяем не установлен ли манагер пакетный npm-v
my $npm_res = `npm -v` || "";
chomp $npm_res;
print " * " . "npm $npm_res" . "\n"
	if ($npm_res ne "");
#6..@... 
if ($node_res eq "") {
	# подготовим пакет нужной версии (сейчас на март 2018 это версия 8 для ноды
	#curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
	#print ">>> " . "
	system("echo $passwd | sudo -S curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -");#\n";
	# установим саму ноду
	#sudo apt-get install -y nodejs
	#print ">>> " . "
	system("echo $passwd | sudo -S apt-get install -y nodejs");#\n";
}
$node_res = `node -v` || "";
chomp $node_res;
print ">>> " . "[ ok ] node is installed!\n"
	if ($node_res ne "");
# првоверяем не установлен ли манагер пакетный npm-v
$npm_res = `npm -v` || "";
chomp $npm_res;
print ">>> " . "[ ok ] npm is installed!\n"
	if ($npm_res ne "");

#3. Установка erlang 20
# Adding repository entry
#To add Erlang Solutions repository (including our public key for apt-secure) 
#to your system, call the following commandsi and install esl-erlang
#print ">>> " . "
chdir "/tmp";# . "\n";
#print ">>> " . "
system("wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb");#" . "\n";
#print ">>> " . "
system("echo $passwd | sudo -S dpkg -i erlang-solutions_1.0_all.deb");#" . "\n";
#print ">>> " . "
system("echo $passwd | sudo -S apt-get update");#" . "\n";
#print ">>> " . "
system("echo $passwd | sudo -S apt-get install -y esl-erlang");#" . "\n";
unlink "erlang-solutions_1.0_all.deb"
	or warn "Cannot delete erlang-solutions_1.0_all.deb:$!";
#print ">>> " . "
chdir "$full_path_to_root";# . "\n";

#5. Сборка и подготовка к пуску
#Перейти в корень проекта
#cd /paht/to/project/rootdir/cargo
chdir $full_path_to_root;
#и последовательно выполнить команды
#npm install
#print ">>> " . "
system("npm install");#\n";
#...подождать выполнения...

#У меня warn'ы
#npm WARN Project@1.0.0 No repository field.
#npm WARN optional SKIPPING OPTIONAL DEPENDENCY: fsevents@1.1.3 (node_modules/fsevents):
#npm WARN notsup SKIPPING OPTIONAL DEPENDENCY: Unsupported platform for fsevents@1.1.3: wanted {"os":"darwin","arch":"any"} (current: {"os":"linux","arch":"x64"})

#установить gulp, дав следующую команду
# проверить наличие (уточнить не --vesrsion ли???
my $gulp_res = `gulp -v` || "";
chomp $gulp_res;
print " * " . "$gulp_res" . "\n"
	if ($gulp_res ne "");
# его скорей всего не будет, поэтому 
#sudo npm i -g gulp вот так её надо установить
#print ">>> " . "
system("echo $passwd | sudo -S npm i -g gulp");#\n";
#и дать в консоли команду
# надо ли её двать, если надо то можно её в bg дать или ваще форкнуть в процесс отдельный...
#gulp
#по окончании подать сигнал
#ctrl+’c’
# процесс и так отомрёт..
defined (my $gulp_pid = fork) 
	or die "Cannot fork: $!";
unless ($gulp_pid) {
	# и дать в консоли команду
	# надо ли её двать, если надо то можно её в bg дать или ваще форкнуть в процесс отдельный...
	print "<gulp." . $gulp_pid . "> >>> " . "system(\"cd $full_path_to_root\")\n";
	chdir $full_path_to_root;	
	print "<gulp." . $gulp_pid . "> >>> " . "system(\"gulp\")\n";
	exec("gulp");	
	#по окончании подать сигнал
	#ctrl+’c’ просто прибить процесс по окончании основногkkkjо процесса и всё...  
}
# parent
#sleep(15);
#скачать зависимости
#./rebar get-deps
#print ">>> " . "
system("./rebar get-deps");#\n";
#скомпилировать зависимости
#./rebar compile
#print ">>> " . "
system("./rebar compile");#\n";

# завершить проецсс с gulp'ом
# хотя это бессмысленно...
kill 0, $gulp_pid
	or die "Cannot signal $gulp_pid whith SIGINT: $!";
#запуск сервера
#./init-dev.sh 

print ">>> " . "  *** DONE :) ***\n";
print "\n\n\t Start the server by ./init-dev command\n\tor nmp run start(in progress:))\n\n\n";
#waitpid($gulp_pid, 0);

#TODO: надо это вмотраживать при установке тоже
#Если заменить в package.json:
#"scripts": {
#    "test": "echo \"Error: no test specified\" && exit 1",
#    "start": "./init-dev.sh"
#  },
#то запуск через команду
#npm run start


# -----------------------------------------------------------
# разинца запуск с sudo и с паролем
# какой вариант выбрать?
#print " &&&& " . `fdisk -l` . "\n";
#my $passwd = "111111111";
#my $cmd = "echo $passwd | sudo -S fdisk -l";
#my $res = `$cmd`;
#print " ---- " . "$res" . "\n";

#my $cmd1 = "echo $passwd | sudo -S service networking status";
#my $res1 = `$cmd1`;
#print " --- " . "$res1" . "\n";
#if ($res1 =~ m/Active: active .exited./gim) {
#	print ">>> " . "[ ok ] running...\n";
#}
# ----------------------------------------------------------

# 
#system("ls -l");
#exec("ls -l");

#defined (my $pid = fork)
#	of die "Cannot fork: $!";
#unless ($pid) {
	# child prcess
#}
# parent



#После чего, перейти по ссылке: http://localhost

#Должна появиться страница следующего содержания:
#Welcome to nginx!

#If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

#For online documentation and support please refer to nginx.org.
#Commercial support is available at nginx.com.

#Thank you for using nginx.

#тут ещё были танцы с конфигами нжинкса в части путей к проекту и корня..
#в общем надо разобраться..

#если всё с настройками правильно, у меня установлен порт 8000
#то должна запустится страничка CargoNet
#http://localhost:8000

#у меня сервер завёлся после того, как я удалил все зависимости
#./rebar delete-deps
#./rebar clean

#установил erlang 18(см установку эрланга)

#повторил пункты
#скачать зависимости
#./rebar get-deps
#скомпилировать зависимости
