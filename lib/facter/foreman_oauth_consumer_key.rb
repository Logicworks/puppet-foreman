Facter.add('foreman_oauth_consumer_key') do
  setcode do
    if File.exist?('/etc/foreman/settings.yaml')
      key = YAML.load_file('/etc/foreman/settings.yaml')[:oauth_consumer_key]
      if key.empty? or key.nil?
        raise "No consumer key in /etc/foreman/settings.yaml"
      else
        key
      end
    else
      raise "No file at /etc/foreman/settings.yaml"
    end
  end
end
