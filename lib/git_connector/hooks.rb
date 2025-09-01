module GitConnector
  class Hooks < Redmine::Hook::ViewListener
    # Add CSS to all pages
    def view_layouts_base_html_head(context = {})
      stylesheet_link_tag('git_connector', plugin: 'redmine_git_connect_pro')
    end

    # # Example: inject dev panel in issue sidebar
    # def view_issues_sidebar_planning_bottom(context = {})
    #   context[:controller].render_to_string(partial: 'git_connector/issues/dev_panel', locals: { issue: context[:issue] })
    # end
  end
end