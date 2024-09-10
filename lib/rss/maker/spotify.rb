# frozen_string_literal: false

require_relative '../spotify'
require_relative '2.0'

module RSS
  module Maker
    module SpotifyBaseModel
      def def_class_accessor(klass, name, type, *args)
        name = name.gsub(/-/, "_").gsub(/^spotify_/, '')
        full_name = "#{RSS::SPOTIFY_PREFIX}_#{name}"
        case type
        when nil
          klass.def_other_element(full_name)
        when :csv
          def_csv_accessor(klass, full_name)
        when :element, :attribute
          recommended_attribute_name, = *args
          klass_name = "Spotify#{Utils.to_class_name(name)}"
          klass.def_classed_element(full_name, klass_name,
                                    recommended_attribute_name)
        when :elements
          plural_name, recommended_attribute_name = args
          plural_name ||= "#{name}s"
          full_plural_name = "#{RSS::SPOTIFY_PREFIX}_#{plural_name}"
          klass_name = "Spotify#{Utils.to_class_name(name)}"
          plural_klass_name = "Spotify#{Utils.to_class_name(plural_name)}"
          def_elements_class_accessor(klass, name, full_name, full_plural_name,
                                      klass_name, plural_klass_name,
                                      recommended_attribute_name)
        end
      end

      def def_yes_other_accessor(klass, full_name)
        klass.def_other_element(full_name)
        klass.module_eval(<<-EOC, __FILE__, __LINE__ + 1)
          def #{full_name}?
            Utils::YesOther.parse(@#{full_name})
          end
        EOC
      end

      def def_csv_accessor(klass, full_name)
        klass.def_csv_element(full_name)
      end

      def def_elements_class_accessor(klass, name, full_name, full_plural_name,
                                      klass_name, plural_klass_name,
                                      recommended_attribute_name=nil)
        if recommended_attribute_name
          klass.def_classed_elements(full_name, recommended_attribute_name,
                                     plural_klass_name, full_plural_name)
        else
          klass.def_classed_element(full_plural_name, plural_klass_name)
        end
        klass.module_eval(<<-EOC, __FILE__, __LINE__ + 1)
          def new_#{full_name}(text=nil)
            #{full_name} = @#{full_plural_name}.new_#{name}
            #{full_name}.text = text
            if block_given?
              yield #{full_name}
            else
              #{full_name}
            end
          end
        EOC
      end
    end

    module SpotifyChannelModel
      extend SpotifyBaseModel

      class << self
        def append_features(klass)
          super

          ::RSS::SpotifyChannelModel::ELEMENT_INFOS.each do |name, type, *args|
            def_class_accessor(klass, name, type, *args)
          end
        end
      end

      class SpotifyAccessBase < Base
        %w(spotify_partner_id spotify_sandbox_enabled).each do |name|
          add_need_initialize_variable(name)
          attr_accessor(name)
        end

        def to_feed(feed, current)
          if current.respond_to?(:spotify_access=)
            _not_set_required_variables = not_set_required_variables
            if (required_variable_names - _not_set_required_variables).empty?
              return
            end

            unless have_required_values?
              raise NotSetError.new("maker.channel.spotify_access",
                                    _not_set_required_variables)
            end
            current.spotify_access ||= current.class::SpotifyAccess.new
            current.spotify_access.partners << current.class::SpotifyAccess::Partner.new
            current.spotify_access.partner.id = @spotify_partner_id

            if @spotify_sandbox_enabled
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

          ::RSS::SpotifyItemModel::ELEMENT_INFOS.each do |name, type, *args|
            def_class_accessor(klass, name, type, *args)
          end
        end
      end

      class SpotifyAccessBase < Base
        %w(spotify_entitlement_name).each do |name|
          add_need_initialize_variable(name)
          attr_accessor(name)
        end

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
