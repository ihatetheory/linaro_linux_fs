import os
import re

import apport.packaging
import apport.hookutils

def mask_string (str):
    MASK = '##MASKED##'
    return str.group(1) + MASK

def mask_values(gconfinfo):
    """ strip personal/private information from the GConf entries """
    pattrn = re.compile ('((add_dir|library_locations|download_prefix|share_password|share_name|username|password)=)(.*)$',
    re.IGNORECASE)
    newReport = ""
    for line in gconfinfo.splitlines():
        line = pattrn.sub (mask_string, line)
        newReport += line + '\n'
    return newReport

def add_info(report, ui):
    response = ui.choice("How would you describe the issue?", [
            "problem with the interface",
            "problem with sound",
            "problem with playback of audio files",
            "other problem",
            ], False)

    if response == None: # user cancelled
        raise StopIteration
# TODO: port to gsettings
#    if response[0] == 0: # an issue about rhythmbox interface
#        apport.hookutils.attach_gconf(report, 'rhythmbox')
#        report['GConfNonDefault'] = mask_values(report['GConfNonDefault'])
    if response[0] == 1: # the issue is a sound one
        os.execlp('apport-bug', 'apport-bug', 'audio')
    if response[0] == 2: # the issue is a codec one
        report.add_package_info("libgstreamer1.0-0")
        return

    report["LogAlsaMixer"] = apport.hookutils.command_output(["/usr/bin/amixer"])
    report["GstreamerVersions"] = apport.hookutils.package_versions("gstreamer*")
    report["XorgLog"] = apport.hookutils.read_file("/var/log/Xorg.0.log")
