#!/usr/bin/perl -w
#** ------------------------------------------------------------------
#** Подготовка среды для развёртывания сервиса
#** ------------------------------------------------------------------
# nam: CargoZavr project auto installer
# vsn: 0.0.1
# dsc: Tries to install and prepare your env to use CargoZarv project automatically
# crt: 3 22:19:56 MSK 2018
# upd:
# ath:
# lic: 
# cnt: 
# 
##

use warnings;
use strict;
use File::Basename qw(basename dirname);
use File::Spec;
use autodie;

# Обязатетельыне аргументы передаваемы при запуске
# пароль root для sudo 
# желаемый каталог в кторый склонируется проект, без HOME! либо прдётся чистить...
# пользователь git
# пароль для git
#
my $usage = "Usage: install.pl rootpasswd path/to/project gituser gitpasswd ....";

die $usage
	if (4 > @ARGV);


print ">>> agrgumers: @ARGV" . "\n";

# понять кто я
# whoame
my $user = `whoami`;
chomp $user;
print ">>> user: " . $user . "\n";
# получить домашний каталог
# $HOME
print ">>> home directory: " . $ENV{HOME} . "\n";
# подготовить структуру каталогов?
# $HOME/code/cargo
# это путь потом надо будет в конфигах nginx использовать как параметр корня

# подготовить шаблоны файлов для замены, прям суда их запихнуть чтоб не терялись...
print ">>>" . " default directory: $ENV{HOME}/code" . "\n";

#** ------------------------------------------------------------------
#** Подготовка среды для развёртывания сервиса
#** ------------------------------------------------------------------

#0. Клон проекта через HTTP
#пока заведено что проект расположен по такому пути /home/user/code/ user инменно user никаких фривольностей :)
#git clone http://code.tvzavr.ru/cargo/cargo.git
# тут надо проверить наличие гитика, если его нет то установить
#git --version
#print ">>> " . `git --version` . "\n";
my $git_res = `git --version`;
chomp $git_res;
print " * " . "$git_res" . "\n";
#git version 2.7.4
print ">>> sudo apt install git\n"
	if ($git_res eq "");
# проверить установку 
$git_res = `git --version`;
chomp $git_res;
print ">>> " . "[ ok ] git installed!\n"
	if ($git_res ne "");
print ">>> clonnig directory: " . "git clone http://code.tvzavr.ru/cargo/cargo.git " . $ENV{HOME} . "/code" . "\n";
#после установки должно получится так:
#/home/user/code/cargo 
#это будет корень(root) проекта

#всё это не железно и гвоздями не приколочено, просто настройка конфигов в ручную(пока) это потеря времени и лишняя головная боль

#chicagoboss уже там вмонтажен. его не надо искать

#1. Установка nginx
# проверить не установлени ли? что-то типа nginx --version
print ">>> " . `nginx --version` . "\n";
my $nginx_res = `nginx --version`;
print " * " . "$nginx_res". "\n"
	if ($nginx_res eq "");
#даём команду на установку
#sudo apt install nginx
print ">>> sudo apt install nginx\n"
	if ($nginx_res eq "");
# проверить устанвоку
print ">>> " . `nginx --version` . "\n";
#затем надо заменить файл
#(я перед заменой сделал cp nginx.conf nginx.conf.bac :)
#/ect/nginx/nginx.conf на наш nginx.conf 
#и в каталог /etc/nginx/conf.d
#скопировать файл cargo.conf
#получится результат
#/etc/nginx/conf.d/cargo.conf
print ">>> configureing nginx...\n";
#эти файлы надо брать у коллег (чистый кастом местного розлива)

#nginx надо запустить или перезапустить
#sudo service nginx restart
print ">>> sudo service nginx restart\n";
#и проверить запущен ли он(не возникло ли ошибок в ходе запуска) 
#sudo service nginx status
print ">>> sudo service nginx status\n";
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
print ">>> " . `node -v` . "\n";
# првоверяем не установлен ли манагер пакетный npm-v
print ">>> " . `npm -v` . "\n";
#6..@...
#вот тут срослось
#https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions


#[opt] если его нету то надо поставить перед установкой
#curl -v если нету то надо его ставить
print ">>> " . `curl --version` . "\n";
#sudo apt install curl
print ">>> " . "sudo apt install curl" . "\n";
#curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
print ">>> " . "curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -\n";
#sudo apt-get install -y nodejs
print ">>> " . "sudo apt-get install -y nodejs\n";

#3. Установка erlang 19
#зависимости не дали мне с ходу поставить эту версию(19.2.3)
#у меня не были установлены wxWidgets для GUI и херь какая то ещё libsctp1
#
#                       libwxbase3.0-0 but it is not installable or
#                       libwxbase3.0-0v5 but it is not going to be installed
#              Depends: libwxgtk2.8-0 but it is not installable or
#                       libwxgtk3.0-0 but it is not installable or
#                       libwxgtk3.0-0v5 but it is not going to be installed
#              Depends: libsctp1 but it is not going to be installed

#ставим зависимости(надеюсь не придётся их парсить и обрабатывать...)
#sudo apt install libsctp1
#sudo apt install libwxbase3.0-0v5 libwxgtk3.0-0v5
print ">>> " . "sudo apt install libsctp1\n";
print ">>> " . "sudo apt install libwxbase3.0-0v5 libwxgtk3.0-0v5\n";
#затем скачиваем erlang c https://www.erlang-solutions.com/resources/download.html
#(там внизу в табличке надо выбрать подходящую версию пакета)
# тут если не прокатит оффициальная версия прдётся выбирать версию по ОС
print ">>> " . `uname -a` . "\n";
print ">>> " . `lsb_release -a` . "\n";
#версия на 15 февраля 2018 используется 18
#хочу поставить 20(20.2.2)
#{как это автоматом делать?}
#качаем и переходим в каталог загрузки
#cd /path/to/downloads/
#у меня несколько версий и команда ls даёт такой результат
#ls esl-erlang_*
#esl-erlang_18.3.4-1~ubuntu~xenial_amd64.deb  esl-erlang_20.2.2-1~ubuntu~xenial_amd64.deb
#esl-erlang_19.3.6-1~ubuntu~xenial_amd64.deb
print ">>> cd " . "$ENV{HOME}/Downloads\n";
#теперь устанавливаем, здесь при помощи dpkg
#(я хочу попробовать версию 20.2.2 потому пока в примере будет такая)
#dpkg -i esl-erlang_20.2.2-1~ubuntu~xenial_amd64.deb
print ">>> dpkg -i esl-erlang_20.2.2-1~ubuntu~xenial_amd64.deb\n";
#после установки даём команду в консоли
#erl
#и должна высыпаться строка приветствия эрлангконсольки с версией
#Erlang/OTP 20 [erts-9.2] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false]

#Eshell V9.2  (abort with ^G)
#1>
#для выхода q().

#4. Настройка chicagoboss
#взять у коллег файл boss.conf (чистый кастом)
#и положить его в корень проекта (каталог называется cargo это корень(root))
#должно получиться так
#/paht/to/project/rootdir/cargo/boss.conf
print ">>> " . "generating boss.conf file...\n";

#5. Сборка и подготовка к пуску
#Перейти в корень проекта
#cd /paht/to/project/rootdir/cargo
print ">>> " . "cd $ENV{HOME}/code/cargo\n";
#и последовательно выполнить команды
#npm install
print ">>> " . "npm install\n";
#...подождать выполнения...

#У меня warn'ы
#npm WARN Project@1.0.0 No repository field.
#npm WARN optional SKIPPING OPTIONAL DEPENDENCY: fsevents@1.1.3 (node_modules/fsevents):
#npm WARN notsup SKIPPING OPTIONAL DEPENDENCY: Unsupported platform for fsevents@1.1.3: wanted {"os":"darwin","arch":"any"} (current: {"os":"linux","arch":"x64"})

#установить gulp, дав следующую команду
# проверить наличие (уточнить не --vesrsion ли???
print ">>> " . `gulp -v` . "\n";
# его скорей всего не будет, поэтому 
#sudo npm i -g gulp вот так её надо установить
print ">>> " . "sudo npm i -g gulp\n";
#и дать в консоли команду
# надо ли её двать, если надо то можно её в bg дать или ваще форкнуть в процесс отдельный...
#gulp
#по окончании подать сигнал
#ctrl+’c’

#скачать зависимости
#./rebar get-deps
print ">>> " . "./rebar get-deps\n";
#скомпилировать зависимости
#./rebar compile
print ">>> " . "./rebar compile\n";

print ">>> " . "DONE :)\n";
#запуск сервера
#./init-dev.sh 

#Если заменить в package.json:
#"scripts": {
#    "test": "echo \"Error: no test specified\" && exit 1",
#    "start": "./init-dev.sh"
#  },
#то запуск через команду
#npm run start
my $passwd = "111111111";
my $cmd = "echo $passwd | sudo -S fdisk -l";
my $res = `$cmd`;
print " ---- " . "$res" . "\n";

my $cmd1 = "echo $passwd | sudo -S service networking status";
my $res1 = `$cmd1`;
print " --- " . "$res1" . "\n";
if ($res1 =~ m/Active: active .exited./gim) {
	print ">>> " . "[ ok ] running...\n";
}
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
