#!/usr/bin/env python3
"""Linexin Launcher: its Recent Apps / Recent Files view stayed empty. modelForRow() isn't a notifying
binding, so the view kept the null it got before the root model was filled. Re-read it whenever the
root model refills. Takes the path to RecentView.qml; does nothing if it's already patched."""
import sys
path = sys.argv[1]
s = open(path).read()
if "rootRevision" in s:
    sys.exit(0)
old = '''    readonly property var recentModel: (categoryRow.currentCategory >= 0
                                        && categoryRow.currentCategory < root.recentRowCount)'''
new = '''    // lorien-rice: modelForRow() isn't a notifying binding, so the view kept the null it got before the
    // root model was filled (the history looked empty). Re-read it whenever the root model refills.
    property int rootRevision: 0
    Connections {
        target: rootModel
        function onRefreshed() { recentView.rootRevision++; }
        function onCountChanged() { recentView.rootRevision++; }
    }
    readonly property var recentModel: (recentView.rootRevision >= 0
                                        && categoryRow.currentCategory >= 0
                                        && categoryRow.currentCategory < root.recentRowCount)'''
if old not in s:
    print("Linexin Launcher changed upstream; Recent view patch skipped.")
    sys.exit(0)
open(path, "w").write(s.replace(old, new, 1))
