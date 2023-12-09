# git-ssh-helper
An oh-my-zsh assistant plugin for managing multiple git account with different ssh keys per repo.

## [Function]
When there are multiple git(hub) accounts with different ssh key bound; It is often trivial to handle with the keys.
One approach is to access the remote repo via `GIT_SSH_COMMAND`, which would be like:
```bash
GIT_SSH_COMMAND="ssh -i /path/to/key/file" git pull origin xxx-branch
```
But if you do not want to type the environment variable every time, this plugin may help.
Each time when entering a folder which is a `git repo`, this plugin reminds you to set an unique ssh key per-repo. The next time when accessing remote repos, specified keys will be leveraged.

## [Usage]

### Step 1:
Put ./git-ssh-helper/ folder under path: ${HOME}/.oh-my-zsh/custom/plugins/

### Step 2:
Add plugin via .zshrc; inside the plugin section:

> plugins=(... git-multi-sshacc-asst ...)

### Step 3:
Restart the shell or run `source ${HOME}/.zshrc'
