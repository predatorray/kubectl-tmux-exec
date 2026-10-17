# kubectl-tmux-exec

![GitHub release version](https://img.shields.io/github/v/release/predatorray/kubectl-tmux-exec)
![License](https://img.shields.io/github/license/predatorray/kubectl-tmux-exec)
![Build Status](https://img.shields.io/github/actions/workflow/status/predatorray/kubectl-tmux-exec/ci.yml?branch=master)
![GitHub all releases](https://img.shields.io/github/downloads/predatorray/kubectl-tmux-exec/total)

A **kubectl** plugin for executing commands interactively across multiple pods or containers using [**tmux**](https://github.com/tmux/tmux),
like `csshX` or `pssh` but for **Kubernetes**.

![screenshot](../assets/screenshot.png?raw=true)

To execute command across all the Nginx containers using `bash` for example, run:

```sh
kubectl tmux-exec -l app=nginx /bin/bash
```

Or, just like `kubectl exec`, but into **all** the pods of a deployment (or any other resource that `kubectl exec` supports):

```sh
kubectl tmux-exec deploy/nginx /bin/bash
```

## Installation 

### Homebrew

> **Note**: This is for Mac users only.

1. Install [Homebrew](https://brew.sh/).

2. `brew install predatorray/brew/kubectl-tmux-exec`

Finally, ensure `/usr/local/bin/kubectl-tmux_exec` is in your `$PATH`.

### Krew

1. Install [Krew](https://krew.sigs.k8s.io/) by following [the user guide](https://krew.sigs.k8s.io/docs/user-guide/setup/install/).

2. `kubectl krew install tmux-exec`

3. Install [`tmux`](https://github.com/tmux/tmux/wiki/Installing).

### Manually

1. Download the [latest release](https://github.com/predatorray/kubectl-tmux-exec/releases/latest).

2. Unpack the `kubectl-tmux-exec-*.tar.gz` file and copy all the files to a directory, `/usr/local/kubectl-tmux-exec` for instance.

3. Add the `bin/` directory to your `$PATH`. For example, add this line to your rc file: `export PATH="$PATH:/usr/local/kubectl-tmux-exec/bin"`.

4. Install [`tmux`](https://github.com/tmux/tmux/wiki/Installing).

## Usage

Make sure you have `kubectl` ≥ 1.12 ([plugin support]), ideally latest.

Otherwise, execute the script directly: `kubectl-tmux_exec [...ARGS]`.

Check if the script has been successfully added by:

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

# or
kubectl-tmux_exec --help
```

### Usage

```sh
kubectl tmux-exec { -l SELECTOR | -f FILE | NAME } [-c CONTAINER] [flags] -- COMMAND [args...]
```

The pods are chosen by exactly one of the following:

- `-l SELECTOR`: all the pods that match the label selector.
- `-f FILE`: the pod names listed line-by-line in a file (or `-` for stdin).
- `NAME`: a pod name, or `TYPE/NAME` of any resource that `kubectl exec` accepts: a pod, service, deployment, replicaset,
  replicationcontroller, statefulset, daemonset or job (e.g. `deploy/nginx`, `sts/web`, `svc/nginx`, `job/backup`).
  The pods are resolved the same way as `kubectl exec` does, except that all of them are chosen instead of only one:
  - for a service, all the pods that match its selector;
  - for a workload, all the pods that match its selector **and** are controlled by it (through its replicasets for a
    deployment), so that other pods that happen to share the same labels are not included.

### Options

| Flag                            | Usage                                                                                                                                                       |
|---------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `-V`<br>`--version`             | Print the version information                                                                                                                               |
| `-l`<br>`--selector`            | Selector (label query) to filter on, supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)<br>You must use either `--selector`, `--file` or a `NAME`. |
| `-f`<br>`--file`                | Read pod names line-by-line from a file.<br>You must use either `--selector`, `--file` or a `NAME`.                                                            |
| `-c`<br>`--container`           | Container name. If omitted, the first container in the pod will be chosen                                                                                   |
| `-i`<br>`--stdin`               | Pass stdin to the container (**deprecated**, since it's enabled by default; using it is an error, see [Deprecated Options](#deprecated-options))              |
| `-t`<br>`--tty`                 | Stdin is a TTY (**deprecated**, since it's enabled by default; using it is an error, see [Deprecated Options](#deprecated-options))                           |
| `-d`<br>`--detach`              | Make the Tmux session detached                                                                                                                              |
| `-n`<br>`--namespace=`          | The namespace scope for this CLI request (can be applied multiple times)                                                                                    |
| `--context`                     | The name of the kubeconfig context to use (can be applied multiple times)                                                                                   |
| `-A`<br>`--all-namespaces`      | If present, list and execute the requested object(s) across all namespaces. Namespace in current context is ignored even if specified with --namespace.     |
| `-C`<br>`--enable-control-mode` | Start tmux in control mode and echo is disabled. (See: [iTerm2 Integration](#iterm2-integration))                                                           |
| `--remain-on-exit`              | Remain Tmux window on exit                                                                                                                                  |
| `--select-layout`               | One of the five Tmux preset layouts: even-horizontal, even-vertical, main-horizontal, main-vertical, or tiled.                                              |
| `--session-mode`                | Where tmux is opened: auto, new-session, current-session                                                                                                    |

The usage of these options is also available by `--help`.

### Deprecated Options

The options `-i` / `--stdin` and `-t` / `--tty` have no effect since both are enabled by default. Previously they were
ignored with a warning; now using either of them fails with an error. To go back to the previous behavior (ignore them
with a warning), set the environment variable `KUBECTL_TMUX_EXEC_ALLOW_DEPRECATED` to any value other than empty or `0`,
e.g. in your shell profile:

```sh
export KUBECTL_TMUX_EXEC_ALLOW_DEPRECATED=1
```

### Example

The `tmux-exec` is similar to `exec`, except that it executes the command in multiple pods at once.

To `bash` into all pod containers that share some common labels, `foo=bar` for instance.

```sh
kubectl tmux-exec -l foo=bar /bin/bash
```

To `bash` into all the pods of the statefulset `web`, in the `nginx` container.

```sh
kubectl tmux-exec sts/web -c nginx /bin/bash
```

After you have successfully `bash`-ed into your selected containers, a Tmux window is opened actually, where each pane displays the execution result of each pod's container. Your keyboard inputs will be synchronized to all those panes.

If you are not familar with Tmux, you can have a look at tmux's man page or online tutorials. Or you can see the [cheatsheet](#tmux-cheatsheet) below, which will be sufficient I think.

### iTerm2 Integration

With `-C` or `--enable-control-mode`, it runs in control mode and delegates pane input to [iTerm2]'s "Broadcast Input" feature,
no need for tmux key bindings.

Use <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>i</kbd> to toggle broadcasting in iTerm2. (`synchronize-panes` will be disabled automatically in this mode.)

(see: [tmux Integration](https://iterm2.com/documentation-tmux-integration.html) for more information)

#### Example

```sh
kubectl tmux-exec -C -l app=nginx /bin/bash
```

![screenshot](../assets/screenshot-iterm2-integration.png?raw=true)

### Shell Auto-completion

Please check [this wiki](https://github.com/predatorray/kubectl-tmux-exec/wiki/Shell-Auto-completion) for more information.

### Tmux Cheatsheet

All Tmux command starts with a `PREFIX`. By default the `PREFIX` is <kbd>Ctrl</kbd> + <kbd>b</kbd>. I will use `C-b` below to stand for it.

`C-b d`, detach from the session. After that, the Tmux will be running in the backgroud. You can type `tmux a` to re-attach.

`C-b :setw synchronize-panes off`, turn off synchronizing inputs to all panes.

`C-b :setw synchronize-panes on`, turn on synchronizing inputs to all panes.

`C-b <ARROW-KEY>`, move cursor between panes.

`C-b xy`, close the current pane.

`C-b &y`, close the window including all panes.

## Community & Support

- File issues or feature requests via [GitHub Issues]((https://github.com/predatorray/kubectl-tmux-exec/issues/new))
- Join the [Google Group](https://groups.google.com/g/kubectl-tmux-exec) for discussions

## Other plugins

[kubectl-alias](https://github.com/predatorray/kubectl-alias): the missing alias command for kubectl.

## Buy Me a Coffee

If it saves you time, feel free to [buy me a coffee] 🙌

[![](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)][buy me a coffee]

[buy me a coffee]: https://buymeacoffee.com/predatorray
[iTerm2]: https://iterm2.com/index.html
[plugin support]: https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/
