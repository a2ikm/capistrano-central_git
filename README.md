# Capistrano::CentralGit

**Note that this product is still under development. So they can be changed without notices.**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano-central_git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-central_git

## Usage

In Capfile:

```ruby
require "capistrano/setup"
require "capistrano/deploy"
require "capistrano/central_git"
```

In config/deploy.rb:

```ruby
set :deploy_to, "/var/www/my-app"
set :repo_url, "git@github.com:you/my-app.git"

set :scm, :central_git
set :central_host, "your-build-server"
set :central_path, "/home/you/central_git"
```

And make sure that:

- Your central_host can access to release servers via ssh.
- Your central_host includes rsync.

## Configurations

| Name | Default | Description |
|---|---|---|
| repo_url | | |
| repo_tree | `nil` | |
| branch | master | |
| ssh_options | {} | |
| keep_releases | 5 | |
| scm | `nil` | | Must be `central_git` |
| central_host | `nil` | |
| central_host_ssh_options | {} | |
| central_path | /var/www/#{application} | |
| central_repo_path | #{central_path}/repo | |
| central_packages_path | #{central_path}/packages |
| deploy_to | /var/www/#{application} | |
| release_packages_path | #{deploy_to}/packages | |
| excludes | [] | |
| rsync_options | -al | |
| rsync_rsh | /usr/bin/ssh | |
| max_parallels | number of hosts | |
| keep_central_packages | 5 | |

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/a2ikm/capistrano-central_git.

