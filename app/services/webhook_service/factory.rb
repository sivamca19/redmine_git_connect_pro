module WebhookService
  class Factory
    def self.build(provider, **args)
      case provider.to_sym
      when :github
        Github.new(**args)
      when :gitlab
        Gitlab.new(**args)
      when :bitbucket
        Bitbucket.new(**args)
      else
        raise "Unsupported provider: #{provider}"
      end
    end
  end
end
