Puppet::Type.newtype(:foreman_hostgroup) do
  desc 'foreman_hostgroup registers a hostgroup in foreman.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the hostgroup.'
    isrequired
  end

  newparam(:base_url) do
    desc 'Foreman\'s base url.'
    defaultto "https://localhost"
  end

  newparam(:effective_user) do
    desc 'Foreman\'s effective user for the registration (usually admin).'
    defaultto "admin"
  end

  newparam(:consumer_key) do
    desc 'Foreman oauth consumer_key'
  end

  newparam(:consumer_secret) do
    desc 'Foreman oauth consumer_secret'
  end

  #newproperty(:puppetclasses) do
  #  desc 'The url of the hostgroup'
  #  isrequired
  #  newvalues(URI.regexp)
  #end

  def refresh
    provider.refresh_features! if provider.respond_to?(:refresh_features!)
  end

end
