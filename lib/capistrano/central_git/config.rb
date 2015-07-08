module Capistrano::CentralGit
  class Config
    def self.package_name
      @package_name ||= fetch(:package_name, "#{fetch(:release_timestamp)}.tar.gz")
    end

    def self.central_path
      @central_path ||= Pathname.new(fetch(:central_path, "/var/www/#{fetch(:application)}"))
    end

    def self.central_repo_path
      @central_repo_path ||= Pathname.new(fetch(:central_repo_path, central_path.join("repo")))
    end

    def self.central_packages_path
      @central_packages_path ||= Pathname.new(fetch(:central_packages_path, central_path.join("packages")))
    end

    def self.central_package_path
      @central_package_path ||= Pathname.new(fetch(:central_package_path, central_packages_path.join(package_name)))
    end

    def self.release_packages_path
      @release_packages_path ||= Pathname.new(fetch(:release_packages_path, shared_path.join("packages")))
    end

    def self.release_package_path
      @release_package_path ||= Pathname.new(fetch(:remote_packge_path, release_packages_path.join(package_name)))
    end

    def self.excludes
      @excludes ||= fetch(:excludes, []).push(".git").uniq
    end

    def self.central_host
      @central_host ||= fetch(:central_host)
    end

    def self.central_host_ssh_options
      @central_host_ssh_options ||= fetch(:central_host_ssh_options) || fetch(:ssh_options, {})
    end

    def self.rsync_options
      @rsync_options ||= fetch(:rsync_options, "-al")
    end

    def self.rsync_rsh
      @rsync_rsh ||= fetch(:rsync_rsh, "/usr/bin/ssh")
    end

    def self.max_parallels(hosts)
      @max_parallels ||= fetch(:max_parallels, hosts.size).to_i
    end

    def self.keep_packages
      @keep_packages ||= fetch(:keep_packages, 5).to_i
    end
  end
end
