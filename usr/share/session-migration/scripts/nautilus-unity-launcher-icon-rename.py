#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright (C) 2013 Canonical

from gi.repository import Gio
import os,sys

if "com.canonical.Unity.Launcher" not in Gio.Settings.list_schemas():
    print("No unity schemas found, no migration needed")
    sys.exit(0)

gsettings=Gio.Settings(schema="com.canonical.Unity.Launcher", path="/com/canonical/unity/launcher/")
launcher_list = gsettings.get_strv("favorites")

# Unity used nautilus-home.desktop but we are migrating to use the standard nautilus.desktop instead
try:
    idx=launcher_list.index("application://nautilus.desktop")
    launcher_list[idx]="application://org.gnome.Nautilus.desktop"
except ValueError:
    pass
# gsettings doesn't work directly, the key is somewhat reverted. Work one level under then: dconf!
from subprocess import Popen, PIPE, STDOUT
p = Popen(['dconf', 'load', '/com/canonical/unity/launcher/'], stdout=PIPE, stdin=PIPE, stderr=STDOUT)
p.communicate(input="[/]\nfavorites={}".format(launcher_list).encode('utf-8'))
