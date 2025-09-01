module GitConnector
  module Admin
    class GlobalSettingsController < ApplicationController
      before_action :require_admin
      before_action :set_provider, only: %i[edit update destroy]

      layout "admin"

      def index
        @providers = GitConnector::GlobalSetting.all
      end

      def new
        @provider = GitConnector::GlobalSetting.new
      end

      def create
        @provider = GitConnector::GlobalSetting.new(provider_params)
        save_and_redirect(@provider, :new, "Provider created successfully")
      end

      def edit; end

      def update
        save_and_redirect(@provider, :edit, "Provider updated successfully")
      end

      def destroy
        if @provider.destroy
          flash[:notice] = "Provider deleted successfully"
        else
          flash[:error] = "Failed to delete provider"
        end
        redirect_to git_connector_admin_global_settings_path
      end

      private

      def set_provider
        @provider = GitConnector::GlobalSetting.find(params[:id])
      end

      def provider_params
        params.require(:git_connector_global_setting)
              .permit(:provider, :client_id, :client_secret, :base_url)
      end

      def save_and_redirect(resource, render_action, success_message)
        if resource.save
          flash[:notice] = success_message
          redirect_to git_connector_admin_global_settings_path
        else
          render render_action
        end
      end
    end
  end
end