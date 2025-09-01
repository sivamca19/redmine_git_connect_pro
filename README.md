# Redmine Git Connect Pro

Redmine Git Connect Pro is a Redmine plugin that enables seamless integration with Git repositories.  
It allows users to configure multiple Git providers, manage repositories, and link them with Redmine projects for enhanced collaboration and version control.

---

## ✨ Features

- Connect Redmine with popular Git providers (GitHub, GitLab, Bitbucket, etc.).
- Manage multiple Git providers from a central configuration.
- Link repositories with Redmine projects.
- Browse repositories within Redmine.
- Supports custom repository settings per project.
- Provides a dedicated admin panel for global configurations.
- Breadcrumb navigation for better user experience.
- Error handling and validation messages for providers and repositories.

---

## 📦 Installation

1. Clone or download this plugin into your Redmine `plugins` directory:

```bash
cd /path/to/redmine/plugins
git clone https://github.com/sivamca19/redmine_git_connect_pro.git
```
2. Install required gems (if any):
```bash
bundle install
```

3. Run plugin migrations:
```bash
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

4. Restart your Redmine application (Passenger/Unicorn/Puma).

## 🔧 Configuration

- Go to Administration → Git Connector to configure global provider settings.
- Add provider credentials:
  - Provider: GitHub / GitLab / GitBucket
  - Client ID: Your OAuth client ID
  - Client Secret: Your OAuth client secret
- Navigate to a project and configure repositories under Project Settings → Repositories.

## Environment Variables

The plugin requires the following environment variable:
- APP_URL
The base URL of your Redmine application.
Example:

```bash
export APP_URL="https://redmine.example.com"
```

This is used when configuring OAuth callback URLs with Git providers.

## Example OAuth Callback URLs

When registering your Redmine instance with GitHub, GitLab, or GitBucket, set the OAuth redirect URI to:
```bash
https://your-redmine-domain.com/projects/oauth/callback
```

Replace https://your-redmine-domain.com with the value of ENV["APP_URL"].

## 🖥️ Usage

- Admins can manage global Git providers.
- Project managers can link repositories to their projects.
- Users can browse repositories from within Redmine.

## 📋 Requirements

- Redmine 6.1+ (tested)
- Ruby 3.0+
- Rails 6.1+

## 🧪 Development & Testing

1. Run migrations in development:
```bash
bundle exec rake redmine:plugins:migrate RAILS_ENV=development
```

2. Start the Redmine server:
```bash
rails s
```

3. Access the plugin under Administration → Git Connector.

## ❌ Uninstallation

To remove the plugin:
```bash
bundle exec rake redmine:plugins:migrate NAME=redmine_git_connect_pro VERSION=0 RAILS_ENV=production
```

Then delete the plugin folder from plugins/.

## 📜 License

This plugin is licensed under the MIT License.
See the LICENSE file for details.

## 👨‍💻 Author

Developed by Sivamanikandan
For support or customization, contact: Sedin Technologies