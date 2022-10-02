# ===========================================================
# yWeb: Extention Uninstaller Include
# Extention Name: example menu
# ===========================================================

yI_updatename="yWeb-Extension Example Menu"
yI_ext_tag="example-menu"
yI_ext_version="0-0-1"
yI_install_log="${y_path_tmp}/install_{$yI_ext_tag}.log"
yI_uninstaller="${yI_ext_tag}_uninstall.sh"

uninstall()
{
	rm $y_ywebover_dir/Y_Ext_Example_Menu.yhtm
}
