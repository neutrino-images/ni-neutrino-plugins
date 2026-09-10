# Neutrino Lua plugin scripts

Deutsch: [README.de.md](README.de.md)

Lua plugins for Neutrino, one per directory under `plugins/`. Beside
them `share/lua/5.2/n_gui.lua` and `n_helpers.lua`, helpers that ship
as a package of their own, and `xupnpd/`, content files for the xupnpd
media server. The image recipes fetch the tip of `master` from here
whenever they build with network access, so what is pushed here is in
the next build.

Under `plugins/` two kinds of plugin sit side by side. Most are
directories with their files in this repository. Four are git
submodules with a repository of their own: `logoupdater`,
`neutrino-mediathek`, `stb_startup` and `webmin-setup`. A submodule
entry is a *pin*, the commit it points at; git calls the entry a
*gitlink*. The goal is one repository per plugin; the directories are
the part not split out yet.

**In one sentence:** a plugin that lives here is fixed and pushed here;
a submodule plugin is fixed in its own repository, and the pin here
follows on its own, the superproject `plugins` after it.

## Contents

1. [Clone](#clone)
2. [Change a plugin that lives here](#change-a-plugin-that-lives-here)
3. [Change a submodule plugin](#change-a-submodule-plugin)
4. [What happens on its own](#what-happens-on-its-own)
5. [Commit subjects](#commit-subjects)
6. [Split a plugin out](#split-a-plugin-out)

## Clone

With the submodules, or the four are empty directories:

```bash
git clone --recursive https://github.com/tuxbox-neutrino/plugin-scripts-lua.git
cd plugin-scripts-lua
git submodule status                # no line starting with "-"
```

## Change a plugin that lives here

Everything under `plugins/<name>/` that is not a submodule. Test the
change on a box before pushing; the next image build ships it.

```bash
cd plugins/<name>                   # e.g. plugins/webtv
$EDITOR <file>
git add . && git commit -m "fix (<name>): ..."
git push
git log -1 origin/master            # your commit at the tip
```

## Change a submodule plugin

`plugins/logoupdater`, `plugins/neutrino-mediathek`,
`plugins/stb_startup`, `plugins/webmin-setup`. Work in the plugin's own
repository, which is the checkout below that path. A fresh clone leaves
it detached on the pin, so switch to its branch first — `master` for
all four:

```bash
cd plugins/<name>
git switch master && git pull
$EDITOR <file>
git add . && git commit -m "fix (<name>): ..."
git push
git log -1 origin/master            # in the plugin repository
```

The pin here follows on its own (next section). To move it at once,
back in this repository:

```bash
cd ../..                            # the root of plugin-scripts-lua
git submodule update --remote plugins/<name>   # fetch the plugin's master
git diff --submodule=log            # what the pin moves over: the text for the subject
git add plugins/<name>
git commit -m "chore (plugins): <name>: <what moved>"
git push
```

## What happens on its own

The workflow `update-submodule-pins.yml` runs every hour (scheduled at
:17; GitHub often starts it a few minutes late), moves each of the four
pins to the tip of the plugin's branch and pushes the result as
`GitHub Actions <actions@github.com>`. Nothing triggers on push. The
superproject `plugins`, which links this repository as `scripts-lua`,
runs the same procedure at :47, so a plugin fix travels both levels
without waiting for a second full cycle.

To have it now instead: Actions → *Update submodule pins* → *Run
workflow*, or with the GitHub CLI (`gh`). The run commits and pushes a
pin bump to `master`, the same one the timer would make later:

```bash
gh workflow run update-submodule-pins.yml -R tuxbox-neutrino/plugin-scripts-lua --ref master
gh run list -R tuxbox-neutrino/plugin-scripts-lua -L 1   # the run and its result
```

How the pin commit is worded, which branch a pin follows and what to do
when the workflow is down is described in the superproject's README under
[What happens on its own](https://github.com/tuxbox-neutrino/plugins#what-happens-on-its-own).
Note that commit subjects there follow a different form than here.

## Commit subjects

From now on `<type> (<scope>): <summary>`, at most 72 columns, the
scope being the plugin directory or the script inside it that changed:

```
fix (yt_live): escape the ampersands in the channel list
chore (plugins): drop the stale stb_startup copy
```

Older commits do not follow this yet; new ones do.

## Split a plugin out

The goal is a repository per plugin, named `plugin-lua-<name>` with
underscores turned into dashes (`stb_startup` → `plugin-lua-stb-startup`;
`neutrino-mediathek` is the historical exception). Create the repository
under `tuxbox-neutrino/` and move the files there with their history,
then replace the directory here with the pin:

```bash
git rm -r plugins/<name>
git submodule add ../plugin-lua-<name>.git plugins/<name>
git commit -m "build (plugins): link <name> as a submodule"
git ls-tree HEAD plugins/<name>     # "160000 commit ...": a gitlink now
```

In the same step, point the plugin's recipe in `meta-neutrino` at the
new repository: the recipes extract `plugins/<name>` from this
repository, and that extraction finds nothing behind a gitlink. Recipe
names differ from directory names; find the recipe by its source name
(a recipe without `SRC_NAME` uses its own name):

```bash
grep -rl 'SRC_NAME = "<name>"' meta-neutrino/recipes-neutrino/neutrino-plugins-lua/
```
