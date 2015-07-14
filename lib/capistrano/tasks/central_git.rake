unless defined?(Capistrano::CentralGit::TASK_LOADED)
Capistrano::CentralGit::TASK_LOADED = true

require "capistrano/central_git/scm"

namespace :central_git do

  def central_git_scm
    @central_git_scm ||= Capistrano::CentralGit::SCM.new(self)
  end

  def run_central(&block)
    SSHKit.config.backend.new(central_git_scm.sshkit_host, &block).run
  end

  def central_path
    central_git_scm.config.central_path
  end

  def central_repo_path
    central_git_scm.config.central_repo_path
  end

  def central_packages_path
    central_git_scm.config.central_packages_path
  end

  def release_packages_path
    central_git_scm.config.release_packages_path
  end

  set :git_environmental_variables, ->() {
    {
      git_askpass: "/bin/echo",
      git_ssh:     "#{fetch(:tmp_dir)}/#{fetch(:application)}/git-ssh.sh"
    }
  }

  desc "Upload the git wrapper script, this script guarantees that we can script git without getting an interactive prompt"
  task :wrapper do
    run_central do
      execute :mkdir, "-p", "#{fetch(:tmp_dir)}/#{fetch(:application)}/"
      upload! StringIO.new("#!/bin/sh -e\nexec /usr/bin/ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no \"$@\"\n"), "#{fetch(:tmp_dir)}/#{fetch(:application)}/git-ssh.sh"
      execute :chmod, "+x", "#{fetch(:tmp_dir)}/#{fetch(:application)}/git-ssh.sh"
    end
  end

  desc "Check that the repository is reachable"
  task check: :"central_git:wrapper" do
    fetch(:branch)
    run_central do
      with fetch(:git_environmental_variables) do
        central_git_scm.check
      end
      execute :mkdir, "-p", central_path
    end

    on release_roles :all do |host|
      execute :mkdir, "-p", release_packages_path
    end
  end

  desc "Clone the repo to the cache"
  task clone: :"central_git:wrapper" do
    run_central do
      if central_git_scm.test
        info t(:mirror_exists, at: central_repo_path)
      else
        with fetch(:git_environmental_variables) do
          central_git_scm.clone
        end
      end
    end
  end

  desc "Update the repo mirror to reflect the origin state"
  task update: :"central_git:clone" do
    run_central do
      within central_repo_path do
        with fetch(:git_environmental_variables) do
          central_git_scm.update
        end
      end
    end
  end

  desc "Copy repo to releases"
  task create_release: :"central_git:update" do
    run_central do
      within central_repo_path do
        central_git_scm.create_package
        central_git_scm.deploy_package
      end
    end

    on release_roles :all do
      within releases_path do
        central_git_scm.extract_package
      end
    end
  end

  desc 'Determine the revision that will be deployed'
  task :set_current_revision do
    run_central do
      within central_repo_path do
        with fetch(:git_environmental_variables) do
          set :current_revision, central_git_scm.fetch_revision
        end
      end
    end
  end

  desc "Cleanup packages"
  task cleanup: :"deploy:cleanup" do
    run_central do
      within central_packages_path do
        central_git_scm.cleanup_packages
      end
    end
  end

  desc "Show configurations"
  task :config do
    config = central_git_scm.config
    hosts = ::Capistrano::Configuration.env.filter(release_roles(:all))

    pairs = {
      repo_url: fetch(:repo_url),
      repo_tree: fetch(:repo_tree),
      central_host: config.central_host,
      central_path: config.central_path,
      central_repo_path: config.central_repo_path,
      central_packages_path: config.central_packages_path,
      deploy_to: fetch(:deploy_to),
      release_packages_path: config.release_packages_path,
      excludes: config.excludes.join(" "),
      rsync_options: config.rsync_options,
      rsync_rsh: config.rsync_rsh,
      max_parallels: config.max_parallels(hosts),
      keep_packages: config.keep_packages,
    }

    max_key_length = pairs.keys.map { |k| k.to_s.length }.max
    col = max_key_length + 2
    pairs.each do |key, value|
      puts "#{key.to_s.rjust(col)}    #{value}"
    end

  end
end

end
