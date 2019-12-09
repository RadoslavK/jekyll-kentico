require 'kontent-delivery-sdk-ruby'

require 'jekyll-kentico/resolvers/content_link_resolver'
require 'jekyll-kentico/resolvers/inline_content_item_resolver'

require 'jekyll-kentico/constants/kentico_config_keys'

module Kentico
  module Kontent
    module Jekyll
      module SiteProcessing
        include Kentico::Kontent::Jekyll::Resolvers

        class KenticoKontentImporter
          def initialize(config)
            @config = config
            @items = []
            @taxonomy_groups = []
          end

          def items_by_type(language)
            retrieve_items(language)
              .group_by { |item| item.system.type }
          end

          def taxonomies
            @taxonomy_groups = retrieve_taxonomies
          end

          private

          def inline_content_item_resolver
            @inline_content_item_resolver ||= Resolvers::InlineContentItemResolver.for(@config)
          end

          def content_link_url_resolver
            @content_link_url_resolver ||= Resolvers::ContentLinkResolver.for(@config)
          end

          def delivery_client
            project_id = value_for(@config, KenticoConfigKeys::PROJECT_ID)
            secure_key = value_for(@config, KenticoConfigKeys::SECURE_KEY)

            ::Kentico::Kontent::Delivery::DeliveryClient.new(
              project_id: project_id,
              secure_key: secure_key,
              content_link_url_resolver: content_link_url_resolver,
              inline_content_item_resolver: inline_content_item_resolver
            )
          end

          def retrieve_taxonomies
            delivery_client
              .taxonomies
              .request_latest_content
              .execute { |response| return response.taxonomies }
          end

          def retrieve_items(language)
            client = delivery_client.items
            client = client.language(language) if language
            client.request_latest_content
              .depth(@config.max_linked_items_depth || 1)
              .execute { |response| return response.items }
          end

          def value_for(config, key)
            potential_value = config[key]
            return ENV[potential_value.gsub('ENV_', '')] if !potential_value.nil? && potential_value.start_with?('ENV_')
            potential_value
          end
        end
      end
    end
  end
end
