# Deprecated AS PER THE PR - https://github.com/test-kitchen/test-kitchen/pull/1730
require_relative "chef_infra"

module Kitchen
  module Provisioner
    # Chef Zero provisioner (deprecated, use ChefInfra instead).
    #
    # This provisioner is maintained for backward compatibility and delegates
    # to ChefInfra. It also supports enterprise gem delegation.
    #
    # @author Fletcher Nichol <fnichol@nichol.ca>
    class ChefZero < ChefInfra
      # Factory method that returns the appropriate provisioner implementation.
      # If an enterprise gem (kitchen-chef-enterprise or kitchen-cinc) is available,
      # delegate to its implementation. Otherwise, use the standard ChefInfra implementation.
      #
      # @param config [Hash] configuration hash
      # @return [ChefZero] provisioner instance
      def self.new(config = {})
        enterprise_gem = ChefBase.enterprise_gem_available?
        
        if enterprise_gem
          begin
            omnibus_chef_class = self
            require "#{enterprise_gem}/provisioner/chef_zero"
            enterprise_class = Kitchen::Provisioner.const_get(:ChefZero)
            
            if enterprise_class != omnibus_chef_class
              if config[:instance] && config[:instance].respond_to?(:logger)
                config[:instance].logger.info("Using #{enterprise_gem} implementation of ChefZero provisioner")
              end
              return enterprise_class.allocate.tap { |instance| instance.send(:initialize, config) }
            end
          rescue LoadError, NameError => e
            if config[:instance] && config[:instance].respond_to?(:logger)
              config[:instance].logger.debug("Could not load enterprise provisioner, using kitchen-omnibus-chef: #{e.message}")
            end
          end
        end
        
        # Fall back to ChefInfra implementation (ChefZero is just an alias)
        allocate.tap { |instance| instance.send(:initialize, config) }
      end
    end
  end
end
