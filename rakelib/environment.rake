# Lazy load the environment for this lib
#
# Include as a pre-requisite for other tasks
task :environment do
  require_relative "../lib/miq"
end
