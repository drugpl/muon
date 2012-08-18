muon
=================

muon is going to be a distributed time tracking tool. It already tracks time, but it's not distributed yet.

Installation
------------
```
gem install muon
```

Usage
------------
```
cd ~/myproject
muon init
muon start
# do some work
muon stop
muon log
```

You'll find more details via `muon help`.

Configuration
-------------
You can set up some handy aliases:
```
muon config --global alias.a start
muon config --global alias.z stop
muon config --global alias.st status
```

Bash completion
------------
```
source /path/to/muon/extras/muon-completion.bash
```

Bash prompt
------------
```
source /path/to/muon/extras/muon-prompt.bash
```
Then add `$(__muon_ps1)` somewhere in your $PS1, for example:
```
export PS1='\w$(__muon_ps1) \$ '
```
Or with some colors:
```
export PS1='\w\[\033[31m\]$(__muon_ps1) \[\033[00m\]\$ '
```
