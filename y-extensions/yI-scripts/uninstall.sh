# ===========================================================
# yWeb Extension: Uninstall an Extension
# by yjogol
# -----------------------------------------------------------

# -----------------------------------------------------------
# Installer Configs
# -----------------------------------------------------------
yI_version="1.5"

# -----------------------------------------------------------
# Dirs
# -----------------------------------------------------------
y_path_varbin="/var/bin"
y_path_config="/var/tuxbox/config"
y_path_tmp="/tmp"
y_path_install="$y_path_tmp/y-install"
y_ywebover_dir="/var/httpd"
y_ext_conf_dir="$y_path_config/y-ext"

# -----------------------------------------------------------
# Files
# -----------------------------------------------------------
y_config_Y_Web="$y_path_config/Y-Web.conf"
y_config_nhttpd="$y_path_config/nhttpd.conf"
y_config_neutrino="$y_path_config/neutrino.conf"
y_upload_file="$y_path_tmp/upload.tmp"

# ===========================================================
# config-Dateien - lesen / schreiben
# (Zeilenformat: VarName=VarValue)
# ===========================================================
cfg=""

# -----------------------------------------------------------
# config-Datei lesen/cachen (Inhalt in $cfg)
# $1=config-Filename
# -----------------------------------------------------------
config_open()
{
	cfg=""
	cfg=`cat $1`
}

# -----------------------------------------------------------
# config-Datei schreiben (Inhalt in $cfg)
# $1=config-Filename
# -----------------------------------------------------------
config_write()
{
	echo "$cfg" >$1
}

# -----------------------------------------------------------
# Variablenwert zurueckgeben (vorher open)
# $1=VarName
# -----------------------------------------------------------
config_get_value()
{
	cmd="sed -n /^$1=/p"
	tmp=`echo "$cfg" | $cmd`
	cmd="sed -e s/^$1=//1"
	tmp=`echo "$tmp" | $cmd`
	echo $tmp
}

# -----------------------------------------------------------
# Variablenwert zurueckgeben (ohne open)
# $1=config-Filename
# $2=VarName
# -----------------------------------------------------------
config_get_value_direct()
{
	config_open $1
	config_get_value $2
}

# -----------------------------------------------------------
# Variablenwert setzen (vorher open)
# $1=VarName)
# $2=VarValue
# -----------------------------------------------------------
config_set_value()
{
	tmp=`echo "$cfg" | sed -n "/^$1=.*/p"`
	if [ "$tmp" = "" ]
	then
		cfg=`echo -e "$cfg\n$1=$2"`
	else
		cmd="sed -e s/^$1=.*/$1=$2/g"
		cfg=`echo "$cfg" | $cmd`
	fi
}

# -----------------------------------------------------------
# Variablenwert zurueckgeben (ohne open)
# $1=config-Filename
# $2=VarName)
# $3=VarValue
# -----------------------------------------------------------
config_set_value_direct()
{
	config_open $1
	config_set_value $2 $3
	config_write $1
}

# ===========================================================
# Initialization
# ===========================================================
. $y_ext_conf_dir/$1
hp=`config_get_value_direct "$y_config_nhttpd" "WebsiteMain.override_directory"`
if [ "$hp" != "" ]; then
	y_ywebover_dir=`echo "$hp"`
fi
mkdir -p $y_ywebover_dir
 
# -----------------------------------------------------------
# prepare log
# -----------------------------------------------------------
date +%y%m%d_%H%M%S >"$yI_uninstall_log"
echo "" >>"$yI_uninstall_log"
echo "uninstalling $yI_updatename [$yI_ext_tag/$yI_ext_version]" >>"$yI_uninstall_log"
#echo "installdir: $y_ywebover_dir"

# -----------------------------------------------------------
# Uninstall (from <tag>_uninstall.inc)
# -----------------------------------------------------------
uninstall

# -----------------------------------------------------------
# finishing
# -----------------------------------------------------------
rm $y_ext_conf_dir/$1

# -----------------------------------------------------------
# Clean Up
# -----------------------------------------------------------
