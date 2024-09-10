# frozen_string_literal: false

require_relative '../spotify'
require_relative '2.0'

module RSS
  module Maker
    module SpotifyBaseModel
      def def_class_accessor(klass, name)
        name = name.gsub(/-/, "_").gsub(/^spotify_/, '')

        klass_name = "Spotify#{Utils.to_class_name(name)}"
        klass.def_classed_element("#{RSS::SPOTIFY_PREFIX}_#{name}", klass_name)
      end
    end

    module SpotifyChannelModel
      extend SpotifyBaseModel

      class << self
        def append_features(klass)
          super

          ::RSS::SpotifyChannelModel::ELEMENT_INFOS.each { |name| def_class_accessor(klass, name) }
        end
      end

      class SpotifyAccessBase < Base
        %w(spotify_partner_id spotify_sandbox_enabled).each do |name|
          add_need_initialize_variable(name)
          attr_accessor(name)
        end

        def to_feed(_feed, current)
          if current.respond_to?(:spotify_access=) && (@spotify_partner_id || !@spotify_sandbox_enabled.nil?)
            unless have_required_values?
              raise NotSetError.new("maker.channel.spotify_access", not_set_required_variables)
            end

            current.spotify_access ||= current.class::SpotifyAccess.new
            current.spotify_access.partners << current.class::SpotifyAccess::Partner.new
            current.spotify_access.partner.id = @spotify_partner_id

            unless @spotify_sandbox_enabled.nil?
              current.spotify_access.sandboxs << current.class::SpotifyAccess::Sandbox.new
              current.spotify_access.sandbox.enabled = @spotify_sandbox_enabled
            end
          end
        end

        private

        def required_variable_names
          %w(spotify_partner_id)
        end
      end
    end

    module SpotifyItemModel
      extend SpotifyBaseModel

      class << self
        def append_features(klass)
          super

          ::RSS::SpotifyItemModel::ELEMENT_INFOS.each { |name| def_class_accessor(klass, name) }
        end
      end

      class SpotifyAccessBase < Base
        add_need_initialize_variable('spotify_entitlement_name')
        attr_accessor('spotify_entitlement_name')

        def to_feed(_feed, current)
          if @spotify_entitlement_name && current.respond_to?(:spotify_access=)
            current.spotify_access ||= current.class::SpotifyAccess.new
            current.spotify_access.entitlements << current.class::SpotifyAccess::Entitlement.new
            current.spotify_access.entitlement.name = @spotify_entitlement_name
          end
        end
      end
    end

    class ChannelBase
      include Maker::SpotifyChannelModel

      class SpotifyAccess < SpotifyAccessBase; end
    end

    class ItemsBase
      class ItemBase
        include Maker::SpotifyItemModel

        class SpotifyAccess < SpotifyAccessBase; end
      end
    end
  end
end
