Puppet::Type.type(:foreman_hostgroup).provide(:rest_v2) do

  confine :feature => :apipie_bindings

  def raise_error(e)
    body = JSON.parse(e.response)["error"]["full_messages"].join(" ") rescue 'N/A'
    fail "Proxy #{resource[:name]} cannot be registered (#{e.message}): #{body}"
  end

  # when both rest and rest_v2 providers are installed, use this one
  def self.specificity
    super + 1
  end

  def api
    @api ||= ApipieBindings::API.new({
      :uri => resource[:base_url],
      :api_version => 2,
      :oauth => {
        :consumer_key    => resource[:consumer_key],
        :consumer_secret => resource[:consumer_secret]
      },
      :timeout => resource[:timeout],
      :headers => {
        :foreman_user => resource[:effective_user],
      },
      :apidoc_cache_base_dir => File.join(Puppet[:vardir], 'apipie_bindings')
    })
  end

  # hostgroup hash or nil
  def hostgroup
    if @hostgroup
      @hostgroup
    else
      @hostgroup = api.resource(:hostgroups).call(:index, :search => "name=#{resource[:name]}")['results'][0]
    end
  rescue Exception => e
    raise_error e
  end

  def id
    hostgroup ? hostgroup['id'] : nil
  end

  def exists?
    ! id.nil?
  end

  def create
    api.resource(:hostgroups).call(:create, {
      :hostgroup => {
        :name => resource[:name]
      }
    })
  rescue Exception => e
    raise_error e
  end

  def destroy
    api.resource(:hostgroups).call(:destroy, :id => id)
    @hostgroup = nil
  rescue Exception => e
    raise_error e
  end

  def environment_id
    hostgroup ? hostgroup['environment_id'] : nil
  end

  def environment_name
    hostgroup ? hostgroup['environment_name'] : nil
  end

  def environment=(value)
    set_environment = api.resource(:environments).call(:index, :search => "name=#{value}")['results'][0]

    api.resource(:hostgroups).call(:update, { :id => id, :hostgroup => { :environment_id => set_environment[:id]})
  rescue Exception => e
    raise_error e
  end

  def refresh_features!
    api.resource(:hostgroups).call(:refresh, :id => id)
  rescue Exception => e
    raise_error e
  end

end
