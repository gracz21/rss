# frozen_string_literal: false
require 'rss/2.0'

module RSS
  # The prefix for the Spotify XML namespace.
  SPOTIFY_PREFIX = 'spotify'
  # The URI of the Spotify Namespace specification.
  SPOTIFY_URI = 'http://www.spotify.com/ns/rss'

  # Spec: https://developer.spotify.com/documentation/open-access/tutorials/content

  Rss.install_ns(SPOTIFY_PREFIX, SPOTIFY_URI)

  module SpotifyModelUtils
    include Utils

    def def_class_accessor(klass, name)
      normalized_name = name.gsub(/-/, "_")
      full_name = "#{SPOTIFY_PREFIX}_#{normalized_name}"

      klass.install_have_child_element(name, SPOTIFY_PREFIX, "?", full_name)
    end
  end

  module SpotifyBaseModel
    extend SpotifyModelUtils

    ELEMENTS = []

    ELEMENT_INFOS = ["access"]
  end

  module SpotifyChannelModel
    extend BaseModel
    extend SpotifyModelUtils
    include SpotifyBaseModel

    ELEMENTS = []
    ELEMENT_INFOS = SpotifyBaseModel::ELEMENT_INFOS

    class << self
      def append_features(klass)
        super

        return if klass.instance_of?(Module)
        ELEMENT_INFOS.each { |name| def_class_accessor(klass, name) }
      end
    end

    class SpotifyAccess < Element
      include RSS09

      @tag_name = "access"

      class << self
        def required_prefix
          SPOTIFY_PREFIX
        end

        def required_uri
          SPOTIFY_URI
        end
      end

      install_have_children_element('partner', '', nil)
      install_have_children_element('sandbox', '', '?')

      def full_name
        tag_name_with_prefix(SPOTIFY_PREFIX)
      end

      class Partner < Element
        include RSS09

        @tag_name = "partner"

        install_get_attribute('id', '')

        def initialize(*args)
          if Utils.element_initialize_arguments?(args)
            super
          else
            super()
            self.id = args[0]
          end
        end
      end

      class Sandbox < Element
        include RSS09

        @tag_name = "sandbox"

        install_get_attribute('enabled', '', '?', :boolean)

        def initialize(*args)
          if Utils.element_initialize_arguments?(args)
            super
          else
            super()
            self.enabled = args[0]
          end
        end
      end

      private

      def maker_target(target)
        target.spotify_access
      end

      def setup_maker_element(spotify_access)
        super(spotify_access)
        spotify_access.spotify_partner_id = partner.id
        spotify_access.spotify_sandbox_enabled = sandbox.enabled
      end
    end
  end

  module SpotifyItemModel
    extend BaseModel
    extend SpotifyModelUtils
    include SpotifyBaseModel

    ELEMENT_INFOS = SpotifyBaseModel::ELEMENT_INFOS

    class << self
      def append_features(klass)
        super

        return if klass.instance_of?(Module)
        ELEMENT_INFOS.each { |name| def_class_accessor(klass, name) }
      end
    end

    class SpotifyAccess < Element
      include RSS09

      @tag_name = "access"

      class << self
        def required_prefix
          SPOTIFY_PREFIX
        end

        def required_uri
          SPOTIFY_URI
        end
      end

      install_have_children_element('entitlement', '', nil)

      def full_name
        tag_name_with_prefix(SPOTIFY_PREFIX)
      end

      class Entitlement < Element
        include RSS09

        @tag_name = "entitlement"

        install_get_attribute('name', '')

        def initialize(*args)
          if Utils.element_initialize_arguments?(args)
            super
          else
            super()
            self.name = args[0]
          end
        end
      end
    end
  end

  class Rss
    class Channel
      include SpotifyChannelModel
      class Item; include SpotifyItemModel; end
    end
  end

  element_infos = SpotifyChannelModel::ELEMENT_INFOS + SpotifyItemModel::ELEMENT_INFOS
  element_infos.each do |name|
    class_name = Utils.to_class_name(name)
    BaseListener.install_class_name(SPOTIFY_URI, name, "Spotify#{class_name}")
  end
end
