require "delegate"
require "parallel"
require "capistrano/central_git/config"

module Capistrano::CentralGit
  class SCM < SimpleDelegator
    def initialize(context)
      super(context)
    end

    def config
      Capistrano::CentralGit::Config
    end

    def sshkit_host
      @sshkit_host ||= SSHKit::Host.new(config.central_host).tap do |h|
        h.ssh_options = config.central_host_ssh_options
      end
    end

    def git(*args)
      args.unshift :git
      execute *args
    end

    def test!(*args)
      __getobj__.test *args
    end

    def test
      test! " [ -d #{config.central_repo_path}/.git ] "
    end

    def check
      git :"ls-remote --heads", repo_url
    end

    def clone
      git :clone, "--recursive", repo_url, config.central_repo_path
    end

    def update
      git :remote, :update
      git :checkout, fetch(:branch)
      git :pull
      git :submodule, :update, "--init"
    end

    def create_package
      excludes = config.excludes.flat_map { |e| ["--exclude", e] }

      tree_top =
        if tree = fetch(:repo_tree)
          tree.slice %r#^/?(.*?)/?$#, 1
        else
          ""
        end

      execute :mkdir, "-p", config.central_packages_path

      within tree_top do
        execute :tar, "zcf", config.central_package_path, *excludes, "."
      end
    end

    def deploy_package
      hosts = ::Capistrano::Configuration.env.filter(release_roles(:all))
      rsync_options = config.rsync_options
      rsync_rsh = config.rsync_rsh
      central_package_path = config.central_package_path
      release_package_path = config.release_package_path
      Parallel.each(hosts, in_threads: config.max_parallels(hosts)) do |host|
        execute :rsync, "#{rsync_options} --rsh='#{rsync_rsh}' #{central_package_path} #{host}:#{release_package_path}"
      end
    end

    def extract_package
      execute :mkdir, "-p", release_path
      execute :tar, "zxf", config.release_package_path, "-C", release_path
    end

    def cleanup_central_packages
      cleanup_packages(config.central_packages_path, config.keep_central_packages)
    end

    def cleanup_release_packages
      cleanup_packages(config.release_packages_path, config.keep_release_packages)
    end

    def fetch_revision
      capture(:git, "rev-list --max-count=1 --abbrev-commit #{fetch(:branch)}").strip
    end

    private

    def cleanup_packages(packages_path, keep_packages)
      packages = capture(:ls, '-xtr', packages_path).split
      if packages.count >= keep_packages
        info t(:keeping_packages, host: host.to_s, keep_packages: keep_packages, packages: packages.count)
        older_packages = (packages - packages.last(keep_packages))
        if older_packages.any?
          older_packages_str = older_packages.map do |package|
            packages_path.join(package)
          end.join(" ")
          execute :rm, '-rf', older_packages_str
        else
          info t(:no_old_packages, host: host.to_s, keep_packages: keep_packages)
        end
      end
    end
  end
end
