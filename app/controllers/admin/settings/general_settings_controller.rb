module Admin
  module Settings
    class GeneralSettingsController < Admin::Settings::BaseController
      after_action :bust_content_change_caches, only: %i[create]

      SPECIAL_PARAMS_TO_ADD = %w[
        credit_prices_in_cents
        meta_keywords
        logo
      ].freeze

      def create
        result = ::Settings::General::Upsert.call(settings_params)
        if result.success?
          Audit::Logger.log(:internal, current_user, params.dup)
          render json: { message: I18n.t("core.success_settings") }, status: :ok
        else
          render json: { error: result.errors.to_sentence }, status: :unprocessable_entity
        end
      end

      private

      # NOTE: we need to override this since the controller name doesn't reflect
      # the model name
      def authorization_resource
        ::Settings::General
      end

      def settings_params
        params.require(:settings_general)&.merge(parsed_countries)&.permit(
          settings_keys.map(&:to_sym),
          social_media_handles: ::Settings::General::SOCIAL_MEDIA_SERVICES,
          meta_keywords: ::Settings::General.meta_keywords.keys,
          credit_prices_in_cents: ::Settings::General.credit_prices_in_cents.keys,
          billboard_enabled_countries: ISO3166::Country.codes,
        )
      end

      def settings_keys
        ::Settings::General.keys + SPECIAL_PARAMS_TO_ADD
      end

      def parsed_countries
        countries = params[:settings_general][:billboard_enabled_countries]
        return {} unless countries

        { billboard_enabled_countries: JSON.parse(countries) }
      end
    end
  end
end
