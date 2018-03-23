#!/usr/bin/perl -w
#** ------------------------------------------------------------------
#** Подготовка среды для развёртывания сервиса
#** ------------------------------------------------------------------
# nam: CargoZavr project auto installer
# vsn: 0.0.6
# dsc: Tries to install and prepare your env to use CargoZarv project automatically
# crt: Пн мар  5 21:24:56 MSK 2018
# upd: Пт мар 23 21:45:53 MSK 2018
# ath: Michael DARIN, Moscow, Russia, (c) 2018
# lic: gnu>=2, "AS-IS", "NO WARRENTY"
# cnt: darin.m@tvzavr.ru
# 
##
# ChangeLog
# 0.0.1 использовался глобальный sudo, утанка от root
# 0.0.2 ближе к инструкции используется sudo для нужных команд, установка от $user
#       утановил всё окружение вроде бы без проблем
# 0.0.3 генерирование и раскладывание конфигов, доработка процесса установки всё собирается
# 0.0.4 введены первые опции управления установкой
# 0.0.5 реализована настройка процедуры развёртывания(не в полном объёме ещё)
#				добавлен хелп
# 0.0.6	добавлена обрабокта опци usage, version, instll
#				реализованы условаия отображения предупреждения установки по умолчанию
#				справочные сообщения на русском(наверное лучше и на английском)
#				изменён шаблон конфига nginx, изменён под новую архитектуру
#				начаты работы по добавлению шагов утановки(удаление пакетов, старых
#					возможность доустановки postgresql и развёртываение БД cargo
#					redis и emqtt брокера
# 0.0.7 добавлена установка emqtt
#				добавлен режим тихие игры(silent) 
#				добалено изменение файла package.json
use warnings;
use strict;
use File::Basename qw(basename dirname);
use File::Spec;
use Getopt::Long;
use autodie;

my $usage = q(
  Использование: cazavr {опция[=значение]}
);

my $default_config_warn = q(
	ВНИМАНИЕ! Процедура установки запустится с 
		  настройками по умалчанию!

	Если вы хотите настроить процедуру, передав желаемые
	параметры для установки, нажмите комбинацию ctrl+'c' 
	и заупустите 	программу с нужными опциями.
	Если вы хотите ознакомиться со всеми опциями,
	запустите программу с опцией --help для вызова
	справки.
	Если настройки по умлчанию вас устраивают,
	подождите, установка сейчас начнётся...
);
# насколько жу это проще на английском блеать...
#	WARNING! Installation is going to be started with 
#		 default configuration!
#	
#	For configuring the installation params, press ctrl+'c' 
#	and run the script with --help option for more details 
#	abuot how to exactly configure the installation script.
#	Or stay be waiting for to contine installation with defaults.
#
#);

my $help = q(
cazavr 0.0.7 (amd64)
Использование: cazavr {опция[=значение]}

cazavr — сервис автоматического развёртывания проeкта cargo с 
интерфейсом командной строки, предоставляет команды для настройки 
процедуры развертывания.

Основные параметры и команды:
  ---- минимально необходимые пакеты для запуска ----
  no-git - не устанавливать git
  no-clone - не клонировать проект
  no-nginx - не устанавливать nginx
  no-nodejs - не устанавливать nodejs и npm
  no-erlang - не устанавливать erlang
  no-gulp - не устанавливать gulp
  ---- полностью автономный локальный сервис ---- 
  no-emqtt - не устанавливать emqttd
  no-postgresql - не расворачивать CarogDB/postgresql
  no-redis - не утанавливать redis 
  ---- настройка параметров сборки самого сервиса ----
  install - установить и собрать проект без окружения
  help - показать это справочное сообщение
  verbose - максимально информативный вывод
  silent - без лишних коментариев
  version - показать версию 
  usage - показать краткую справку по использованию
  log=Logfile - задать файл журнала регистрации хода установки
  git-user=Username - задать имя пользователя для работы с git
  git-passwd=Password - задать пароль пользователя для работы с git
  root-passwd=Rootpassword - задать пароль суперпользователя(root)
  cargo-root=Relativpath - задать желаeмый относительнй каталог для клонироваия
  server-port=Port - задать порт на котором будет доступна страница
		

Дополнительную информацию о доступных командах смотрите в wiki.
Параметры настройки и синтаксис описаны в wiki.
Информацию о том, как настроить источники, можно найти в wiki.
Выбор пакетов и версий описывается через ?.
В cazavr есть шарм старушки Шапокляк и равнодушие Сергея Шнурова.
);

my $version = q(
cazavr v0.0.6
);

# получить аргументы командной строки
my %options;
GetOptions("no-git" => \$options{"no-git"},
						"no-clone" => \$options{"no-clone"},
					 	"no-nginx" => \$options{"no-nginx"},
					 	"no-erlang" => \$options{"no-erlang"},
					 	"no-nodejs" => \$options{"no-nodejs"},
						"no-gulp" => \$options{"no-gulp"},
						"no-emqtt" => \$options{"no-emqtt"},
						"no-postgresql" => \$options{"no-postgresql"},
						"no-redis" => \$options{"no-redis"},
						"install" => \$options{"install"},
						"git-user=s" => \$options{"git-usr"},
						"git-passwd=s" => \$options{"git-passwd"},
						"root-passwd=s" => \$options{"root-passwd"},
						"server-port=s" => \$options{"server-port"},
						"cargo-root=s" => \$options{"cargo-root"},
						"log=s" => \$options{"log"},
						"help" => \$options{"help"},
						"usage" => \$options{"usage"},
						"version" => \$options{"version"},
						"silent" => \$options{"silent"},
						"verbose" => \$options{"verbose"},
           	"outfile=s" => \$options{"outfile"}
          )
  or die("$0:Error in command line arguments\n");

#while ( my($key, $value) = each %options) {
	#print "$key -> $value\n";
#}
# есклю включена опция утановить и собрать проект
# то сбросить флаги устанвоки программ окружения
if ($options{"install"}) {
	print ">>> " . "install selected, no-git no-erlang no-nginx no-gulp no-nodejs ENABLED!" . "\n";
	$options{"no-git"} = 1;
	$options{"no-nginx"} = 1;
	$options{"no-erlang"} = 1;
	$options{"no-gulp"} = 1;
	$options{"no-nodejs"} = 1;
}
my @keys = keys %options;



# показать справочное сообщение со скиском и описание доступных команд
die "$0:$help"
	if ($options{"help"});
# показать короткую српавку по использованию команды
die "$0:$usage"
	if ($options{"usage"});
# показать версию
die "$0:$version"
	if ($options{"version"});
#die "stop";

# режим вывода(vervose by default)
my $output_mode = "";
# устанвить режим тихой устанвоки
$output_mode = " 2>&1 1>/dev/zero"
	if ($options{"silent"});
#TODO(darin-m): добвить вывод в лог и т.п.

# понять кто я
my $user = `whoami`;
chomp $user;
print ">>> " . "user: " . $user . "\n";
# получить пароль суперпользвоателя для запуска sudo
my $passwd = $options{"root-passwd"} || "111111111"; # defaut password :)
print ">>> " . "root password: " . "$passwd" . "\n";
# получить домашний каталог
my $home_dir = $ENV{HOME};
print ">>> " . "home: " . $home_dir . "\n";
# подготовить структуру каталогов?
# каталог с шаблонами конфигов
my $templates_dir = File::Spec->catfile(dirname($0), "templates");
print ">>> " . "templates: $templates_dir" . "\n";
# это путь потом надо будет в конфигах nginx использовать как параметр корня
my $default_cargo_root = File::Spec->catfile("code", "cargo");
# подготовить шаблоны файлов для замены, прям суда их запихнуть чтоб не терялись...
my $cargo_root = $options{"cargo-root"} || $default_cargo_root;
print ">>> " . "relative cargo root: " . $cargo_root . "\n";
my $full_path_to_root = File::Spec->catfile($home_dir, $cargo_root);
print ">>> " . "absolut cargo root: " . $full_path_to_root . "\n";
my $port = $options{"server-port"} || "8000"; # default port
print ">>> " . "cargo port:" . $port . "\n";
# TODO: надо доработать логику этого сообщения
# дать предупреждение если используются настройки по умолчанию и выдержать таймаут
warn $default_config_warn
	unless (defined($options{"cargo-root"}) 
					or defined($options{"server-port"}) 
					or defined($options{"root-passwd"}));
sleep 30;
#sleep 20; # показать настройки пользователю
#die "stop";
# Клон проекта через HTTP
# тут надо проверить наличие гитика, если его нет то установить
unless ($options{"no-git"}) {
	my $git_res = `git --version` || "";
	chomp $git_res;
	print " * " . "$git_res" . "\n"
		if ($git_res ne "");
	system("echo $passwd | sudo -S apt-get install -y git")
		if ($git_res eq "");
	# проверить установку 
	$git_res = `git --version`;
	chomp $git_res;
	print ">>> " . "[ ok ] git is installed!\n"
		if ($git_res ne "");
	print ">>> clonnig cargo to your root directory: " . $full_path_to_root . "\n";
}

unless ($options{"no-clone"}) {
	# удалять каталог если он есть и содержимое в мём перед клонироваем
	system("rm -rf $full_path_to_root")
		if -e $full_path_to_root;
	# клонируем прект cargo по указанному пути
	# TODO: тут надо пользователя же вводить!!
	system("git clone http://code.tvzavr.ru/cargo/cargo.git $full_path_to_root");
	#
	# Настройка chicagoboss
	#взять у коллег файл boss.conf (чистый кастом)
	#и положить его в корень проекта (каталог называется cargo это корень(root))
	#должно получиться так
	#/paht/to/project/rootdir/cargo/boss.conf
	print ">>> " . "generating boss.config file...\n";
	# открыть файл шаблона boss.config на в
#TODO(darin-m): добвить вывод в лог и т.п.вод
	my $boss_conf_tpl_fname = File::Spec->catfile($templates_dir, "boss.config.tpl");
	open FIN, "<$boss_conf_tpl_fname"
		or die "$0:Cannot open $boss_conf_tpl_fname:$!";
	#открыть целевой файл генерируемого конфига на вывод
	my $boss_conf_target_fname = File::Spec->catfile($templates_dir, "boss.config");
	open FOUT, ">$boss_conf_target_fname"
		or die "$0:Cannot open $boss_conf_target_fname:$!";
	#прогнать через преобразователь
	map { chomp;
		# TODO: здесь вставить правила преобразования
		print FOUT "$_\n";
	} <FIN>;
	#закрыть файл шаблона
	close FIN
		or die "$0:Cannot close $boss_conf_tpl_fname:$!";
	#закрыть файл конфига
	close FOUT
		or die "$0:Cannot close $boss_conf_target_fname:$!";
	#перемесить сгенерированный кофиг в каталог /etc/nginx
	system("mv $boss_conf_target_fname $full_path_to_root");
}

unless ($options{"no-nginx"}) {
	# Установка nginx
	# проверить не установлени ли nginx
	my $nginx_res = `nginx -v 2>&1` ||  "";
	chomp $nginx_res;
	print " * " . "$nginx_res". "\n"
		if ($nginx_res ne "");
	# даём команду на установку
	system("echo $passwd | sudo -S apt-get install -y nginx $output_mode")
		if ($nginx_res eq "");
	# проверить устанвоку
	$nginx_res =  `nginx -v 2>&1` || "";
	chomp $nginx_res;
	print ">>> " . "[ ok ] nginx is installed!\n"
		if ($nginx_res ne "");
	# затем надо заменить файл
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
		or die "$0:Cannot open $nginx_conf_tpl_fname:$!";
	#открыть целевой файл генерируемого конфига на вывод
	my $nginx_conf_target_fname = File::Spec->catfile($templates_dir, "nginx.conf");
	open FOUT, ">$nginx_conf_target_fname"
		or die "$0:Cannot open $nginx_conf_target_fname:$!";
	#прогнать через преобразователь
	map { chomp;
		# TODO: здесь вставить правила преобразования
		if (s/\$\{port\}/$port/) {
			print FOUT "$_\n";
		} elsif (s/\$\{cargo_root\}/$full_path_to_root/) {
			print FOUT "$_\n";
		} else {
			print FOUT "$_\n";
		}
	} <FIN>;
	#закрыть файл шаблона
	close FIN
		or die "$0:Cannot close $nginx_conf_tpl_fname:$!";
	#закрыть файл конфига
	close FOUT
		or die "$0:Cannot close $nginx_conf_target_fname:$!";
	#сделать резервную копию существующего файла если он есть
	system("echo $passwd | sudo -S mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak");
	#перемесить сгенерированный кофиг в каталог /etc/nginx
	system("echo $passwd | sudo -S mv $nginx_conf_target_fname /etc/nginx");
	# открыть файл шаблона cargo.config на ввод
	my $cargo_conf_tpl_fname = File::Spec->catfile($templates_dir, "cargo.conf.tpl");
	open FIN, "<$cargo_conf_tpl_fname"
		or die "$0:Cannot open $cargo_conf_tpl_fname:$!";
	#открыть целевой файл генерируемого конфига на вывод
	my $cargo_conf_target_fname = File::Spec->catfile($templates_dir, "cargo.conf");
	open FOUT, ">$cargo_conf_target_fname"
		or die "$0:Cannot open $cargo_conf_target_fname:$!";
	#прогнать через преобразователь
	map { chomp;
		# TODO: здесь вставить правила преобразования
		if (s/\$\{port\}/$port/) {
			print FOUT "$_\n";
		} elsif (s/\$\{cargo_root\}/$full_path_to_root/) {
			print FOUT "$_\n";
		} else {
			print FOUT "$_\n";
		}
	} <FIN>;
	#закрыть файл шаблона
	close FIN
		or die "$0:Cannot close $cargo_conf_tpl_fname:$!";
	#закрыть файл конфига
	close FOUT
		or die "$0:Cannot close $cargo_conf_target_fname:$!";
	#перемесить сгенерированный кофиг в каталог /etc/nginx
	system("echo $passwd | sudo -S mv $cargo_conf_target_fname /etc/nginx/conf.d");
	#nginx надо запустить или перезапустить
	system("echo $passwd | sudo -S service nginx restart");
	#и проверить запущен ли он(не возникло ли ошибок в ходе запуска) 
	$nginx_res = `echo $passwd | sudo -S service nginx status`;
	if ($nginx_res =~ /Active:\s*active/gim) {
		print ">>> " . "[ ok ] nginx is running...\n";
	}
}

unless ($options{"no-nodejs"}) {
	# Установка nodejs и npm
	# проверям не установлена ли нода node -v
	#вот тут срослось
	#https://nodejs.org/en/download/package-manager/#debian-and-ubuntu-based-linux-distributions
	#[opt] если его нету то надо поставить перед установкой
	my $curl_res = `curl --version` || "";
	chomp $curl_res;
	print " * " . "$curl_res" . "\n"
		if ($curl_res ne "");
	system("echo $passwd | sudo -S apt-get install -y curl $output_mode")
		if ($curl_res eq "");
	# проверим установку
	$curl_res = `curl --version` || "";
	chomp $curl_res;
	print ">>> " . "[ ok ] curl is installed!\n"
		if ($curl_res ne "");
	#TODO: проверяем не установлена ли нода(кстати если установлена и не та, её надо бы снести и так со всем...)
	my $node_res = `node -v` || "";
	chomp $node_res;
	print " * " . "node $node_res" . "\n"
		if ($node_res ne "");
	# првоверяем не установлен ли манагер пакетный npm-v
	my $npm_res = `npm -v` || "";
	chomp $npm_res;
	print " * " . "npm $npm_res" . "\n"
		if ($npm_res ne "");
	if ($node_res eq "") {
		# подготовим пакет нужной версии (сейчас на март 2018 это версия 8 для ноды
		#curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
		system("echo $passwd | sudo -S curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - $output_mode");
		# установим саму ноду
		system("echo $passwd | sudo -S apt-get install -y nodejs $output_mode");
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
}

unless ($options{"no-erlang"}) {
	# Установка erlang 20
	# Adding repository entry
	#To add Erlang Solutions repository (including our public key for apt-secure) 
	#to your system, call the following commandsi and install esl-erlang
	chdir "/tmp";
	system("wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb $output_mode");
	system("echo $passwd | sudo -S dpkg -i erlang-solutions_1.0_all.deb $output_mode");
	system("echo $passwd | sudo -S apt-get update $output_mode");
	system("echo $passwd | sudo -S apt-get install -y esl-erlang $output_mode");
	unlink "erlang-solutions_1.0_all.deb"
		or warn "$0:Cannot delete erlang-solutions_1.0_all.deb:$!";
	chdir "$full_path_to_root";
}

unless ($options{"no-emqtt"}) {
	#TODO:emqtt install and config
	#Сборка emqtt c github:
	chdir "/tmp";
  system("git clone https://github.com/emqtt/emq-relx.git $output_mode");
	chdir "/tmp/emq-relx";
	system("make $output_mode");
	# make install может он там есть?
	# запуск в ручную
  #cd _rel/emqttd
	#./bin/emqttd console
	# удадалить исходники полсле устанвоки
	system ("rm -rf /tmp/emq-relx");
	# вернуться в рабочий каталог
	chdir "$full_path_to_root";
}


unless ($options{"no-redis"}) {
	#TODO: redis install and config
	print ">>> " . "[WARN] Redis installation is not implemented yet!" . "\n";
}

unless ($options{"no-postgresql"}) {
	#TODO: postgresql install, config and land cargo db
	print ">>> " . "[WARN] PostgreSQL installation is not implemented yet!" . "\n";
}

# Сборка и подготовка к пуску
#Перейти в корень проекта
#cd /paht/to/project/rootdir/cargo
chdir $full_path_to_root;
#и последовательно выполнить команды
print ">>> " . "installing..." . "\n";
system("npm install $output_mode");
print ">>> " . "building..." . "\n";
system("npm run build $output_mode");

unless ($options{"no-gulp"}) {
	#установить gulp, дав следующую команду
	# проверить наличие (уточнить не --vesrsion ли???
	my $gulp_res = `gulp -v` || "";
	chomp $gulp_res;
	print " * " . "$gulp_res" . "\n"
		if ($gulp_res ne "");
	# его скорей всего не будет, поэтому 
	system("echo $passwd | sudo -S npm i -g gulp $output_mode");
}


# TODO: надо бы проверять не зупущен ли gulp...
# если не заупущен, то запускать
# надо ли её двать, если надо то можно её в bg дать или ваще форкнуть в процесс отдельный...
#по окончании подать сигнал
#ctrl+’c’
# процесс и так отомрёт..
print ">>> " . "starting gulp in detached process..." . "\n";
defined (my $gulp_pid = fork) 
	or die "$0:Cannot fork: $!";
unless ($gulp_pid) {
	# и дать в консоли команду
	# надо ли её двать, если надо то можно её в bg дать или ваще форкнуть в процесс отдельный...
	#print "<gulp." . $gulp_pid . "> >>> " . "system(\"cd $full_path_to_root\")\n";
	chdir $full_path_to_root;	
	#print "<gulp." . $gulp_pid . "> >>> " . "system(\"gulp\")\n";
	exec("gulp");	
	#по окончании подать сигнал
	#ctrl+’c’ просто прибить процесс по окончании основногkkkjо процесса и всё...  
}

#скачать зависимости
print ">>> " . "gethering deps..." . "\n";
system("./rebar get-deps $output_mode");
#скомпилировать зависимости
print ">>> " . "compiling..." . "\n";
system("./rebar compile $output_mode");

# завершить проецсс с gulp'ом
# хотя это бессмысленно...
#kill 0, $gulp_pid
#	or die "Cannot signal $gulp_pid whith SIGINT: $!";

#Если заменить в package.json:
#"scripts": {
#    "test": "echo \"Error: no test specified\" && exit 1",
#    "start": "./init-dev.sh"
#  },
#то запуск через команду
#npm run start
# открыть файл pacage.json
print ">>> " . "modifieng package.json -> \"start\": \"./init-dev.sh\" added\n";
	my $package_json_fname = File::Spec->catfile($full_path_to_root, "package.json");
	open FIN, "<$package_json_fname"
		or die "$0:Cannot open $package_json_fname:$!";
	#открыть новый файл с добавленной строкой для запуска
	my $package_json_new_fname = File::Spec->catfile($full_path_to_root, "package.json.new");
	open FOUT, ">$package_json_new_fname"
		or die "$0:Cannot open $package_json_new_fname:$!";
	#прогнать через преобразователь
	map { chomp;
		# TODO: здесь вставить правила преобразования
		if (m/(\s*)(\"test\")[^:]*(:)\s*(.+)/) {
			print FOUT "$1$2$3$4,\n";
			print FOUT "$1\"start\": \"./init-dev.sh\"\n";
		} else {
			print FOUT "$_\n";
		}
	} <FIN>;
	#закрыть файл шаблона
	close FIN
		or die "$0:Cannot close $package_json_fname:$!";
	#закрыть файл конфига
	close FOUT
		or die "$0:Cannot close $package_json_new_fname:$!";
# заменить файлы
unlink "$package_json_fname";
system "mv $package_json_new_fname $package_json_fname";

print ">>> " . "  *** DONE :) ***\n";
print "\n\n\t Start the server by ./init-dev command\n\t\tor npm run star command.\n\n\n";
#waitpid($gulp_pid, 0);


