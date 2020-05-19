# kubectl-tmux-exec

[![homebrew](https://img.shields.io/badge/homebrew-0.0.4-orange)](https://brew.sh/)
[![krew](https://img.shields.io/badge/krew-0.0.4-blue)](https://krew.sigs.k8s.io/)
![license](https://img.shields.io/badge/license-MIT-green)

A kubectl plugin that controls multiple pods simultaneously using [Tmux](https://github.com/tmux/tmux).

![screenshot](../assets/screenshot.png?raw=true)

It is to `kubectl exec` as `csshX` or `pssh` is to `ssh`.

Instead of `exec bash` into multiple pod's containers one-at-a-time, like `kubectl exec pod{N} /bin/bash`.

You can now use

```sh
kubectl tmux-exec -l app=nginx /bin/bash
```

# Installation 

## via Homebrew

> **Note**: This is for Mac users only.

1. Install [Homebrew](https://brew.sh/).

2. `brew install predatorray/brew/kubectl-tmux-exec`

The script should be installed under `/usr/local/bin/kubectl-tmux_exec` by default. Please ensure the `bin` directory is in your `$PATH` environment variable.

## via Krew

> **Note**: It is recommended for Linux users.
> 
> Although it works both on Mac and Linux, it is not recommended for Mac users, since you still may need to install the dependency `gnu-getopt` with the help of Homebrew.

1. Install [Krew](https://krew.sigs.k8s.io/) by following [the user guide](https://krew.sigs.k8s.io/docs/user-guide/setup/install/).

2. `kubectl krew install tmux-exec`

3. Install the dependencies. ([Wiki: How-to-Install-Dependencies](https://github.com/predatorray/kubectl-tmux-exec/wiki/How-to-Install-Dependencies))

# Usage

To execute this script as a [plugin]((https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/)), a `kubectl` version prior to `1.12.0` is required and the latest version is preferred. But you can execute the script directly like `kubectl-tmux_exec [...ARGS]` if it is not supported.

If it is supported, you can check if the script has been added to kubectl's plugin list by

```sh
kubectl plugin list
```

The output should be like

```txt
The following compatible plugins are available:

/usr/local/bin/kubectl-tmux_exec
```

If it does not show in the list, check `$PATH` env again.

You can use the command below to get the usage of the script.

```sh
kubectl tmux-exec --help
```

Or, execute it directly.

```
kubectl-tmux_exec --help
```

## Options

Flag | Usage
--- | ---
`-l`<br>`--selector` | Selector (label query) to filter on, supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)<br>You must either use `--selector` or `--file` option.
`-f`<br>`--file` | Read pod names line-by-line from a file.<br>You must either use `--selector` or `--file` option.
`-c`<br>`--container` | Container name. If omitted, the first container in the pod will be chosen
`-i`<br>`--stdin` | Pass stdin to the container (**deprecated**, since it's enabled by default)
`-t`<br>`--tty` | Stdin is a TTY (**deprecated**, since it's enabled by default)
`-d`<br>`--detach` | Make the Tmux session detached
`--remain-on-exit` | Remain Tmux window on exit
`--select-layout` | One of the five Tmux preset layouts: even-horizontal, even-vertical, main-horizontal, main-vertical, or tiled.

The usage of these options is also available by `--help`.

## Example

The `tmux-exec` is similar to `exec`, except that it requires label selectors while `exec` requires a pod name.

To `bash` into all pod containers that share some common labels, `foo=bar` for instance.

```sh
kubectl tmux-exec -l foo=bar /bin/bash
```

After you have successfully `bash`-ed into your selected containers, a Tmux window is opened actually, where each pane displays the execution result of each pod's container. Your keyboard inputs will be synchronized to all those panes.

If you are not familar with Tmux, you can have a look at tmux's man page or online tutorials. Or you can see the cheatsheet below, which will be sufficient I think.

## Tmux cheatsheet

All Tmux command starts with a PREFIX. By default the PREFIX is `ctrl+b`. I will use `C-b` below to stand for it.

`C-b d`, detach from the session. After that, the Tmux will be running in the backgroud. You can type `tmux a` to re-attach.

`C-b :setw synchronize-panes off`, turn off synchronizing inputs to all panes.

`C-b :setw synchronize-panes on`, turn on synchronizing inputs to all panes.

`C-b <ARROW-KEY>`, move cursor between panes.

`C-b xy`, close the current pane.

`C-b &y`, close the window including all panes.

# Support

Please feel free to [open an issue](https://github.com/predatorray/kubectl-tmux-exec/issues/new) if you find any bug or have any suggestion.
