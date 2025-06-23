# Provision

This repository contains my personal bootstrap script to fully automate the setup of a new development machine on either macOS or Linux. It lays the foundation for my environment by installing essential tools and orchestrating configuration management.

> Disclaimer: It's important to note that this script has been specifically tailored for my personal workflow. It is not intended to be a tool-agnostic solution. The most significant dependency is the use of Bitwarden for secret management, accessed via the `rbw` command-line tool. If you plan to adapt this script for your own use, you will need to modify the authentication phase to work with your preferred secrets manager.

## Prerequisites

Before running the bootstrap script, you must have the following prepared:

1. GitHub Repositories: You must have two repositories pushed to your GitHub account:

   - Ansible Repository (Private Recommended): A repository containing your Ansible playbooks. The name must match the `ANSIBLE_REPO` variable in the script _(default: ansible-personal-workstation)._

   - Chezmoi Dotfiles Repository: A repository managed by Chezmoi. The name must match the `DOTFILES_REPO` variable _(default: dotfiles)._

2. A Bitwarden Account with your credentials ready.
3. **An SSH Key Stored Correctly in Bitwarden:** You must store your private SSH key using one of the two methods below. The item must be named `GITHUB_ZZH_PRIVATE_ZEY`

   - **Option 1 (Note):** In Bitwarden, create a **Note** item and paste the entire private key into the main notes field.
   - **Option 2 (Login):** Create a **Login** item and paste the entire private key into the **password field**.

   _(Do not use the dedicated "SSH Key" item type for this bootstrap process, as it is designed for a different workflow.)_

4. The corresponding public SSH key added to your GitHub account.

## Provisioning new machine (no dependencies)

1. **[Download `bootstrap.sh`](https://raw.githubusercontent.com/gnohj/provision/main/bootstrap.sh)**
   _(You can right-click the link and select "Save Link As...")_
2. **Open Terminal**

```bash
chmod +x bootstrap.sh

./bootstrap.sh \
  your_email@example.com \
  your_github_username \
  your_dotfiles_repo_name (optional, default: dotfiles) \
  your_ansible_repository_base_path (optional, default: $HOME) \
  ansible_repo_name (optional, default: ansible-personal-workstation)



ex: ./bootstrap.sh \
     foo@bar.com \
     foobar \
     dotfiles
     ~/Repositories \
     my_ansible_repo
```

## After the bootstrap

Once the initial setup is complete, you will manage your system by making changes in your Git repositories and then applying them. Here is where to find them:

### Managing System Packages & Applications (Ansible)

    Location: The Ansible repository is cloned to the location you specified when first bootstrapping, or your home directory by default.

      e.g., ~/ansible-personal-workstation or ~/Repositories/ansible-personal-workstation

    Workflow: To install a new application or change a system setting:

        cd into your Ansible repository.

        Edit the relevant playbook file (e.g., main.yml).

        Commit and push your changes with Git.

        Run ansible-playbook main.yml --ask-become-pass on your machine to apply the changes.

_Reference: For more details, see the official [Ansible Playbook Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html)_

### Managing Dotfiles (Chezmoi)

    Location: Chezmoi clones your dotfiles repository to a standard, hidden location:

      e.g, ~/.local/share/chezmoi

    Workflow: To edit a dotfile (like your .zshrc or .gitconfig):

        Recommended Method: Use the chezmoi command. It will find the source file for you and open it in your editor.

        chezmoi edit ~/.zshrc

        After saving your changes, run chezmoi apply to make them live.

        Direct Method: You can also cd ~/.local/share/chezmoi, edit the files directly, and use standard git commands to commit and push your changes.

_Reference: For more details, see the official [Chezmoi Operation Documentation](https://www.chezmoi.io/user-guide/daily-operations/)_

### Syncing with different machines

- Update system applications and packages

```bash
cd ~/Developer/ansible-personal-workstation # Or wherever you cloned it
git pull
ansible-playbook main.yml --ask-become-pass
```

- Update dotfiles

```bash
chezmoi update
```
