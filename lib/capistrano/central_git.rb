require "capistrano/central_git/version"

module Capistrano
  module CentralGit
  end
end

load File.expand_path("../tasks/central_git.rake", __FILE__)
