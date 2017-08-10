from apport.hookutils import attach_gsettings_package

def add_info(report):
    attach_gsettings_package(report, 'gnome-panel-data')
