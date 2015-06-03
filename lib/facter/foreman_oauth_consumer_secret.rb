Facter.add('foreman_oauth_consumer_secret') do
  setcode do
    if File.exist?('/etc/foreman/settings.yaml')
      secret = YAML.load_file('/etc/foreman/settings.yaml')[:oauth_consumer_secret]
      if secret.empty? or secret.nil?
        raise "No consumer secret in /etc/foreman/settings.yaml"
      else
        secret
      end
    else
      raise "No file at /etc/foreman/settings.yaml"
    end
  end
end
