require "rake/testtask"

#
# Reset repos back to clean state
#
namespace :reset do
  desc "Reset all repos to clean state"
  task :all => [:guides, :site]

  desc "Reset guides to clean state"
  task :guides => :environment do
    Miq::Guides.reset
  end

  desc "Reset site repo to clean state"
  task :site => :environment do
    Miq::Site.reset
  end

  desc "Delete reference docs tmp directory"
  task :reference => :environment do
    Miq::RefDocs.reset
  end

  task :ref => :reference
end

#
# Update repos
#
namespace :update do
  desc "Update guides and site from upstream; prime ref doc repo"
  task :all => [:guides, :site, :reference]

  desc "Reset and update guides repo"
  task :guides => :environment do
    puts "Updating guides"
    Miq::Guides.update
  end

  desc "Reset and update site repo"
  task :site => :environment do
    puts "Updating site"
    Miq::Site.update
  end

  desc "Prime the reference docs staging directory"
  task :reference => :environment do
    say "Updating reference docs", :green
    RefDocs.update
  end

  task :ref => :reference
end

#
# Build aspects of the site
#
namespace :build do
  desc "Buildes guides, Jekyll site, and reference docs"
  task :all => [:say_all, :guides, :site, :reference]

  task :say_all do
    puts "Building all"
  end

  desc "Build guides"
  task :guides => :environment do
    puts "Processing guides"
    Miq::Guides.build
  end

  desc "Build Jekyll site"
  task :site => :environment do
    puts "Building Jekyll site"
    Miq::Site.build
  end

  desc "Build Reference Docs"
  task :reference => :environment do
    puts "Building reference docs"
    Miq::RefDocs.build
  end

  task :ref => :reference

  desc "Regenerate menu yaml files"
  task :menus => :environment do
    require 'io/console'

    puts "Rebuilding menu yaml files"
    puts "This will clobber existing files in tmp."
    print "Are you sure? Y/n"
    answer = STDIN.noecho(&:getch).tap { puts }

    if answer == "Y"
      Miq::RefMenu.build
      Miq::GuidesMenu.build
    else
      puts "Cancelled"
    end
  end
end

namespace :generate do
  desc <<~LONGDESC
    Generate a LWIMIQ blog post

    Generates a new Last Week in ManageIQ blog post skeleton. Includes all the
    links for PRs merged in the last week in the various ManageIQ repositories.

    With when option :current is set, generate:lwimiq generates links based on
    the current week instead of the last.
  LONGDESC
  task :lwimiq, [:current] => :environment do |t, options|
    options.with_defaults :current => false

    puts "Generating LWIMIQ post", :green
    Miq::Lwimiq.generate(options)
  end
end

desc "Does Jekyll serve with appropriate args"
task :serve => :environment do
  Miq::Site.serve
end

Rake::TestTask.new do |t|
  t.libs.push 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = false
  t.verbose = false
end

task :default => :test
