# kubectl-tmux-exec

A kubectl plugin that uses [Tmux](https://github.com/tmux/tmux) to multiplex commands to pods.

It is to `kubectl exec` as `csshX` or `pssh` is to `ssh`.

Instead of `exec bash` into multiple pod's containers one-at-a-time, like `kubectl exec -it pod{N} /bin/bash`.

You can now use

```sh
kubectl tmux-exec -it -l app=nginx /bin/bash
```

# Installation via Homebrew

If you do not have Homebrew installed on your mac, please follow [its installation instruction](https://brew.sh/).

After that, execute the command below.

```sh
brew install predatorray/brew/kubectl-tmux-exec
```

The script should be installed under `/usr/local/bin/kubectl-tmux_exec` by default. Please ensure the `bin` directory is in your `$PATH` environment variable.

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

## Example

The `tmux-exec` is similar to `exec`, except that it requires label selectors while `exec` requires a pod name.

To `bash` into all pod containers that share some common labels, `foo=bar` for instance.

```sh
kubectl tmux-exec -it -l foo=bar /bin/bash
```

It should be noted that the `-i` / `--stdin` and `-t` / `--tty` options must both be turned on when you are trying to initiate an interactive session. If not, there will not be any errors. Instead, the `tmux` process simply exits because the `exec`-ed command exits due to no inputs.

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
