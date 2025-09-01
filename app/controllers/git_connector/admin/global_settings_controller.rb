module GitConnector
  module Admin
    class GlobalSettingsController < ApplicationController
      before_action :require_admin
      before_action :set_provider, only: [:edit, :update, :destroy]
      layout "admin"

      def index
        @providers = GitConnector::GlobalSetting.all
      end

      def new
        @provider = GitConnector::GlobalSetting.new
      end

      def create
        @provider = GitConnector::GlobalSetting.new(provider_params)
        if @provider.save
          flash[:notice] = "Provider created successfully"
          redirect_to git_connector_admin_global_settings_path
        else
          render :new
        end
      end

      def edit
      end

      def update
        if @provider.update(provider_params)
          flash[:notice] = "Provider updated successfully"
          redirect_to git_connector_admin_global_settings_path
        else
          render :edit
        end
      end

      def destroy
        @provider.destroy
        flash[:notice] = "Provider deleted successfully"
        redirect_to git_connector_admin_global_settings_path
      end

      private

      def set_provider
        @provider = GitConnector::GlobalSetting.find(params[:id])
      end

      def provider_params
        params.require(:git_connector_global_setting).permit(:provider, :client_id, :client_secret, :base_url)
      end
    end
  end
end
