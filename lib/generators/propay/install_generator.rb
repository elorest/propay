module Propay
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)
      desc "Creates initializer for tools."

      def copy_initializer
        template "propay_initializer.rb", "config/initializers/propay.rb"

        puts "Install complete!"
      end
    end
  end
end
